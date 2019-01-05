module Afipws
  class WSBase
    extend Forwardable

    attr_reader :wsaa, :client, :env
    def_delegators :wsaa, :cuit

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
    end
  end
end
