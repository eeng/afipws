module Afipws
  class WConsDeclaracion
    WSDL = {
      development: 'https://wsaduhomoext.afip.gob.ar/diav2/wconsdeclaracion/wconsdeclaracion.asmx?WSDL',
      production: 'https://webservicesadu.afip.gov.ar/DIAV2/wconsdeclaracion/wconsdeclaracion.asmx?WSDL',
      test: Root + '/spec/fixtures/wconsdeclaracion/wconsdeclaracion.wsdl'
    }.freeze

    def initialize env: :development, cuit:, tipo_agente: 'IMEX', rol: 'IMEX', savon: {}, **options
      @cuit, @tipo_agente, @rol = cuit, tipo_agente, rol
      @wsaa = options[:wsaa] || WSAA.new(options.merge(service: 'wconsdeclaracion', env: env, cuit: cuit))
      @client = Client.new(savon.reverse_merge(wsdl: WSDL[env]))
    end

    def dummy
      request :dummy
    end

    def detallada_lista_declaraciones identificador_declaracion: nil, fecha_oficializacion_desde: nil, fecha_oficializacion_hasta: nil
      message = {
        'argDetalladasListaParams' => {
          'CuitImportadorExportador' => @cuit,
          'IdentificadorDeclaracion' => identificador_declaracion,
          'FechaOficializacionDesde' => fecha_oficializacion_desde&.iso8601,
          'FechaOficializacionHasta' => fecha_oficializacion_hasta&.iso8601
        }.compact
      }
      request(:detallada_lista_declaraciones, auth.merge(message))[:declaraciones][:declaracion]
    end

    def detallada_estado identificador_declaracion
      message = {'argIdentificadorDestinacion' => identificador_declaracion}
      request(:detallada_estado, auth.merge(message))[:estado]
    end

    private

    def request action, body = nil
      response = @client.request(action, body).to_hash[:"#{action}_response"][:"#{action}_result"]
      if response[:lista_errores] && response[:lista_errores][:detalle_error][:codigo] != '0'
        raise WSError, Array.wrap(response[:lista_errores][:detalle_error]).map { |e| {code: e[:codigo], msg: e[:descripcion]} }
      else
        response
      end
    rescue Savon::SOAPFault => f
      raise WSError, f.message
    end

    def auth
      {
        'argWSAutenticacionEmpresa' => {
          'Token' => @wsaa.auth[:token],
          'Sign' => @wsaa.auth[:sign],
          'CuitEmpresaConectada' => @cuit,
          'TipoAgente' => @tipo_agente,
          'Rol' => @rol
        }
      }
    end
  end
end
