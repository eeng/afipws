# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSFE do
  let :ws do 
    wsaa = stub :login => ['t', 's']
    Afipws::WSFE.new :cuit => '1', :wsaa => wsaa
  end
  
  it "dummy" do
    savon.expects('FEDummy').returns(:success)
    ws.dummy.should == { :app_server => "OK", :db_server => "OK", :auth_server => "OK" }
  end
  
  it "tipos_comprobantes" do
    savon.expects('FEParamGetTiposCbte').with('<wsdl:Auth><wsdl:Token>t</wsdl:Token><wsdl:Sign>s</wsdl:Sign><wsdl:Cuit>1</wsdl:Cuit></wsdl:Auth>').returns(:success)
    # TODO quizas convendria convertir los tipos de datos date, null, integer
    ws.tipos_comprobantes.should == [
      { :id => "1", :desc => "Factura A", :fch_desde => "20100917", :fch_hasta => "NULL" }, 
      { :id => "2", :desc => "Nota de Débito A", :fch_desde => "20100917", :fch_hasta => "NULL" }]
  end
  
  it "debería autenticarse usando el WSAA"
end