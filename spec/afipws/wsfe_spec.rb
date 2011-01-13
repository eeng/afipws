# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSFE do
  let :ws do 
    wsaa = stub :login => { :token => 't', :sign => 's' }
    Afipws::WSFE.new :cuit => '1', :wsaa => wsaa
  end
  
  context "Métodos de negocio" do
    it "dummy" do
      savon.expects('FEDummy').returns(:success)
      ws.dummy.should == { :app_server => "OK", :db_server => "OK", :auth_server => "OK" }
    end

    it "tipos_comprobantes" do
      savon.expects('FEParamGetTiposCbte').returns(:success)
      # TODO quizas convendria convertir los tipos de datos date, null, integer
      ws.tipos_comprobantes.should == [
        { :id => "1", :desc => "Factura A", :fch_desde => "20100917", :fch_hasta => "NULL" }, 
        { :id => "2", :desc => "Nota de Débito A", :fch_desde => "20100917", :fch_hasta => "NULL" }]
    end
    
    it "tipos_documentos" do
      savon.expects('FEParamGetTiposDoc').returns(:success)
      ws.tipos_documentos.should == [
        { :id => "80", :desc => "CUIT", :fch_desde => "20080725", :fch_hasta => "NULL" }]
    end
  end
  
  context "autenticacion" do
    it "debería autenticarse usando el WSAA" do
      wsfe = Afipws::WSFE.new :cuit => '1', :cert => 'cert', :key => 'key'
      wsfe.wsaa.cert.should == 'cert'
      wsfe.wsaa.key.should == 'key'
      wsfe.wsaa.service.should == 'wsfe'
      wsfe.wsaa.expects(:login).returns({ :token => 't', :sign => 's' })
      savon.expects('FEParamGetTiposCbte').with('<wsdl:Auth><wsdl:Token>t</wsdl:Token><wsdl:Sign>s</wsdl:Sign><wsdl:Cuit>1</wsdl:Cuit></wsdl:Auth>').returns(:success)
      wsfe.tipos_comprobantes
    end
  end
  
  context "manejo de errores" do
    it "cuando hay un error" do
      savon.expects('FEParamGetTiposCbte').returns(:failure_1_error)
      expect { ws.tipos_comprobantes }.to raise_error { |e| 
        e.should be_a Afipws::WSError
        e.errors.should == [{ :code => "600", :msg => "No se corresponden token con firma" }] 
        e.message.should == "600: No se corresponden token con firma" 
      }
    end

    it "cuando hay varios errores" do
      savon.expects('FEParamGetTiposCbte').returns(:failure_2_errors)
      expect { ws.tipos_comprobantes }.to raise_error { |e| 
        e.should be_a Afipws::WSError
        e.errors.should == [{ :code => "600", :msg => "No se corresponden token con firma" }, { :code => "601", :msg => "CUIT representada no incluida en token" }] 
        e.message.should == "600: No se corresponden token con firma; 601: CUIT representada no incluida en token" 
      }
    end
  end
end