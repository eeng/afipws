# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSAA do
  context "generación documento tra" do
    it "debería generar xml" do
      Time.stub(:now) { Time.local(2001, 12, 31, 12, 00) }
      xml = subject.generar_tra
      xml.should match_xpath "/loginTicketRequest/header/uniqueId", Time.now.to_i.to_s
      xml.should match_xpath "/loginTicketRequest/header/generationTime", "2001-12-31T12:00:00-0300"
      xml.should match_xpath "/loginTicketRequest/header/expirationTime", "2001-12-31T12:40:00-0300"
      xml.should match_xpath "/loginTicketRequest/header/destination", "cn=wsaa,o=afip,c=ar,serialNumber=CUIT 33693450239"
      xml.should match_xpath "/loginTicketRequest/header/source", "cn=VitolenDev,o=Nicolau Emmanuel,c=ar,serialNumber=CUIT 20300032673"
      xml.should match_xpath "/loginTicketRequest/service", "wsfe"
    end
  end
  
  
end
