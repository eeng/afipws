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
      ws.tipos_comprobantes.should == [
        { :id => '1', :desc => "Factura A", :fch_desde => Date.new(2010,9,17), :fch_hasta => nil }, 
        { :id => '2', :desc => "Nota de Débito A", :fch_desde => Date.new(2010,9,18), :fch_hasta => Date.new(2011,9,18) }]
    end
    
    it "tipos_documentos" do
      savon.expects('FEParamGetTiposDoc').returns(:success)
      ws.tipos_documentos.should == [
        { :id => '80', :desc => "CUIT", :fch_desde => Date.new(2008,7,25), :fch_hasta => nil }]
    end
    
    it "tipos_monedas" do
      savon.expects('FEParamGetTiposMonedas').returns(:success)
      ws.tipos_monedas.should == [
        { :id => 'PES', :desc => "Pesos Argentinos", :fch_desde => Date.new(2009,4,3), :fch_hasta => nil }, 
        { :id => '002', :desc => "Dólar Libre EEUU", :fch_desde => Date.new(2009,4,16), :fch_hasta => nil }]
    end
  end
  
  context "autenticacion" do
    it "debería autenticarse usando el WSAA" do
      wsfe = Afipws::WSFE.new :cuit => '1', :cert => 'cert', :key => 'key'
      wsfe.wsaa.cert.should == 'cert'
      wsfe.wsaa.key.should == 'key'
      wsfe.wsaa.service.should == 'wsfe'
      wsfe.wsaa.expects(:login).returns({ :token => 't', :sign => 's' })
      savon.expects('FEParamGetTiposCbte').with('wsdl:Auth' => {'wsdl:Token' => 't', 'wsdl:Sign' => 's', 'wsdl:Cuit' => '1'}).returns(:success)
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