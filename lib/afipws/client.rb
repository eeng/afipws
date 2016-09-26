module Afipws
  class Client
    def initialize wsdl_url, env
      @client = Savon::Client.new do
        wsdl.document = wsdl_url
        http.auth.ssl.verify_mode = :none if env == :development # Esto está porque el certificado del WSAA había vencido durante las pruebas
        http.auth.ssl.ssl_version = :SSLv3 if env == :development || Date.today >= Date.new(2016,11,1) # Esto es porque la afip cambió el algoritmo de cifrado de los certificados y sin esto no conectaba al WSFE. En el entorno de homologación ya está realizado el cambio pero en production recién el 1/11/2016.
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
      @client.request(namespace, action) { soap.body = add_ns_to_keys(body) }
    end
    
    def soap_actions
      @client.wsdl.soap_actions
    end
    
    def method_missing method_sym, *args
      request method_sym, *args
    end
    
    private
    
    def add_ns_to_keys body
      case body
      when Hash
        Hash[body.map { |k, v| ["#{namespace}:#{camelize(k)}", add_ns_to_keys(v)] }]
      when Array
        body.map { |x| add_ns_to_keys x }
      else 
        body
      end
    end
    
    def namespace
      :wsdl
    end
    
    def camelize k
      k.is_a?(String) ? k : k.to_s.camelize
    end
  end
end