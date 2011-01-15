module Afipws
  class WSFE
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client
    def_delegators :wsaa, :ta, :auth, :cuit

    WSDL = {
      :dev => "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL",
      :test => Root + '/spec/fixtures/wsfe.wsdl'
    }
    
    def initialize options = {}
      @wsaa = options[:wsaa] || WSAA.new(options.merge(:service => 'wsfe'))
      @client = Client.new WSDL[options[:env] || :test]
    end
    
    def dummy
      @client.fe_dummy
    end
    
    def tipos_comprobantes
      r = @client.fe_param_get_tipos_cbte auth
      x2r get_array(r, :cbte_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_documentos
      r = @client.fe_param_get_tipos_doc auth
      x2r get_array(r, :doc_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_monedas
      r = @client.fe_param_get_tipos_monedas auth
      x2r get_array(r, :moneda), :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_iva
      r = @client.fe_param_get_tipos_iva auth
      x2r get_array(r, :iva_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date
    end
    
    def tipos_tributos
      r = @client.fe_param_get_tipos_tributos auth
      x2r get_array(r, :tributo_tipo), :id => :integer, :fch_desde => :date, :fch_hasta => :date      
    end

    # TODO simplificar lo q devuelve
    def cotizacion moneda_id
      r = @client.fe_param_get_cotizacion auth.merge :mon_id => moneda_id
      x2r r[:result_get], :mon_cotiz => :float, :fch_cotiz => :date
    end
    
    def autorizar_comprobantes opciones
      comprobantes = opciones[:comprobantes]
      request = { 'FeCAEReq' => {
        'FeCabReq' => opciones.select_keys(:cbte_tipo, :pto_vta).merge(:cant_reg => comprobantes.size),
        'FeDetReq' => { 
          'FECAEDetRequest' => comprobantes.map do |comprobante|
            comprobante.merge(:cbte_desde => comprobante[:cbte_nro], :cbte_hasta => comprobante[:cbte_nro]).
              select_keys(:concepto, :doc_tipo, :doc_nro, :cbte_desde, 
              :cbte_hasta, :cbte_fch, :imp_total, :imp_tot_conc, :imp_neto, :imp_op_ex, :imp_trib, 
              :mon_id, :mon_cotiz, :iva).merge({ 'ImpIVA' => comprobante[:imp_iva] })
          end
      }}}
      r = @client.fecae_solicitar auth.merge r2x(request, :cbte_fch => :date)
      r = Array.wrap(r[:fe_det_resp][:fecae_det_response]).map do |h| 
        obs = h[:observaciones] ? h[:observaciones][:obs] : nil
        h.select_keys(:cae, :cae_fch_vto).merge(:cbte_nro => h[:cbte_desde]).tap { |h| h.merge!(:observaciones => obs) if obs }
      end
      x2r r, :cae_fch_vto => :date, :cbte_nro => :integer, :code => :integer
    end
    
    def ultimo_comprobante_autorizado opciones
      @client.fe_comp_ultimo_autorizado(auth.merge(opciones))[:cbte_nro].to_i
    end

    def consultar_comprobante opciones
      @client.fe_comp_consultar(auth.merge(opciones))[:result_get]
    end
    
    def cant_max_registros_x_request
      @client.fe_comp_tot_x_request[:reg_x_req].to_i
    end
    
    private
    def get_array response, array_element
      Array.wrap response[:result_get][array_element]
    end
  end
end