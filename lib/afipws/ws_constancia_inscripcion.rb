module Afipws
  class WSConstanciaInscripcion
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client, :env, :constancia_de
    def_delegators :wsaa, :ta, :cuit

    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      test: Root + '/spec/fixtures/ws_constancia_inscripcion.wsdl'
    }.freeze

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'ws_sr_constancia_inscripcion'))
      @client = Client.new Hash(options[:savon])
        .reverse_merge(wsdl: WSDL[@env], ssl_version: :TLSv1, soap_version: 1)
    end

    def dummy
      @client.request(:dummy).to_hash[:dummy_response][:return]
    end

    def get_persona id
      @client.request(:get_persona, auth.merge(id_persona: id)).to_hash[:get_persona_response][:persona_return]
    end

    private

    def auth
      wsaa.auth.merge(cuit_representada: cuit)
    end
  end
end
