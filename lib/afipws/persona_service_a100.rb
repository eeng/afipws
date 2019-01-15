module Afipws
  class PersonaServiceA100
    extend Forwardable
    include TypeConversions
    attr_reader :wsaa, :client, :env
    def_delegators :wsaa, :ta, :auth, :cuit, :authorized_cuit

    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      production: 'https://aws.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a100.wsdl'
    }.freeze

    def initialize options = {}
      @env = (options[:env] || :test).to_sym
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'ws_sr_padron_a100'))
      savon_options = (options[:savon])? options[:savon].merge(soap_version: 1) : {soap_version: 1}
      @client = Client.new Hash(savon_options)
        .reverse_merge(wsdl: WSDL[@env], ssl_version: :TLSv1, convert_request_keys_to: :camelcase)
    end

    def dummy
      @client.dummy[:return]
    end


    def jurisdictions
      get_parameter_collection_by_name 'SUPA.E_PROVINCIA'
    end

    def company_types
      get_parameter_collection_by_name 'SUPA.TIPO_EMPRESA_JURIDICA'
    end

    def public_organisms
      get_parameter_collection_by_name 'SUPA.E_ORGANISMO_INFORMANTE'
    end


    private

    def get_parameter_collection_by_name type
      request = {
          'token' => auth[:auth][:token],
          'sign' => auth[:auth][:sign],
          'cuitRepresentada' => auth[:auth][:cuit],
          'collectionName' => type          
      }
      @client.get_parameter_collection_by_name(request)[:parameter_collection_return][:parameter_collection]
    end



    

  end
end
