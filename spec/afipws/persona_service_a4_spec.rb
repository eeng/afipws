require 'spec_helper'

describe Afipws::PersonaServiceA4 do
  let(:auth) { {auth: {token: 't', sign: 's', cuit: '12345678912', expiration_time: 12.hours.from_now}} }
  let(:message) { {token: 't', sign: 's', cuitRepresentada: '12345678912', idPersona: '98765432198'} }  
  let(:ws) { Afipws::PersonaServiceA4.new cuit: '1', wsaa: Afipws::WSAA.new.tap { |wsaa| wsaa.stubs auth: auth } }

  context "Métodos de negocio" do
    it "dummy" do
      savon.expects(:dummy).returns(fixture('ws_sr_padron_a4/dummy/success'))
      ws.dummy.should == { appserver: "OK", authserver: "OK", dbserver: "OK" }
    end


    it "get_persona" do
      savon.expects(:get_persona).with(message: message.stringify_keys).returns(fixture('ws_sr_padron_a4/get_persona/success'))
      rta = ws.get_persona('98765432198')
      rta.should have_entries apellido: 'ERNESTO DANIEL' 
    end

  end

end
