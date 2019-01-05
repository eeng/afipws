module Afipws
  class PersonaServiceA4 < WSBase
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a4.wsdl'
    }.freeze

    def initialize options = {}
      super
      @wsaa = WSAA.new options.merge(service: 'ws_sr_padron_a4')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[env], soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
    end

    def get_persona id
      message = auth.merge(cuitRepresentada: cuit, idPersona: id)
      request(:get_persona, message)[:persona_return][:persona]
    end
  end
end
