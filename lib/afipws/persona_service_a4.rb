module Afipws
  class PersonaServiceA4
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a4.wsdl'
    }.freeze

    attr_reader :wsaa

    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = WSAA.new options.merge(service: 'ws_sr_padron_a4')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@wsaa.env], soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
    end

    def get_persona id
      message = @wsaa.auth.merge(cuitRepresentada: @cuit, idPersona: id)
      request(:get_persona, message)[:persona_return][:persona]
    end

    private

    def request action, body = nil
      @client.request(action, body).to_hash[:"#{action}_response"]
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end
  end
end
