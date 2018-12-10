require 'spec_helper'

describe Afipws::TypeConversions do
  include Afipws::TypeConversions

  context 'r2x' do
    it 'debería convertir values de hashes a xml types' do
      r2x({fecha: Date.new(2011, 1, 2), id: 1}, fecha: :date).should == {fecha: '20110102', id: 1}
      r2x({container: {fecha: Date.new(2011, 1, 2)}}, fecha: :date).should == {container: {fecha: '20110102'}}
    end

    it 'debería convertir values de hashes aunque estén en arrays' do
      r2x([{fecha: Date.new(2011, 1, 2)}], fecha: :date).should == [{fecha: '20110102'}]
      r2x({container: [{fecha: Date.new(2011, 1, 2)}, {fecha: Date.new(2011, 1, 3)}]}, fecha: :date).should == {container: [{fecha: '20110102'}, {fecha: '20110103'}]}
    end
  end

  context 'x2r' do
    it 'deberia convertir values de hashes de xml types a ruby' do
      x2r({fecha: '20110102', id: '1', total: '1.23', obs: 'algo'}, fecha: :date, id: :integer, total: :float)
        .should == {fecha: Date.new(2011, 1, 2), id: 1, total: 1.23, obs: 'algo'}
      x2r({container: {id: '1'}}, id: :integer).should == {container: {id: 1}}
    end

    it 'debería hacer la conversión en arrays también' do
      x2r({container: [{id: '1'}, {id: '2'}]}, id: :integer).should == {container: [{id: 1}, {id: 2}]}
    end
  end
end
