require 'spec_helper'

module Afipws
  describe Client do
    context 'manejo de errores' do
      subject { Client.new(wsdl: Afipws::WSFE::WSDL[:test]) }

      it 'Savon::SOAPFault se encapsulan en ServerError' do
        savon.expects(:fe_dummy).returns(fixture('wsaa/login_cms/fault'))
        -> { subject.request :fe_dummy }.should raise_error ServerError, /CMS no es valido/
      end

      it 'HTTPClient::TimeoutError se encapsulan en NetworkError' do
        # Hack to mock exceptions on Savon
        subject.instance_eval('@savon').expects(:call).raises(HTTPClient::ReceiveTimeoutError, 'execution expired')
        -> { subject.request :fe_dummy }.should raise_error NetworkError, /execution expired/
      end
    end
  end
end
