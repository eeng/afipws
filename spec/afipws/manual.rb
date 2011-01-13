$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

ws = Afipws::WSFE.new :env => :dev, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 
# p ws.tipos_monedas
# p ws.cotizacion 'DOL'
p ws.ultimo_comprobante_autorizado :pto_vta => 10, :cbte_tipo => 1