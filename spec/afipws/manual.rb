$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

ws = Afipws::WSFE.new :env => :dev, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 
# p ws.tipos_monedas
# p ws.cotizacion 'DOL'

p ws.ultimo_comprobante_autorizado :pto_vta => 1, :cbte_tipo => 1

xml = Builder::XmlMarkup.new indent: 2
xml.ar :Auth do
  xml.ar :Token, ws.ta[:token]
  xml.ar :Sign, ws.ta[:sign]
  xml.ar :Cuit, ws.cuit
end
puts xml.target!