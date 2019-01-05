module Afipws
  class WSBase
    extend Forwardable

    attr_reader :wsaa, :client, :env
    def_delegators :wsaa, :cuit, :auth

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
    end

    def request action, body = nil
      @client.request(action, body).to_hash[:"#{action}_response"]
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end
  end
end
