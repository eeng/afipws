module Afipws
  class WSFE
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa
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

    # TODO simplificar lo q devuelve
    def cotizacion moneda_id
      r = @client.fe_param_get_cotizacion auth.merge :mon_id => moneda_id
      x2r r[:result_get], :mon_cotiz => :float, :fch_cotiz => :date
    end
    
    def autorizar_comprobante comprobante
      request = { 'FeCAEReq' => {
        'FeCabReq' => comprobante.select_keys(:cant_reg, :cbte_tipo, :pto_vta),
        'FeDetReq' => { 
          'FECAEDetRequest' => comprobante.select_keys(:concepto, :doc_tipo, :doc_nro, :cbte_desde, 
            :cbte_hasta, :cbte_fch, :imp_total, :imp_tot_conc, :imp_neto, :imp_op_ex, :imp_trib, 
            :mon_id, :mon_cotiz, :iva).merge({ 'ImpIVA' => comprobante[:imp_iva] })
      }}}
      r = @client.fecae_solicitar auth.merge r2x(request, :cbte_fch => :date)
      x2r r[:fe_det_resp][:fecae_det_response].select_keys(:cae, :cae_fch_vto), :cae_fch_vto => :date
    end
    
    def ultimo_comprobante_autorizado opciones
      @client.fe_comp_ultimo_autorizado(auth.merge(opciones))[:cbte_nro].to_i
    end

    def consultar_comprobante opciones
      @client.fe_comp_consultar(auth.merge(opciones))[:result_get]
    end
    
    private
    def get_array response, array_element
      Array.wrap response[:result_get][array_element]
    end
  end
end
