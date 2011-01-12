module Afipws
  class WSAA
    # TODO ver si se puede poner un ttl mas largo
    def generar_tra service = 'wsfe', ttl = 2400
      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          # TODO parametrizar source, aunque creo que son opcionales los 2 campos sigs
          xml.source "cn=VitolenDev,o=Nicolau Emmanuel,c=ar,serialNumber=CUIT 20300032673"
          xml.destination "cn=wsaa,o=afip,c=ar,serialNumber=CUIT 33693450239"
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
      Base64.encode64 pkcs7.to_pem.lines.to_a[1..-2].join
    end
    
    private
    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z')
    end
  end
end
