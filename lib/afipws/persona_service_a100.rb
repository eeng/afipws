module Afipws
  class PersonaServiceA100 < WSBase
    WSDL = {
      development: 'https://awshomo.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      production: 'https://aws.afip.gov.ar/sr-parametros/webservices/parameterServiceA100?WSDL',
      test: Root + '/spec/fixtures/ws_sr_padron_a100.wsdl'
    }.freeze

    def initialize options = {}
      super
      @wsaa = WSAA.new options.merge(service: 'ws_sr_padron_a100')
      @client = Client.new Hash(options[:savon]).reverse_merge(wsdl: WSDL[env], soap_version: 1)
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
        token: auth[:token],
        sign: auth[:sign],
        cuitRepresentada: cuit,
        collectionName: type
      }
      request(:get_parameter_collection_by_name, message)[:parameter_collection_return][:parameter_collection]
    end
  end
end
