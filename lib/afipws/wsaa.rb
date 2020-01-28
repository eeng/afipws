module Afipws
  class WSAA
    attr_reader :key, :cert, :service, :ta, :cuit, :client, :env

    WSDL = {
      development: 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl',
      production: 'https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl',
      test: Root + '/spec/fixtures/wsaa/wsaa.wsdl'
    }

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @key = options[:key]
      @cert = options[:cert]
      @service = options[:service] || 'wsfe'
      @ttl = options[:ttl] || 2400
      @cuit = options[:cuit]
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@env])
      @ta_path = options[:ta_path] || File.join(Dir.pwd, 'tmp', "#{@cuit}-#{@env}-#{@service}-ta.dump")
    end

    def generar_tra service, ttl
      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId Time.now.to_i
          xml.generationTime xsd_datetime Time.now - ttl
          xml.expirationTime xsd_datetime Time.now + ttl
        end
        xml.service service
      end
    end

    def firmar_tra tra, key, crt
      key = OpenSSL::PKey::RSA.new key
      crt = OpenSSL::X509::Certificate.new crt
      OpenSSL::PKCS7.sign crt, key, tra
    end

    def codificar_tra pkcs7
      pkcs7.to_pem.lines.to_a[1..-2].join
    end

    def tra key, cert, service, ttl
      codificar_tra firmar_tra(generar_tra(service, ttl), key, cert)
    end

    def login
      response = @client.request :login_cms, in0: tra(@key, @cert, @service, @ttl)
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      {
        token: ta.css('token').text,
        sign: ta.css('sign').text,
        generation_time: from_xsd_datetime(ta.css('generationTime').text),
        expiration_time: from_xsd_datetime(ta.css('expirationTime').text)
      }
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end

    def auth
      ta = obtener_y_cachear_ta
      {token: ta[:token], sign: ta[:sign]}
    end

    private

    # Previene el error 'El CEE ya posee un TA valido para el acceso al WSN solicitado' que se genera cuando se pide el token varias veces en poco tiempo
    def obtener_y_cachear_ta
      @ta ||= restore_ta
      if ta_expirado? @ta
        @ta = login
        persist_ta @ta
      end
      @ta
    end

    def ta_expirado? ta
      ta.nil? || ta[:expiration_time] <= Time.now
    end

    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub /(\d{2})(\d{2})$/, '\1:\2'
    end

    def from_xsd_datetime str
      Time.parse(str) rescue nil
    end

    def restore_ta
      Marshal.load(File.read(@ta_path)) if File.exist?(@ta_path) && !File.zero?(@ta_path)
    end

    def persist_ta ta
      FileUtils.mkdir_p(File.dirname(@ta_path))
      File.open(@ta_path, 'wb') { |f| f.write(Marshal.dump(ta)) }
    end
  end
end
