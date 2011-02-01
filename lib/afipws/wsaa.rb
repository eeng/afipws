module Afipws
  class WSAA
    attr_reader :key, :cert, :service, :ta, :cuit, :client

    WSDL = {
      :development => "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl",
      :production => "https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl",
      :test => Root + "/spec/fixtures/wsaa.wsdl"
    }
    
    def initialize options = {}
      @key = options[:key]
      @cert = options[:cert]
      @service = options[:service] || 'wsfe'
      @ttl = options[:ttl] || 2400
      @cuit = options[:cuit]
      @client = Client.new WSDL[options[:env] || :test]
    end
    
    def generar_tra service, ttl
      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId Time.now.to_i
          xml.generationTime xsd_datetime Time.now - ttl
          # TODO me parece que no le da mucha bola el WS al expirationTime
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
      response = @client.raw_request :login_cms, 'in0' => tra(@key, @cert, @service, @ttl)
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      { :token => ta.css('token').text, :sign => ta.css('sign').text, 
        :generation_time => from_xsd_datetime(ta.css('generationTime').text),
        :expiration_time => from_xsd_datetime(ta.css('expirationTime').text) }
    rescue Savon::SOAP::Fault => f
      raise WSError, f.message
    end
    
    # Obtiene un TA, lo cachea hasta que expire, y devuelve el hash Auth listo para pasarle al Client
    # en los otros WS.
    def auth
      @ta = login if ta_expirado?
      { :auth => { :token => @ta[:token], :sign => @ta[:sign], :cuit => @cuit } }
    end
    
    private
    def ta_expirado?
      @ta.nil? or @ta[:expiration_time] <= Time.now
    end
    
    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub /(\d{2})(\d{2})$/, '\1:\2'
    end
    
    def from_xsd_datetime str
      Time.parse(str) rescue nil
    end
  end
end
