module Afipws
  class Client
    def initialize wsdl_url
      @client = Savon::Client.new { wsdl.document = wsdl_url }
    end
    
    def request action, body = nil
      response = @client.request(namespace, action) { soap.body = add_ns_to_keys(body) }.to_hash[:"#{action}_response"][:"#{action}_result"]
      if response[:errors]
        raise WSError, Array.wrap(response[:errors][:err])
      else
        response
      end
    end
    
    def method_missing method_sym, *args
      request method_sym, *args
    end
    
    private
    def add_ns_to_keys body
      if body.is_a? Hash
        Hash[body.map { |k, v| ["#{namespace}:#{k}", add_ns_to_keys(v)] }]
      else
        body
      end
    end
    
    def namespace
      :wsdl
    end
  end
end