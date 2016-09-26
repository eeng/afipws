module Afipws
  class WSFE
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client, :env
    def_delegators :wsaa, :ta, :auth, :cuit

    WSDL = {
      development: "https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL",
      # production: "https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL",
      production: Root + "/lib/afipws/wsfev1.wsdl",
      test: Root + "/spec/fixtures/wsfe.wsdl"
    }
    
    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'wsfe'))
      ssl_version = env == :development || Date.today >= Date.new(2016,11,1) ? :SSLv3 : :TLSv1
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@env], ssl_version: ssl_version, convert_request_keys_to: :camelcase)
    end
    
    def dummy
      @client.fe_dummy
    end
    
    def tipos_comprobantes
      r = @client.fe_param_get_tipos_cbte auth
      x2r get_array(r, :cbte_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end
    
    def tipos_documentos
      r = @client.fe_param_get_tipos_doc auth
      x2r get_array(r, :doc_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end
    
    def tipos_monedas
      r = @client.fe_param_get_tipos_monedas auth
      x2r get_array(r, :moneda), fch_desde: :date, fch_hasta: :date
    end
    
    def tipos_iva
      r = @client.fe_param_get_tipos_iva auth
      x2r get_array(r, :iva_tipo), id: :integer, fch_desde: :date, fch_hasta: :date
    end
    
    def tipos_tributos
      r = @client.fe_param_get_tipos_tributos auth
      x2r get_array(r, :tributo_tipo), id: :integer, fch_desde: :date, fch_hasta: :date      
    end

    def puntos_venta
      r = @client.fe_param_get_ptos_venta auth
      x2r get_array(r, :pto_venta), nro: :integer, fch_baja: :date, bloqueado: :boolean
    end
    
    def cotizacion moneda_id
      @client.fe_param_get_cotizacion(auth.merge(mon_id: moneda_id))[:result_get][:mon_cotiz].to_f
    end
    
    def autorizar_comprobantes opciones
      comprobantes = opciones[:comprobantes]
      request = { 'FeCAEReq' => {
        'FeCabReq' => opciones.select_keys(:cbte_tipo, :pto_vta).merge(cant_reg: comprobantes.size),
        'FeDetReq' => { 'FECAEDetRequest' => comprobantes.map { |comprobante|  comprobante_to_request comprobante }
      }}}
      r = @client.fecae_solicitar auth.merge r2x(request, cbte_fch: :date)
      r = Array.wrap(r[:fe_det_resp][:fecae_det_response]).map do |h| 
        obs = Array.wrap(h[:observaciones] ? h[:observaciones][:obs] : nil)
        h.select_keys(:cae, :cae_fch_vto, :resultado).merge(cbte_nro: h[:cbte_desde], observaciones: obs)
      end
      x2r r, cae_fch_vto: :date, cbte_nro: :integer, code: :integer
    end
    
    def comprobante_to_request comprobante
      nro = comprobante.delete :cbte_nro
      iva = comprobante.delete :imp_iva
      comprobante.delete :tributos if comprobante[:imp_trib] == 0
      comprobante.merge cbte_desde: nro, cbte_hasta: nro, 'ImpIVA' => iva
    end
    
    def solicitar_caea
      convertir_rta_caea @client.fecaea_solicitar auth.merge(periodo_para_solicitud_caea)
    rescue Afipws::WSError => e
      if e.errors.any? { |e| e[:code] == '15008' }
        consultar_caea fecha_inicio_quincena_siguiente
      else
        raise
      end
    end
    
    def consultar_caea fecha
      convertir_rta_caea @client.fecaea_consultar auth.merge(periodo_para_consulta_caea(fecha))
    end
    
    def informar_comprobantes_caea opciones
      comprobantes = opciones[:comprobantes]
      request = { 'FeCAEARegInfReq' => {
        'FeCabReq' => opciones.select_keys(:cbte_tipo, :pto_vta).merge(cant_reg: comprobantes.size),
        'FeDetReq' => { 'FECAEADetRequest' => comprobantes.map do |comprobante|
            comprobante_to_request comprobante.merge('CAEA' => comprobante.delete(:caea))
          end
      }}}
      r = @client.fecaea_reg_informativo auth.merge r2x(request, cbte_fch: :date)
      r = Array.wrap(r[:fe_det_resp][:fecaea_det_response]).map do |h| 
        obs = Array.wrap(h[:observaciones] ? h[:observaciones][:obs] : nil)
        h.select_keys(:caea, :resultado).merge(cbte_nro: h[:cbte_desde], observaciones: obs)
      end
      x2r r, cbte_nro: :integer, code: :integer
    end
    
    def informar_caea_sin_movimientos caea, pto_vta
      @client.fecaea_sin_movimiento_informar(auth.merge('CAEA' => caea, 'PtoVta' => pto_vta))
    end
    
    def ultimo_comprobante_autorizado opciones
      @client.fe_comp_ultimo_autorizado(auth.merge(opciones))[:cbte_nro].to_i
    end

    def consultar_comprobante opciones
      @client.fe_comp_consultar(auth.merge(fe_comp_cons_req: opciones))[:result_get]
    end
    
    def cant_max_registros_x_lote
      @client.fe_comp_tot_x_request(auth)[:reg_x_req].to_i
    end
    
    def periodo_para_solicitud_caea
      periodo_para_consulta_caea fecha_inicio_quincena_siguiente
    end
    
    def periodo_para_consulta_caea fecha
      orden = fecha.day <= 15 ? 1 : 2
      { orden: orden, periodo: fecha.strftime('%Y%m') }
    end
    
    def fecha_inicio_quincena_siguiente
      hoy = Date.today
      hoy.day <= 15 ? hoy.change(day: 16) : hoy.next_month.change(day: 1)      
    end
    
    private
    def get_array response, array_element
      Array.wrap response[:result_get][array_element]
    end
    
    def convertir_rta_caea r
      x2r r[:result_get], fch_tope_inf: :date, fch_vig_desde: :date, fch_vig_hasta: :date
    end
  end
end