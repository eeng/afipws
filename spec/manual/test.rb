$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'afipws'

Savon.configure { |config| config.log = true }

ws = Afipws::WSFE.new :env => :development, :cuit => '20300032673', 
  :cert => File.read(File.dirname(__FILE__) + '/test.crt'), 
  :key => File.read(File.dirname(__FILE__) + '/test.key') 

def obtener_ta ws
  ws.cotizacion 'DOL'
  xml = Builder::XmlMarkup.new indent: 2
  xml.ar :Auth do
    xml.ar :Token, ws.ta[:token]
    xml.ar :Sign, ws.ta[:sign]
    xml.ar :Cuit, ws.cuit
  end
  puts xml.target!
end

def autorizar_comprobante ws
  ultimo = ws.ultimo_comprobante_autorizado :pto_vta => 1, :cbte_tipo => 1
  # cant_informar = ws.cant_max_registros_x_request
  cant_informar = 2
  puts "Informando #{cant_informar} comprobantes"
  comprobantes = (1..cant_informar).to_a.map do |i|
    { 
      :cbte_nro => ultimo + i, :concepto => 1, :doc_nro => 30521189203, :doc_tipo => 80, :cbte_fch => Date.today, 
      :imp_total => 1270.48, :imp_neto => 1049.98, :imp_iva => 220.50, :mon_id => 'PES', :mon_cotiz => 1,
      :iva => { :alic_iva => [{ :id => 5, :base_imp => 1049.98, :importe => 220.50 }]}
    }
  end
  puts ws.autorizar_comprobantes(:cbte_tipo => 1, :pto_vta => 1, :comprobantes => comprobantes)
end

def consultar_caea ws
  ws.consultar_caea Date.new(2011,2,3)
end

def soap_actions ws
  ws.client.soap_actions
end

p ws.tipos_comprobantes