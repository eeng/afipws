module Afipws
  # HTTPI normally expands cipher strings into cipher names before handing
  # them to HTTPClient, which drops OpenSSL security-level modifiers. This
  # marker lets the affected client preserve an explicit cipher expression.
  class RawSSLCipherString < String
  end

  module PreserveRawSSLCipherString
    def ciphers=(ciphers)
      return @ciphers = ciphers.to_s if ciphers.is_a?(RawSSLCipherString)

      super
    end
  end

  HTTPI::Auth::SSL.prepend PreserveRawSSLCipherString

  class Client
    def initialize savon_options
      @savon = Savon.client savon_options.reverse_merge(soap_version: 2, ssl_version: :TLSv1_2)
    end

    def request action, body = nil
      @savon.call action, message: body
    rescue Savon::SOAPFault, Savon::HTTPError => e
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
