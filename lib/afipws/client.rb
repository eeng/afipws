module Afipws
  class Client
    def initialize savon_options
      @client = Savon.client savon_options.reverse_merge(soap_version: 2, ssl_version: :TLSv1_2)
    end

    def request action, body = nil
      @client.call action, message: body
    end

    def operations
      @client.operations
    end
  end
end
