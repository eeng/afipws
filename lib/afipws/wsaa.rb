module Afipws
  class WSAA
    attr_reader :key, :cert, :service
    
    def initialize options = {}
      @key = options[:key]
      @cert = options[:cert]
      @service = options[:service] || 'wsfe'
      @ttl = options[:ttl] || 2400
      @client = Client.new "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl"
    end
    
    # TODO ver si el ttl realmente se usa, el expirationTime deberia ser opcional me parece
    def generar_tra service, ttl
      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId Time.now.to_i
          xml.generationTime xsd_datetime Time.now
          xml.expirationTime xsd_datetime Time.now + ttl
        end
        xml.service service
      end
    end
    
    def firmar_tra tra, key, crt
      key = OpenSSL::PKey::RSA.new key
      crt = OpenSSL::X509::Certificate.new crt
      OpenSSL::PKCS7::sign crt, key, tra
    end
    
    def codificar_tra pkcs7
      pkcs7.to_pem.lines.to_a[1..-2].join
    end
    
    def tra key, cert, service, ttl
      codificar_tra firmar_tra(generar_tra(service, ttl), key, cert)
    end
    
    def login
      response = @client.raw_request :login_cms, :in0 => tra(@key, @cert, @service, @ttl)
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      { :token => ta.css('token').text, :sign => ta.css('sign').text }
    rescue Savon::SOAP::Fault => f
      raise WSError, f.message
    end
    
    private
    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub /(\d{2})(\d{2})$/, '\1:\2'
    end
  end
end
