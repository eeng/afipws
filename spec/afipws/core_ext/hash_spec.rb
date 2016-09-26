require 'spec_helper'

describe Hash do
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
