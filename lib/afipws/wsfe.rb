module Afipws
  class WSFE
    attr_reader :cuit, :wsaa, :ta
    
    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = options[:wsaa] || WSAA.new(options.merge(:service => 'wsfe'))
      @client = Client.new "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
    end
    
    def dummy
      @client.fe_dummy
    end
    
    def tipos_comprobantes
      autenticar_y_tomar_array :cbte_tipo do |auth|
        @client.fe_param_get_tipos_cbte auth
      end
    end
    
    def tipos_documentos
      autenticar_y_tomar_array :doc_tipo do |auth|
        @client.fe_param_get_tipos_doc auth
      end
    end

    def login
      # TODO ver el tema de expiracion del token
      @ta ||= @wsaa.login
    end
    
    private
    def autenticar
      ta = login
      yield 'Auth' => { 'Token' => ta[:token], 'Sign' => ta[:sign], 'Cuit' => cuit }
    end
    
    def autenticar_y_tomar_array array_element, &block
      response = autenticar &block
      Array.wrap response[:result_get][array_element]
    end
  end
end
