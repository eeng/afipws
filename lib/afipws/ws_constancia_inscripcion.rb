module Afipws
  class WSConstanciaInscripcion
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      test: Root + '/spec/fixtures/ws_sr_constancia_inscripcion/ws_constancia_inscripcion.wsdl'
    }.freeze

    attr_reader :wsaa

    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = WSAA.new options.merge(service: 'ws_sr_constancia_inscripcion')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@wsaa.env], soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
    end

    def get_persona id
      message = @wsaa.auth.merge(cuit_representada: @cuit, id_persona: id)
      request(:get_persona, message)[:persona_return]
    end

    private

    def request action, body = nil
      @client.request(action, body).to_hash[:"#{action}_response"]
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end
  end
end
