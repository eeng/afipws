module Afipws
  class WSFE
    attr_reader :cuit
    
    def initialize options = {}
      @cuit = options[:cuit]
      @client = Savon::Client.new do
        wsdl.document = "http://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
      end
      @wsaa = options[:wsaa] || WSAA.new(options)
    end
    
    def dummy
      @client.request(:fe_dummy).to_hash[:fe_dummy_response][:fe_dummy_result]
    end
    
    def tipos_comprobantes
      ta = login
      
      # no puedo pasarle un hash a savon xq es necesario el namespace sino WSFE no acepta el request
      xml = Builder::XmlMarkup.new
      xml.wsdl :Auth do
        xml.wsdl :Token, ta[:token]
        xml.wsdl :Sign, ta[:sign]
        xml.wsdl :Cuit, cuit
      end
      
      response = @client.request :wsdl, :fe_param_get_tipos_cbte do
        soap.body = xml.target!
      end
      response = response.to_hash[:fe_param_get_tipos_cbte_response][:fe_param_get_tipos_cbte_result]
      if response[:result_get]
        response[:result_get][:cbte_tipo]
      else
        raise WSError, Array.wrap(response[:errors][:err])
      end
    end
    
    def login
      # TODO ver el tema de expiracion del token
      @ta ||= @wsaa.login
    end
  end
end
