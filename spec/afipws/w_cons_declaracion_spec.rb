require 'spec_helper'

module Afipws
  describe WConsDeclaracion do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { WConsDeclaracion.new(env: :test, cuit: '23076925089').tap { |ws| ws.wsaa.stubs auth: ta } }

    it 'utiliza los parámetros correctos en el WSAA' do
      ws.wsaa.service.should == 'wconsdeclaracion'
      ws.wsaa.cuit.should == '23076925089'
      ws.wsaa.env.should == :test
    end

    context 'métodos del WS' do
      it 'dummy' do
        savon.expects(:dummy).returns(fixture('wconsdeclaracion/dummy/success'))
        ws.dummy.should == {app_server: 'OK', db_server: 'OK', auth_server: 'OK'}
      end

      context 'detallada_lista_declaraciones' do
        it 'x id declaración' do
          message = with_auth_section(
            'argDetalladasListaParams' => {
              'CuitImportadorExportador' => '23076925089',
              'IdentificadorDeclaracion' => '19093SIMI000434X'
            }
          )
          savon.expects(:detallada_lista_declaraciones).with(message: message)
            .returns(fixture('wconsdeclaracion/detallada_lista_declaraciones/por_id_success'))
          declaracion = ws.detallada_lista_declaraciones identificador_declaracion: '19093SIMI000434X'
          declaracion.should include identificador_declaracion: '19093SIMI000434X', cuit_importador_exportador: '23076925089'
        end

        it 'x rango de fecha de oficialización' do
          message = with_auth_section(
            'argDetalladasListaParams' => {
              'CuitImportadorExportador' => '23076925089',
              'FechaOficializacionDesde' => '2019-04-01T00:00:00-03:00',
              'FechaOficializacionHasta' => '2019-04-30T00:00:00-03:00'
            }
          )
          savon.expects(:detallada_lista_declaraciones).with(message: message)
            .returns(fixture('wconsdeclaracion/detallada_lista_declaraciones/por_fecha_success'))
          declaraciones = ws.detallada_lista_declaraciones(
            fecha_oficializacion_desde: Time.parse('2019-04-01T00:00:00-03:00'),
            fecha_oficializacion_hasta: Time.parse('2019-04-30T00:00:00-03:00')
          )
          declaraciones.should match_array [
            include(identificador_declaracion: '19092SIMI000313M'),
            include(identificador_declaracion: '19092SIMI000314N')
          ]
        end

        it 'x id inexistente' do
          savon.expects(:detallada_lista_declaraciones).with(message: :any)
            .returns(fixture('wconsdeclaracion/detallada_lista_declaraciones/por_id_inexistente'))
          -> { ws.detallada_lista_declaraciones identificador_declaracion: '...' }
            .should raise_error ResponseError, '21248: Declaracion 19093SIMI000434. inexistente o invalida'
        end
      end

      context 'detallada_estado' do
        it 'caso exitoso' do
          message = with_auth_section('argIdentificadorDestinacion' => '19093SIMI000434X')
          savon.expects(:detallada_estado).with(message: message)
            .returns(fixture('wconsdeclaracion/detallada_estado/success'))
          ws.detallada_estado('19093SIMI000434X').should include(
            fecha_salida: DateTime.parse('2019-04-25T18:48:12'),
            fecha_cancelacion: DateTime.parse('2019-07-04T02:29:34')
          )
        end
      end

      def with_auth_section message
        {
          'argWSAutenticacionEmpresa' => {
            'Token' => 't',
            'Sign' => 's',
            'CuitEmpresaConectada' => '23076925089',
            'TipoAgente' => 'IMEX',
            'Rol' => 'IMEX'
          }
        }.merge message
      end
    end
  end
end
