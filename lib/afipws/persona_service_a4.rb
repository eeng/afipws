module Afipws
  class PersonaServiceA4
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client, :env
    def_delegators :wsaa, :ta, :auth, :cuit, :authorized_cuit

    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      production: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA4?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a4.wsdl'
    }.freeze

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'ws_sr_padron_a4'))
      savon_options = (options[:savon])? options[:savon].merge(soap_version: 1) : {soap_version: 1}
      @client = Client.new Hash(savon_options)
        .reverse_merge(wsdl: WSDL[@env], ssl_version: :TLSv1, convert_request_keys_to: :camelcase)
    end

    def dummy
      @client.dummy[:return]
    end


    def get_persona tin
      request = {
          'token' => auth[:auth][:token],
          'sign' => auth[:auth][:sign],
          'cuitRepresentada' => auth[:auth][:cuit],
          'idPersona' => tin          
      }
      @client.get_persona(request)[:persona_return][:persona]
    end




    

  end
end
