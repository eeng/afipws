# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSAA do
  context "generación documento tra" do
    it "debería generar xml" do
      Time.stubs(:now).returns Time.local(2001, 12, 31, 12, 00)
      xml = subject.generar_tra 'wsfe', 2400
      xml.should match_xpath "/loginTicketRequest/header/uniqueId", Time.now.to_i.to_s
      xml.should match_xpath "/loginTicketRequest/header/generationTime", "2001-12-31T12:00:00-03:00"
      xml.should match_xpath "/loginTicketRequest/header/expirationTime", "2001-12-31T12:40:00-03:00"
      xml.should match_xpath "/loginTicketRequest/service", "wsfe"
    end
  end
  
  context "firmado del tra" do
    it "debería firmar el tra usando el certificado y la clave privada" do
      key = File.read(File.dirname(__FILE__) + '/vitolen-dev.key')
      crt = File.read(File.dirname(__FILE__) + '/vitolen-dev.crt')
      tra = subject.generar_tra 'wsfe', 2400
      subject.firmar_tra(tra, key, crt).to_s.should =~ /BEGIN PKCS7/
    end
  end
  
  context "codificación del tra" do
    it "debería quitarle el header y footer" do
      subject.codificar_tra(OpenSSL::PKCS7.new).should == "MAMGAQA=\n"
    end
  end
  
  context "login" do
    it "debería mandar el TRA al WS y obtener el TA" do
      key, crt, tra = 'key', 'cert', 'tra'
      subject.expects(:tra).with(key, crt, 'wsfe', 2400).returns(tra)
      savon.expects(:login_cms).with(:in0 => tra).returns(:success)
      token, sign = subject.login key, crt
      token.should == 'PD94='
      sign.should == 'i9xDN='
    end
    
    it "debería burbugear SOAP Faults" do
      subject.stubs(:tra).returns('')
      savon.raises_soap_fault
      expect { subject.login '', '' }.to raise_error Savon::SOAP::Fault
    end
  end
end
