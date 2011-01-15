$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

Savon.configure { |config| config.log = true }

ws = Afipws::WSFE.new :env => :dev, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 

ultimo = ws.ultimo_comprobante_autorizado :pto_vta => 1, :cbte_tipo => 1
puts ws.autorizar_comprobantes(:cbte_tipo => 1, :pto_vta => 1, :comprobantes => [
  { 
    :cbte_nro => ultimo + 1, :concepto => 1, :doc_nro => 30521189203, :doc_tipo => 80, :cbte_fch => Date.new(2011,01,13), 
    :imp_total => 1270.48, :imp_neto => 1049.98, :imp_iva => 220.50, :mon_id => 'PES', :mon_cotiz => 1,
    :iva => { :alic_iva => [{ :id => 5, :base_imp => 1049.98, :importe => 220.50 }]}
  },
  { 
    :cbte_nro => ultimo + 2, :concepto => 1, :doc_nro => 30521189203, :doc_tipo => 80, :cbte_fch => Date.new(2011,01,13), 
    :imp_total => 1270.48, :imp_neto => 1049.98, :imp_iva => 220.50, :mon_id => 'PES', :mon_cotiz => 1,
    :iva => { :alic_iva => [{ :id => 5, :base_imp => 1049.98, :importe => 220.60 }]}
  }
])
