module Afipws
  class WSFEX
    WSDL = {
      development: 'https://webserviceshomoext.afip.gob.ar/Fiscalizacion/wsfex/Service.asmx?WSDL',
      production: 'https://servicios1.afip.gob.ar/wsfexv1/service.asmx?WSDL',
      test: Root + '/spec/fixtures/wsfex/wsfex.wsdl'
    }.freeze

    REQUIRED_COMPROBANTE_FIELDS = %i[
      id cbte_tipo punto_vta cbte_nro tipo_expo permiso_existente dst_cmp cliente
      domicilio_cliente moneda_id moneda_ctz imp_total idioma_cbte items
    ].freeze
    REQUIRED_ITEM_FIELDS = %i[pro_ds pro_umed pro_total_item].freeze

    include TypeConversions

    attr_reader :wsaa, :cuit

    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = WSAA.new options.merge(service: 'wsfex')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@wsaa.env])
    end

    def ultimo_comprobante_autorizado opciones
      request(:fex_get_last_cmp, 'Auth' => auth, 'PtoVta' => opciones[:pto_vta], 'CbteTipo' => opciones[:cbte_tipo])[:fex_result_last_cmp][:cbte_nro].to_i
    end

    def autorizar_comprobantes opciones
      Array.wrap(opciones[:comprobantes]).map do |comprobante|
        response = request(:fex_authorize, 'Auth' => auth, 'Cmp' => comprobante_to_request(comprobante, opciones), raise_on_errors: false)
        result = x2r(response[:fex_result_auth] || {}, id: :integer, cuit: :integer, cbte_tipo: :integer, punto_vta: :integer,
          cbte_nro: :integer, fch_venc_cae: :date, fecha_vencimiento_cae: :date, fch_cbte: :date)
        errores = normalize_messages(response[:fex_err], :err_code, :err_msg)
        eventos = normalize_messages(response[:fex_events], :event_code, :event_msg)

        {
          resultado: result[:resultado],
          cae: result[:cae],
          cae_fch_vto: result[:fch_venc_cae] || result[:fecha_vencimiento_cae],
          cbte_nro: result[:cbte_nro],
          observaciones: observaciones(result, errores),
          errores: errores,
          eventos: eventos
        }
      end
    end

    def auth
      wsaa.auth.merge(cuit: cuit).transform_keys { |key| soap_key(key) }
    end

    private

    def comprobante_to_request comprobante, opciones
      comprobante = normalize_comprobante(comprobante, opciones)
      validate_comprobante!(comprobante)

      request_payload(
        r2x(comprobante, fecha_cbte: :date, fecha_pago: :date, fecha_permiso_existente: :date)
      )
    end

    def normalize_comprobante comprobante, opciones
      comprobante.deep_dup.tap do |payload|
        payload[:id] ||= payload[:cbte_nro]
        payload[:cbte_tipo] ||= opciones[:cbte_tipo]
        payload[:punto_vta] ||= opciones[:pto_vta]
        payload[:fecha_cbte] ||= payload.delete(:cbte_fch)
        payload[:fecha_pago] ||= payload.delete(:fch_vto_pago)
        payload[:items] = normalize_collection(payload[:items], :item)
        payload[:permisos] = normalize_collection(payload[:permisos], :permiso)
        payload[:cmps_asoc] = normalize_collection(payload[:cmps_asoc], :cmp_asoc)
        payload[:opcionales] = normalize_collection(payload[:opcionales], :opcional)
        payload[:actividades] = normalize_collection(payload[:actividades], :actividad)
      end
    end

    def request_payload comprobante
      payload = {
        'Id' => comprobante[:id],
        'Fecha_cbte' => comprobante[:fecha_cbte],
        'Cbte_Tipo' => comprobante[:cbte_tipo],
        'Punto_vta' => comprobante[:punto_vta],
        'Cbte_nro' => comprobante[:cbte_nro],
        'Tipo_expo' => comprobante[:tipo_expo],
        'Permiso_existente' => comprobante[:permiso_existente],
        'Dst_cmp' => comprobante[:dst_cmp],
        'Cliente' => comprobante[:cliente],
        'Cuit_pais_cliente' => comprobante[:cuit_pais_cliente],
        'Domicilio_cliente' => comprobante[:domicilio_cliente],
        'Id_impositivo' => comprobante[:id_impositivo],
        'Moneda_Id' => comprobante[:moneda_id],
        'Moneda_ctz' => comprobante[:moneda_ctz],
        'Obs_comerciales' => comprobante[:obs_comerciales],
        'Imp_total' => comprobante[:imp_total],
        'Obs' => comprobante[:obs],
        'Forma_pago' => comprobante[:forma_pago],
        'Incoterms' => comprobante[:incoterms],
        'Incoterms_Ds' => comprobante[:incoterms_ds],
        'Idioma_cbte' => comprobante[:idioma_cbte],
        'Fecha_pago' => comprobante[:fecha_pago]
      }

      payload['Permisos'] = request_collection(comprobante[:permisos], 'Permiso') if comprobante[:permisos].present?
      payload['Cmps_asoc'] = request_collection(comprobante[:cmps_asoc], 'Cmp_asoc') if comprobante[:cmps_asoc].present?
      payload['Items'] = request_collection(comprobante[:items], 'Item') if comprobante[:items].present?
      payload['Opcionales'] = request_collection(comprobante[:opcionales], 'Opcional') if comprobante[:opcionales].present?
      payload['Actividades'] = request_collection(comprobante[:actividades], 'Actividad') if comprobante[:actividades].present?
      payload.compact
    end

    def request_collection collection, item_name
      item = Array.wrap(collection.values.first).map { |entry| request_hash(entry) }
      { item_name => item }
    end

    def request_hash hash
      Hash[hash.map { |key, value| [soap_key(key), value] }]
    end

    def soap_key key
      key.to_s.sub(/\A./, &:upcase)
    end

    def normalize_collection collection, item_key
      case collection
      when Array then { item_key => collection }
      when Hash then collection
      else collection
      end
    end

    def validate_comprobante! comprobante
      missing_fields = REQUIRED_COMPROBANTE_FIELDS.select { |field| comprobante[field].blank? }
      raise ArgumentError, "faltan campos obligatorios para WSFEX: #{missing_fields.join(', ')}" if missing_fields.present?
      raise ArgumentError, 'WSFEX requiere cuit_pais_cliente o id_impositivo' if comprobante[:cuit_pais_cliente].blank? && comprobante[:id_impositivo].blank?

      items = Array.wrap(comprobante.dig(:items, :item))
      raise ArgumentError, 'WSFEX requiere al menos un item' if items.blank?

      items.each_with_index do |item, index|
        missing_item_fields = REQUIRED_ITEM_FIELDS.select { |field| item[field].blank? }
        next if missing_item_fields.blank?

        raise ArgumentError, "faltan campos obligatorios para WSFEX en item #{index + 1}: #{missing_item_fields.join(', ')}"
      end
    end

    def observaciones result, errores
      return errores if errores.present?
      motivos = result[:motivos_obs]
      return [] if motivos.blank?

      [{ code: nil, msg: motivos }]
    end

    def normalize_messages raw_messages, code_key, msg_key
      messages = if raw_messages.is_a?(Hash)
        raw_messages.values.find { |value| value.is_a?(Array) || value.is_a?(Hash) } || raw_messages
      else
        raw_messages
      end

      Array.wrap(messages).filter_map do |message|
        next unless message.is_a?(Hash)

        code = message[code_key] || message[:code]
        msg = message[msg_key] || message[:msg]
        next if code.to_i.zero? && msg.to_s.strip.empty?
        next if code.to_i.zero? && msg.to_s.strip.casecmp('ok').zero?

        x2r({ code: code, msg: msg }, code: :integer)
      end
    end

    def request action, body = nil, raise_on_errors: true
      response = @client.request(action, body).to_hash[:"#{action}_response"][:"#{action}_result"]
      errors = normalize_messages(response[:fex_err], :err_code, :err_msg)
      raise ResponseError, errors if raise_on_errors && errors.present?

      response
    end
  end
end
