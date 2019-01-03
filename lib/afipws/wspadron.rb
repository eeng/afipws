module Afipws
  class WSPadron
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client, :env, :constancia_de
    def_delegators :wsaa, :ta, :cuit

    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      # production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      production: Root + '/lib/afipws/wspadronv1.wsdl',
      test: Root + '/spec/fixtures/wspadron.wsdl'
    }.freeze

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @constancia_de = options[:constancia_de]
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'ws_sr_constancia_inscripcion'))
      @client = Client.new Hash(options[:savon])
        .reverse_merge(wsdl: WSDL[@env], ssl_version: :TLSv1, soap_version: 1)
    end

    def dummy
      @client.request(:dummy).to_hash[:dummy_response][:return]
    end

    def get_persona
      response = @client.request(:get_persona, auth).to_hash[:get_persona_response][:persona_return]
      if response[:errors]
        raise WSError, Array.wrap(response[:errors][:err])
      else
        response
      end
    end

    private

    def auth
      wsaa.auth.merge(cuit_representada: cuit, id_persona: constancia_de)
    end
  end
end
