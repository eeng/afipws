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
      token, sign = login
      
      xml = Builder::XmlMarkup.new
      xml.wsdl :Auth do
        xml.wsdl :Token, token
        xml.wsdl :Sign, sign
        xml.wsdl :Cuit, cuit
      end
      
      @client.request :wsdl, :fe_param_get_tipos_cbte do
        soap.body = xml.to_xml
      end
    end
    
    def login
      @token_and_sign ||= @wsaa.login
    end
  end
end
