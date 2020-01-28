module Afipws
  class PersonaServiceA100
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      production: 'https://aws.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a100.wsdl'
    }.freeze

    attr_reader :wsaa

    def initialize options = {}
      @cuit = options[:cuit]
      @wsaa = WSAA.new options.merge(service: 'ws_sr_padron_a100')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[@wsaa.env], soap_version: 1)
    end

    def dummy
      request(:dummy)[:return]
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
      message = {
        token: @wsaa.auth[:token],
        sign: @wsaa.auth[:sign],
        cuitRepresentada: @cuit,
        collectionName: type
      }
      request(:get_parameter_collection_by_name, message)[:parameter_collection_return][:parameter_collection]
    end

    def request action, body = nil
      @client.request(action, body).to_hash[:"#{action}_response"]
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end
  end
end
