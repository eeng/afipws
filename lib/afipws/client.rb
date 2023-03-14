module Afipws
  class Client
    def initialize savon_options
      @savon = Savon.client savon_options.reverse_merge(soap_version: 2, ssl_version: :TLSv1_2)
    end

    def request action, body = nil
      @savon.call action, message: body
    rescue Savon::SOAPFault => e
      raise ServerError, e
    rescue HTTPClient::ConnectTimeoutError => e
      raise NetworkError.new(e, retriable: true)
    rescue HTTPClient::TimeoutError => e
      raise NetworkError, e
    end

    def operations
      @savon.operations
    end
  end
end
