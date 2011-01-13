# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSFE do
  let :ws do 
    wsaa = stub :login => ['t', 's']
    Afipws::WSFE.new :cuit => '1', :wsaa => wsaa
  end
  
  it "dummy" do
    savon.expects(:fe_dummy).returns(:success)
    ws.dummy.should == { :app_server => "OK", :db_server => "OK", :auth_server => "OK" }
  end
  
  it "tipos_comprobantes" do
    savon.expects(:fe_param_get_tipos_cbte).with('Auth' => { 'Token' => 't', 'Sign' => 's', 'Cuit' => '1' }).returns(:success)
    ws.tipos_comprobantes.should == []
  end
  
  it "debería autenticarse usando el WSAA"
end