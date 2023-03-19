require 'spec_helper'

module Afipws
  describe Client do
    context 'manejo de errores' do
      subject { Client.new(wsdl: Afipws::WSFE::WSDL[:test]) }

      it 'Savon::SOAPFault se encapsulan en ServerError' do
        savon.expects(:fe_dummy).returns(fixture('wsaa/login_cms/fault'))
        -> { subject.request :fe_dummy }.should raise_error ServerError, /CMS no es valido/
      end

      it 'HTTPClient::TimeoutError se encapsulan en NetworkError y no es retriable' do
        expect_savon_to_raise HTTPClient::ReceiveTimeoutError, 'execution expired'
        -> { subject.request :fe_dummy }.should raise_error { |error|
          error.should be_a NetworkError
          error.message.should match /execution expired/
          error.retriable?.should be false
        }
      end

      it 'HTTPClient::ConnectTimeoutError se encapsulan en NetworkError y es retriable' do
        expect_savon_to_raise HTTPClient::ConnectTimeoutError, 'execution expired'
        -> { subject.request :fe_dummy }.should raise_error { |error|
          error.should be_a NetworkError
          error.message.should match /execution expired/
          error.retriable?.should be true
        }
      end

      def expect_savon_to_raise error_class, message
        # Hack to mock exceptions on Savon
        subject.instance_eval('@savon', __FILE__, __LINE__).expects(:call).raises(error_class, message)
      end
    end
  end
end
