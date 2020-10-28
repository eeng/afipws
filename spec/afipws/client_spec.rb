require 'spec_helper'

module Afipws
  describe Client do
    context 'manejo de errores' do
      subject { Client.new(wsdl: Afipws::WSFE::WSDL[:test]) }

      it 'SOAPFault se encapsulan en ServerError' do
        savon.expects(:fe_dummy).returns(fixture('wsaa/login_cms/fault'))
        -> { subject.request :fe_dummy }.should raise_error ServerError, /CMS no es valido/
      end
    end
  end
end
