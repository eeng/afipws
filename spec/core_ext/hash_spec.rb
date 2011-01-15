# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hash do
  context "fetch_path" do
    it "deberia aceptar un path como /../.. y retornar el value" do
      hash = { '1' => 2, '3' => { '4' => '5', '6' => { '7' => '8' } } }
      hash.fetch_path('/1').should == 2
      hash.fetch_path('/1/2').should == nil
      hash.fetch_path('/2').should == nil
      hash.fetch_path('/3/4').should == '5'
      hash.fetch_path('/3/6').should == { '7' => '8' }
      hash.fetch_path('/3/6/7').should == '8'
    end
    
    it "debería permitir acceder a values tipo array con subindice" do
      hash = { '1' => [{ '2' => 3 }, { '4' => 5 }] }
      hash.fetch_path('/1[0]/2').should == 3
      hash.fetch_path('/1[1]/4').should == 5
      hash.fetch_path('/1[0]').should == { '2' => 3 }
      hash.fetch_path('/1[2]').should == nil
    end
  end
  
  context "select_keys" do
    it "debería tomar los values de las keys indicadas" do
      hash = Hash[1, 2, 3, 4]
      hash.select_keys(1).should == {1 => 2}
      hash.select_keys(1, 3).should == {1 => 2, 3 => 4}
      hash.select_keys(5).should == {}
      hash.select_keys(5, 3).should == {3 => 4}
    end
  end
  
  context "has_entries?" do
    subject { Hash[1, 2, 3, 4] }
    
    it "debería devolver true cuando self incluye todas las entries del hash parametro" do
      should have_entries 1 => 2
      should have_entries 3 => 4, 1 => 2
      should_not have_entries 1 => 3
    end
  end
end
