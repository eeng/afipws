require 'spec_helper'

module Afipws
  describe PersonaServiceA100 do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { PersonaServiceA100.new(cuit: '12345678912').tap { |ws| ws.wsaa.stubs auth: ta } }
    let(:message) { ta.merge cuitRepresentada: '12345678912' }

    context 'métodos API' do
      it 'dummy' do
        savon.expects(:dummy).returns(fixture('ws_sr_padron_a100/dummy/success'))
        ws.dummy.should == { appserver: 'OK', authserver: 'OK', dbserver: 'OK' }
      end

      it 'jurisdictions' do
        savon.expects(:get_parameter_collection_by_name)
          .with(message: message.merge(collectionName: 'SUPA.E_PROVINCIA'))
          .returns(fixture('ws_sr_padron_a100/jurisdictions/success'))
        ws.jurisdictions.should have_entries name: 'SUPA.E_PROVINCIA'
      end

      it 'company_types' do
        savon.expects(:get_parameter_collection_by_name)
          .with(message: message.merge(collectionName: 'SUPA.TIPO_EMPRESA_JURIDICA'))
          .returns(fixture('ws_sr_padron_a100/company_types/success'))
        ws.company_types.should have_entries name: 'SUPA.TIPO_EMPRESA_JURIDICA'
      end

      it 'public_organisms' do
        savon.expects(:get_parameter_collection_by_name)
          .with(message: message.merge(collectionName: 'SUPA.E_ORGANISMO_INFORMANTE'))
          .returns(fixture('ws_sr_padron_a100/public_organisms/success'))
        ws.public_organisms.should have_entries name: 'SUPA.E_ORGANISMO_INFORMANTE'
      end
    end
  end
end
