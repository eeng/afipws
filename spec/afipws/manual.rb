$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

ws = Afipws::WSFE.new :env => :dev, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 
# p ws.tipos_monedas
# p ws.cotizacion 'DOL'

# p ws.ultimo_comprobante_autorizado :pto_vta => 1, :cbte_tipo => 1
# 
# xml = Builder::XmlMarkup.new indent: 2
# xml.ar :Auth do
#   xml.ar :Token, ws.ta[:token]
#   xml.ar :Sign, ws.ta[:sign]
#   xml.ar :Cuit, ws.cuit
# end
# puts xml.target!

Savon.configure { |config| config.log = true }
rta = ws.autorizar_comprobante(:cant_reg => 1, :cbte_tipo => 1, :pto_vta => 1, :concepto => 1, :doc_nro => 30521189203, :doc_tipo => 80, :cbte_desde => 2, :cbte_hasta => 2, :cbte_fch => Date.new(2011,01,13), :imp_total => 1270.48, :imp_neto => 1049.98, :imp_iva => 220.50, :imp_tot_conc => 0, :imp_op_ex => 0, :imp_trib => 0, :mon_id => 'PES', :mon_cotiz => 1, :iva => [{ :alic_iva => { :id => 5, :base_imp => 1049.98, :importe => 220.50 }}])
