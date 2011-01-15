$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

Savon.configure { |config| config.log = true }

ws = Afipws::WSFE.new :env => :dev, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 

ws.auth

xml = Builder::XmlMarkup.new indent: 2
xml.ar :Auth do
  xml.ar :Token, ws.ta[:token]
  xml.ar :Sign, ws.ta[:sign]
  xml.ar :Cuit, ws.cuit
end
puts xml.target!
