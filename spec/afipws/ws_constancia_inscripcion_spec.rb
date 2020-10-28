require 'spec_helper'

module Afipws
  describe WSConstanciaInscripcion do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { WSConstanciaInscripcion.new(cuit: '1').tap { |ws| ws.wsaa.stubs auth: ta } }
    let(:message) { ta.merge cuit_representada: '1' }

    context 'métodos API' do
      it 'dummy' do
        savon.expects(:dummy).returns(fixture('ws_sr_constancia_inscripcion/dummy/success'))
        ws.dummy.should == { appserver: 'OK', dbserver: 'OK', authserver: 'OK' }
      end

      it 'debería devolver un hash con los datos generales y regímenes impositivos' do
        savon.expects(:get_persona)
          .with(message: message.merge(id_persona: '20294834487'))
          .returns(fixture('ws_sr_constancia_inscripcion/get_persona/success'))
        r = ws.get_persona '20294834487'
        r[:datos_generales].should include(
          estado_clave: 'ACTIVO', mes_cierre: '6', razon_social: 'LA REGALERIA S A',
          tipo_clave: 'CUIT', tipo_persona: 'JURIDICA'
        )
        r[:datos_generales][:domicilio_fiscal].should include(
          cod_postal: '2300', descripcion_provincia: 'SANTA FE',
          direccion: 'AV SIEMPRE VIVA 123', localidad: 'NUEVA YORK', tipo_domicilio: 'FISCAL'
        )
        r[:datos_regimen_general][:actividad].should include(
          id_actividad: '477330', nomenclador: '883', orden: '2', periodo: '201311'
        )
        r[:datos_regimen_general][:impuesto][1].should include(
          descripcion_impuesto: 'IVA', id_impuesto: '30', periodo: '198903'
        )
        r[:datos_regimen_general][:regimen].should include(
          id_impuesto: '208', id_regimen: '159', periodo: '199403'
        )
      end

      it 'cuando hay errores en la constancia sigue la misma lógica' do
        savon.expects(:get_persona)
          .with(message: message.merge(id_persona: '20294834489'))
          .returns(fixture('ws_sr_constancia_inscripcion/get_persona/failure'))
        r = ws.get_persona '20294834489'
        r[:error_regimen_general].should include(
          error: 'El contribuyente cuenta con impuestos con baja de oficio por Decreto 1299/98',
          mensaje: 'No cumple con las condiciones para enviar datos del regimen general'
        )
      end

      it 'cuando no existe la persona' do
        savon.expects(:get_persona)
          .with(message: message.merge(id_persona: '123'))
          .returns(fixture('ws_sr_constancia_inscripcion/get_persona/fault'))
        -> { ws.get_persona '123' }.should raise_error ServerError, /No existe persona con ese Id/
      end
    end

    context 'entorno' do
      it 'debería usar las url para development cuando el env es development' do
        Client.expects(:new).with(wsdl: 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl')
        Client.expects(:new).with(wsdl: 'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL', soap_version: 1)
        WSConstanciaInscripcion.new env: :development
      end

      it 'debería usar las url para production cuando el env es production' do
        Client.expects(:new).with(wsdl: 'https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl')
        Client.expects(:new).with(wsdl: 'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL', soap_version: 1)
        WSConstanciaInscripcion.new env: :production
      end
    end
  end
end
