module Afipws
  class Client
    def initialize savon_options
      @client = Savon.client savon_options.reverse_merge(soap_version: 2, read_timeout: 120, open_timeout: 120)
      @client
    end


    def request action, body = nil
      response = raw_request(action, body).to_hash[:"#{action}_response"]
      if response[:"#{action}_result"].present?
        #wsfe
        response = response[:"#{action}_result"]
        if response[:errors]
          raise WSError, Array.wrap(response[:errors][:err])
        else
          response
        end
      else
        #idenfitfy errors?
        response
      end
        
    end

    def raw_request action, body = nil
      @client.call action, message: body
    end

    def operations
      @client.operations
    end

    def method_missing method_sym, *args
      request method_sym, *args
    end
  end
end
