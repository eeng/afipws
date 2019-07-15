module Afipws
  class WSConstanciaInscripcion < WSBase
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL',
      test: Root + '/spec/fixtures/ws_sr_constancia_inscripcion/ws_constancia_inscripcion.wsdl'
    }.freeze

    def initialize options = {}
      super
      @wsaa = WSAA.new options.merge(service: 'ws_sr_constancia_inscripcion')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[env], soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
    end

    def get_persona id
      message = auth.merge(cuit_representada: cuit, id_persona: id)
      request(:get_persona, message)[:persona_return]
    end
  end
end
