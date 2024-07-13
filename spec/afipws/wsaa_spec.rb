require 'spec_helper'

module Afipws
  describe WSAA do
    context 'generación documento tra' do
      it 'debería generar xml' do
        Time.stubs(:now).returns Time.new(2001, 12, 31, 12, 0, 0, '-03:00')
        xml = subject.generar_tra 'wsfe', 2400
        xml.should match_xpath '/loginTicketRequest/header/uniqueId', Time.now.to_i.to_s
        xml.should match_xpath '/loginTicketRequest/header/generationTime', '2001-12-31T11:20:00-03:00'
        xml.should match_xpath '/loginTicketRequest/header/expirationTime', '2001-12-31T12:40:00-03:00'
        xml.should match_xpath '/loginTicketRequest/service', 'wsfe'
      end
    end

    context 'firmado del tra' do
      it 'debería firmar el tra usando el certificado y la clave privada' do
        key = File.read(File.dirname(__FILE__) + '/test.key')
        crt = File.read(File.dirname(__FILE__) + '/test.crt')
        tra = subject.generar_tra 'wsfe', 2400
        subject.firmar_tra(tra, key, crt).to_s.should =~ /BEGIN PKCS7/
      end
    end

    context 'login' do
      it 'debería mandar el TRA al WS y obtener el TA' do
        ws = WSAA.new key: 'key', cert: 'cert'
        ws.expects(:tra).with('key', 'cert', 'wsfe', 2400).returns('tra')
        savon.expects(:login_cms).with(message: {in0: 'tra'}).returns(fixture('wsaa/login_cms/success'))
        ta = ws.login
        ta[:token].should == 'PD94='
        ta[:sign].should == 'i9xDN='
        ta[:generation_time].should == Time.new(2011, 1, 12, 18, 57, 4, '-03:00')
        ta[:expiration_time].should == Time.new(2011, 1, 13, 6, 57, 4, '-03:00')
      end
    end

    context 'auth' do
      before do
        FileUtils.rm_rf Dir.glob('tmp/*-test-*-ta.dump')
        Time.stubs(:now).returns(Time.local(2010, 1, 1))
      end

      it 'debería devolver hash con token y sign' do
        ws = WSAA.new
        ws.expects(:login).once.returns(token: 'token', sign: 'sign', expiration_time: Time.now + 60)
        ws.auth.should == {token: 'token', sign: 'sign'}
      end

      it 'debería cachear TA en la instancia y disco' do
        ws = WSAA.new
        ws.expects(:login).once.returns(ta = {token: 'token', sign: 'sign', expiration_time: Time.now + 60})
        ws.auth
        ws.auth
        ws.ta.should equal ta

        ws = WSAA.new
        ws.auth
        ws.ta.should == ta
      end

      it 'si el TA expiró debería ejecutar solicitar uno nuevo' do
        subject.expects(:login).twice.returns(token: 't1', expiration_time: Time.now - 2).then.returns(token: 't2')
        subject.auth
        subject.ta[:token].should == 't1'
        subject.auth
        subject.ta[:token].should == 't2'
      end
    end
  end
end
