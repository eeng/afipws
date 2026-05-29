module Afipws
  class WSFEX
    include TypeConversions

    attr_reader :wsaa, :cuit

    WSDL = {
      development: 'https://wswhomo.afip.gov.ar/wsfexv1/service.asmx?WSDL',
      production: 'https://servicios1.afip.gov.ar/wsfexv1/service.asmx?WSDL',
      test: Root + '/spec/fixtures/wsfex/wsfex.wsdl'
    }.freeze

    REQUIRED_COMPROBANTE_FIELDS = %i[
      id cbte_tipo punto_vta cbte_nro tipo_expo dst_cmp cliente
      domicilio_cliente moneda_id imp_total idioma_cbte items
    ].freeze
    REQUIRED_ITEM_FIELDS = %i[pro_ds pro_umed pro_total_item].freeze

    # Tipos de comprobante (manual WSFEX v3.1.1, pág. 19)
    FACTURA_E = 19
    NOTA_DEBITO_E = 20
    NOTA_CREDITO_E = 21
    NOTAS_DE_AJUSTE_E = [NOTA_DEBITO_E, NOTA_CREDITO_E].freeze

    # Tipos de exportación (pág. 13): 1=Bienes, 2=Servicios, 4=Otros
    TIPOS_EXPO_NO_BIENES = [2, 4].freeze

    # Remitos sin tope de cantidad como cmps_asoc (pág. 19)
    REMITOS_SIN_TOPE = [88, 89, 91, 993, 994].freeze

    # Unidades de medida que indican intangibles/servicios sin pro_qty (pág. 21)
    UMEDS_SIN_CANTIDAD = [0, 97, 99].freeze

    # Tope máximo de ítems por comprobante (pág. 21, código 1781)
    MAX_ITEMS_POR_COMPROBANTE = 9999

    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = WSAA.new options.merge(service: 'wsfex')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@wsaa.env])
    end

    def ultimo_comprobante_autorizado opciones
      auth_block = auth.merge('Pto_venta' => opciones[:pto_vta], 'Cbte_Tipo' => opciones[:cbte_tipo])
      response = request(:fex_get_last_cmp, { 'Auth' => auth_block })
      x2r(response[:fex_result_last_cmp] || {}, cbte_nro: :integer, cbte_fecha: :date)
    end

    def autorizar_comprobantes opciones
      Array.wrap(opciones[:comprobantes]).map do |comprobante|
        response = request(:fex_authorize, { 'Auth' => auth, 'Cmp' => comprobante_to_request(comprobante, opciones) }, raise_on_errors: false)
        result = x2r(response[:fex_result_auth] || {}, id: :integer, cuit: :integer, cbte_tipo: :integer, punto_vta: :integer,
          cbte_nro: :integer, fch_venc_cae: :date, fch_cbte: :date)
        errores = normalize_messages(response[:fex_err], :err_code, :err_msg)
        eventos = normalize_messages(response[:fex_events], :event_code, :event_msg)

        {
          resultado: result[:resultado],
          cae: result[:cae],
          cae_fch_vto: result[:fch_venc_cae],
          cbte_nro: result[:cbte_nro],
          reproceso: result[:reproceso] == 'S',
          observaciones: result[:motivos_obs].presence,
          errores: errores,
          eventos: eventos
        }
      end
    end

    private

    def auth
      wsaa.auth.merge(cuit: cuit).transform_keys { |key| soap_key(key) }
    end

    def comprobante_to_request comprobante, opciones
      comprobante = normalize_comprobante(comprobante, opciones)
      validate_comprobante!(comprobante)

      request_payload(
        r2x(comprobante.compact, fecha_cbte: :date, fecha_pago: :date, fecha_permiso_existente: :date)
      )
    end

    def normalize_comprobante comprobante, opciones
      comprobante.deep_dup.tap do |payload|
        payload[:cbte_tipo] ||= opciones[:cbte_tipo]
        payload[:punto_vta] ||= opciones[:pto_vta]
        payload[:id] ||= payload[:cbte_nro]
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
      payload = {}
      payload['Id'] = comprobante[:id]
      payload['Fecha_cbte'] = comprobante[:fecha_cbte]
      payload['Cbte_Tipo'] = comprobante[:cbte_tipo]
      payload['Punto_vta'] = comprobante[:punto_vta]
      payload['Cbte_nro'] = comprobante[:cbte_nro]
      payload['Tipo_expo'] = comprobante[:tipo_expo]
      payload['Permiso_existente'] = comprobante[:permiso_existente] || ''
      payload['Permisos'] = request_collection(comprobante[:permisos], 'Permiso') if comprobante[:permisos].present?
      payload['Dst_cmp'] = comprobante[:dst_cmp]
      payload['Cliente'] = comprobante[:cliente]
      payload['Cuit_pais_cliente'] = comprobante[:cuit_pais_cliente]
      payload['Domicilio_cliente'] = comprobante[:domicilio_cliente]
      payload['Id_impositivo'] = comprobante[:id_impositivo]
      payload['Moneda_Id'] = comprobante[:moneda_id]
      payload['Moneda_ctz'] = comprobante[:moneda_ctz]
      payload['CanMisMonExt'] = comprobante[:can_mis_mon_ext]
      payload['Obs_comerciales'] = comprobante[:obs_comerciales]
      payload['Imp_total'] = comprobante[:imp_total]
      payload['Obs'] = comprobante[:obs]
      payload['Cmps_asoc'] = request_collection(comprobante[:cmps_asoc], 'Cmp_asoc') if comprobante[:cmps_asoc].present?
      payload['Forma_pago'] = comprobante[:forma_pago]
      payload['Incoterms'] = comprobante[:incoterms]
      payload['Incoterms_Ds'] = comprobante[:incoterms_ds]
      payload['Idioma_cbte'] = comprobante[:idioma_cbte]
      payload['Items'] = request_collection(comprobante[:items], 'Item') if comprobante[:items].present?
      payload['Opcionales'] = request_collection(comprobante[:opcionales], 'Opcional') if comprobante[:opcionales].present?
      payload['Fecha_pago'] = comprobante[:fecha_pago]
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

      validate_permiso_rules!(comprobante)
      validate_currency_rules!(comprobante)
      validate_payment_rules!(comprobante)
      validate_associated_vouchers!(comprobante)
      validate_items!(Array.wrap(comprobante.dig(:items, :item)))
    end

    def validate_permiso_rules!(comprobante)
      cbte_tipo = comprobante[:cbte_tipo].to_i
      tipo_expo = comprobante[:tipo_expo].to_i
      permiso_existente = comprobante[:permiso_existente]
      permisos = Array.wrap(comprobante.dig(:permisos, :permiso))

      if permiso_existente.present? && !%w[S N].include?(permiso_existente)
        raise ArgumentError, 'WSFEX requiere que permiso_existente sea S, N o vacío'
      end

      if TIPOS_EXPO_NO_BIENES.include?(tipo_expo)
        raise ArgumentError, 'WSFEX requiere permiso_existente vacío para tipo_expo 2 o 4' if permiso_existente.present?
        raise ArgumentError, 'WSFEX no permite permisos para tipo_expo 2 o 4' if permisos.present?
        return
      end

      if cbte_tipo == FACTURA_E
        raise ArgumentError, 'WSFEX requiere permiso_existente para cbte_tipo 19 y tipo_expo 1' if permiso_existente.blank?
        raise ArgumentError, 'WSFEX requiere permisos cuando permiso_existente es S' if permiso_existente == 'S' && permisos.blank?
        raise ArgumentError, 'WSFEX no permite permisos cuando permiso_existente es N' if permiso_existente == 'N' && permisos.present?
      else
        raise ArgumentError, 'WSFEX requiere permiso_existente vacío para cbte_tipo 20 o 21' if permiso_existente.present?
      end

      permisos.each_with_index do |permiso, index|
        if permiso[:id_permiso].blank? || permiso[:dst_merc].blank?
          raise ArgumentError, "WSFEX requiere id_permiso y dst_merc en permiso #{index + 1}"
        end
      end
    end

    def validate_currency_rules! comprobante
      cbte_tipo = comprobante[:cbte_tipo].to_i
      moneda_id = comprobante[:moneda_id].to_s
      moneda_ctz = comprobante[:moneda_ctz]
      can_mis_mon_ext = comprobante[:can_mis_mon_ext]

      if can_mis_mon_ext.present? && !%w[S N].include?(can_mis_mon_ext)
        raise ArgumentError, 'WSFEX requiere que can_mis_mon_ext sea S o N'
      end

      if can_mis_mon_ext.present? && (moneda_id == 'PES' || NOTAS_DE_AJUSTE_E.include?(cbte_tipo))
        raise ArgumentError, 'WSFEX no permite can_mis_mon_ext para moneda PES o cbte_tipo 20/21'
      end

      numeric_moneda_ctz = numeric_value(moneda_ctz)
      if can_mis_mon_ext != 'S'
        raise ArgumentError, 'WSFEX requiere moneda_ctz si can_mis_mon_ext no es S' if moneda_ctz.blank?
      end

      if moneda_ctz.present? && (numeric_moneda_ctz.nil? || numeric_moneda_ctz <= 0)
        raise ArgumentError, 'WSFEX requiere que moneda_ctz sea mayor a 0'
      end

      if moneda_id == 'PES' && moneda_ctz.present? && numeric_moneda_ctz != 1.0
        raise ArgumentError, 'WSFEX requiere moneda_ctz igual a 1 cuando moneda_id es PES'
      end
    end

    def validate_payment_rules! comprobante
      cbte_tipo = comprobante[:cbte_tipo].to_i
      tipo_expo = comprobante[:tipo_expo].to_i
      fecha_pago = comprobante[:fecha_pago]

      raise ArgumentError, 'WSFEX requiere forma_pago para cbte_tipo 19' if cbte_tipo == FACTURA_E && comprobante[:forma_pago].blank?
      if cbte_tipo == FACTURA_E && tipo_expo == 1 && comprobante[:incoterms].blank?
        raise ArgumentError, 'WSFEX requiere incoterms para cbte_tipo 19 y tipo_expo 1'
      end
      if comprobante[:incoterms_ds].present? && comprobante[:incoterms].blank?
        raise ArgumentError, 'WSFEX requiere incoterms cuando se informa incoterms_ds'
      end

      if fecha_pago.present? && parse_ws_date(fecha_pago).nil?
        raise ArgumentError, 'WSFEX requiere que fecha_pago tenga formato YYYYMMDD o sea Date'
      end

      if cbte_tipo == FACTURA_E && TIPOS_EXPO_NO_BIENES.include?(tipo_expo)
        raise ArgumentError, 'WSFEX requiere fecha_pago para cbte_tipo 19 y tipo_expo 2 o 4' if fecha_pago.blank?

        fecha_cbte = parse_ws_date(comprobante[:fecha_cbte])
        fecha_pago_value = parse_ws_date(fecha_pago)
        if fecha_cbte.present? && fecha_pago_value.present? && fecha_pago_value < fecha_cbte
          raise ArgumentError, 'WSFEX requiere que fecha_pago sea igual o posterior a fecha_cbte'
        end
      elsif cbte_tipo != FACTURA_E && fecha_pago.present?
        raise ArgumentError, 'WSFEX no permite fecha_pago cuando cbte_tipo no es 19'
      end
    end

    def validate_associated_vouchers! comprobante
      cbte_tipo = comprobante[:cbte_tipo].to_i
      tipo_expo = comprobante[:tipo_expo].to_i
      cmps_asoc = Array.wrap(comprobante.dig(:cmps_asoc, :cmp_asoc))

      if NOTAS_DE_AJUSTE_E.include?(cbte_tipo) && tipo_expo == 2 && cmps_asoc.blank?
        raise ArgumentError, 'WSFEX requiere cmps_asoc para notas de servicio'
      end

      return if cmps_asoc.blank?

      if cbte_tipo == FACTURA_E
        if cmps_asoc.any? { |cmp_asoc| !REMITOS_SIN_TOPE.include?(cmp_asoc[:cbte_tipo].to_i) }
          raise ArgumentError, 'WSFEX solo permite remitos de tabaco como cmps_asoc para cbte_tipo 19'
        end
      elsif !NOTAS_DE_AJUSTE_E.include?(cbte_tipo)
        raise ArgumentError, 'WSFEX solo permite cmps_asoc para cbte_tipo 19, 20 o 21'
      end

      if cmps_asoc.size > 1 && cmps_asoc.any? { |cmp_asoc| !REMITOS_SIN_TOPE.include?(cmp_asoc[:cbte_tipo].to_i) }
        raise ArgumentError, 'WSFEX solo permite más de un cmps_asoc cuando todos son remitos tipo 88, 89, 91, 993 o 994'
      end
    end

    def validate_items! items
      raise ArgumentError, 'WSFEX requiere al menos un item' if items.blank?
      raise ArgumentError, "WSFEX permite hasta #{MAX_ITEMS_POR_COMPROBANTE} items" if items.size > MAX_ITEMS_POR_COMPROBANTE

      items.each_with_index do |item, index|
        missing_item_fields = REQUIRED_ITEM_FIELDS.select { |field| item[field].blank? }
        if missing_item_fields.present?
          raise ArgumentError, "faltan campos obligatorios para WSFEX en item #{index + 1}: #{missing_item_fields.join(', ')}"
        end

        pro_umed = item[:pro_umed].to_i
        if !UMEDS_SIN_CANTIDAD.include?(pro_umed)
          raise ArgumentError, "WSFEX requiere pro_qty en item #{index + 1}" if item[:pro_qty].blank?
          raise ArgumentError, "WSFEX requiere pro_precio_uni en item #{index + 1}" if item[:pro_precio_uni].blank?
        else
          %i[pro_qty pro_precio_uni pro_bonificacion].each do |field|
            next if item[field].blank?

            value = numeric_value(item[field])
            if value.nil? || value != 0
              raise ArgumentError, "WSFEX requiere #{field} igual a 0 o no informado cuando pro_umed es 0, 97 o 99 en item #{index + 1}"
            end
          end
        end
      end
    end

    def parse_ws_date value
      return value if value.is_a?(Date)
      return nil if value.blank?

      Date.strptime(value.to_s, '%Y%m%d')
    rescue ArgumentError
      nil
    end

    def numeric_value value
      Float(value)
    rescue ArgumentError, TypeError
      nil
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
