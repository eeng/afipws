module Afipws
  class Client
    def initialize wsdl_url, env
      @client = Savon.client do
        wsdl wsdl_url
        ssl_verify_mode :none if env == :development # Esto está porque el certificado del WSAA había vencido durante las pruebas
        ssl_version :SSLv3 if env == :development || Date.today >= Date.new(2016,11,1) # Esto es porque la afip cambió el algoritmo de cifrado de los certificados y sin esto no conectaba al WSFE. En el entorno de homologación ya está realizado el cambio pero en production recién el 1/11/2016.
        log true
        log_level :debug
      end
    end
    
    def request action, body = nil
      response = raw_request(action, body).to_hash[:"#{action}_response"][:"#{action}_result"]
      if response[:errors]
        raise WSError, Array.wrap(response[:errors][:err])
      else
        response
      end
    end
    
    def raw_request action, body = nil
      @client.call action, message: body
    end
    
    def soap_actions
      @client.wsdl.soap_actions
    end
    
    def method_missing method_sym, *args
      request method_sym, *args
    end
  end
end