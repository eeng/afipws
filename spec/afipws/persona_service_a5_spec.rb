require 'spec_helper'

module Afipws
  describe PersonaServiceA5 do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { PersonaServiceA5.new(cuit: '12345678912').tap { |ws| ws.wsaa.stubs auth: ta } }
    let(:message) { ta.merge cuitRepresentada: '12345678912' }

    context 'métodos API' do
      it 'dummy' do
        savon.expects(:dummy).returns(fixture('ws_sr_padron_a5/dummy/success'))
        ws.dummy.should == { appserver: 'OK', authserver: 'OK', dbserver: 'OK' }
      end

      it 'get_persona' do
        savon.expects(:get_persona)
          .with(message: message.merge(idPersona: '98765432198'))
          .returns(fixture('ws_sr_padron_a5/get_persona/success'))
        ws.get_persona('98765432198').should have_key :datos_generales
      end
    end
  end
end
