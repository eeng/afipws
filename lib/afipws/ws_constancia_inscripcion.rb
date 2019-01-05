module Afipws
  class WSConstanciaInscripcion < WSBase
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      test: Root + '/spec/fixtures/ws_constancia_inscripcion.wsdl'
    }.freeze

    def initialize options = {}
      super
      @wsaa = WSAA.new options.merge(service: 'ws_sr_constancia_inscripcion')
      @client = Client.new Hash(options[:savon])
        .reverse_merge(wsdl: WSDL[env], ssl_version: :TLSv1, soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
    end

    def get_persona id
      request(:get_persona, auth.merge(id_persona: id))[:persona_return]
    end

    def auth
      wsaa.auth.merge(cuit_representada: cuit)
    end

    private

    def request action, body = nil
      @client.request(action, body).to_hash[:"#{action}_response"]
    end
  end
end
