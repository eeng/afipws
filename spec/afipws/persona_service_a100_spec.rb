require 'spec_helper'

describe Afipws::PersonaServiceA100 do
  let(:auth) { {auth: {token: 't', sign: 's', cuit: '12345678912', expiration_time: 12.hours.from_now}} }
  let(:message) { {token: 't', sign: 's', cuitRepresentada: '12345678912', collectionName: ''} }    
  let(:ws) { Afipws::PersonaServiceA100.new cuit: '1', wsaa: Afipws::WSAA.new.tap { |wsaa| wsaa.stubs auth: auth } }

  context "Métodos de negocio" do
    it "dummy" do
      savon.expects(:dummy).returns(fixture('ws_sr_padron_a100/dummy/success'))
      ws.dummy.should == { appserver: "OK", authserver: "OK", dbserver: "OK" }
    end

    it "jurisdictions" do
      message['collectionName'] = 'SUPA.E_PROVINCIA'
      savon.expects(:get_parameter_collection_by_name).with(message: message.stringify_keys).returns(fixture('ws_sr_padron_a100/jurisdictions/success'))
      rta = ws.jurisdictions
      rta.should have_entries name: 'SUPA.E_PROVINCIA' 
    end

    it "company_types" do
      message['collectionName'] = 'SUPA.TIPO_EMPRESA_JURIDICA'
      savon.expects(:get_parameter_collection_by_name).with(message: message.stringify_keys).returns(fixture('ws_sr_padron_a100/company_types/success'))
      rta = ws.company_types
      rta.should have_entries name: 'SUPA.TIPO_EMPRESA_JURIDICA' 
    end

    it "public_organisms" do
      message['collectionName'] = 'SUPA.E_ORGANISMO_INFORMANTE'
      savon.expects(:get_parameter_collection_by_name).with(message: message.stringify_keys).returns(fixture('ws_sr_padron_a100/public_organisms/success'))
      rta = ws.public_organisms
      rta.should have_entries name: 'SUPA.E_ORGANISMO_INFORMANTE' 
    end




  end

end

