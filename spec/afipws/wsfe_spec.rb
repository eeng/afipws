# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Afipws::WSFE do
  let :ws do 
    wsaa = stub :login => { :token => 't', :sign => 's' }
    Afipws::WSFE.new :cuit => '1', :wsaa => wsaa
  end
  
  context "Métodos de negocio" do
    it "dummy" do
      savon.expects('FEDummy').returns(:success)
      ws.dummy.should == { :app_server => "OK", :db_server => "OK", :auth_server => "OK" }
    end

    it "tipos_comprobantes" do
      savon.expects('FEParamGetTiposCbte').returns(:success)
      ws.tipos_comprobantes.should == [
        { :id => 1, :desc => "Factura A", :fch_desde => Date.new(2010,9,17), :fch_hasta => nil }, 
        { :id => 2, :desc => "Nota de Débito A", :fch_desde => Date.new(2010,9,18), :fch_hasta => Date.new(2011,9,18) }]
    end
    
    it "tipos_documentos" do
      savon.expects('FEParamGetTiposDoc').returns(:success)
      ws.tipos_documentos.should == [{ :id => 80, :desc => "CUIT", :fch_desde => Date.new(2008,7,25), :fch_hasta => nil }]
    end
    
    it "tipos_monedas" do
      savon.expects('FEParamGetTiposMonedas').returns(:success)
      ws.tipos_monedas.should == [
        { :id => 'PES', :desc => "Pesos Argentinos", :fch_desde => Date.new(2009,4,3), :fch_hasta => nil }, 
        { :id => '002', :desc => "Dólar Libre EEUU", :fch_desde => Date.new(2009,4,16), :fch_hasta => nil }]
    end
    
    it "tipos_iva" do
      savon.expects('FEParamGetTiposIva').returns(:success)
      ws.tipos_iva.should == [{ :id => 5, :desc => "21%", :fch_desde => Date.new(2009,2,20), :fch_hasta => nil }] 
    end
    
    context "cotizacion" do
      it "cuando la moneda solicitada existe" do
        savon.expects('FEParamGetCotizacion').with(has_entry 'wsdl:MonId', 'DOL').returns(:dolar)
        ws.cotizacion('DOL').should == { :mon_id => 'DOL', :mon_cotiz => 3.976, :fch_cotiz => Date.new(2011,01,12) }
      end
      
      it "cuando la moneda no existe" do
        savon.expects('FEParamGetCotizacion').with(has_entry 'wsdl:MonId', 'PES').returns(:inexistente)
        expect { ws.cotizacion('PES') }.to raise_error Afipws::WSError, /602: Sin Resultados/
      end
    end
    
    it "autorizar_comprobante" do
      savon.expects('FECAESolicitar').with(has_entries 'wsdl:CantReg' => 1, 'wsdl:PtoVta' => 2, 
        'wsdl:Iva' => [{'wsdl:Alicuota' => {'wsdl:Id' => 5, 'wsdl:BaseImp' => 1049.98, 'wsdl:Importe' => 220.5}}]).returns(:autorizacion_1_cbte)
      rta = ws.autorizar_comprobante(:cant_reg => 1, :cbte_tipo => 1, :pto_vta => 2, :concepto => 1, 
        :doc_nro => 30521189203, :doc_tipo => 80, :cbte_desde => 1, :cbte_hasta => 1, :cbte_fch => '20110113', 
        :imp_total => 1270.48, :imp_neto => 1049.98, :imp_iva => 220.50, :imp_tot_conc => 0, :imp_op_ex => 0, 
        :imp_trib => 0, :mon_id => 'PES', :mon_cotiz => 1,
        :iva => [{ :alicuota => { :id => 5, :base_imp => 1049.98, :importe => 220.50 }}])
      rta[:fe_cab_resp][:fch_proceso].should == Date.new(2011,01,13)
      rta[:fe_cab_resp][:resultado].should == 'A'
      rta[:fe_det_resp][:fecae_det_response][:cbte_desde].should == 1
      rta[:fe_det_resp][:fecae_det_response][:cae].should == '61023008595705'
      rta[:fe_det_resp][:fecae_det_response][:cae_fch_vto].should == Date.new(2011,01,23)
    end    
    
    it "ultimo_comprobante_autorizado" do
      savon.expects('FECompUltimoAutorizado').with(has_entries 'wsdl:PtoVta' => 1, 'wsdl:CbteTipo' => 1).returns(:success)
      ws.ultimo_comprobante_autorizado(:pto_vta => 1, :cbte_tipo => 1).should == 20
    end
  end
  
  context "autenticacion" do
    it "debería autenticarse usando el WSAA" do
      wsfe = Afipws::WSFE.new :cuit => '1', :cert => 'cert', :key => 'key'
      wsfe.wsaa.cert.should == 'cert'
      wsfe.wsaa.key.should == 'key'
      wsfe.wsaa.service.should == 'wsfe'
      wsfe.wsaa.expects(:login).returns({ :token => 't', :sign => 's' })
      savon.expects('FEParamGetTiposCbte').with('wsdl:Auth' => {'wsdl:Token' => 't', 'wsdl:Sign' => 's', 'wsdl:Cuit' => '1'}).returns(:success)
      wsfe.tipos_comprobantes
    end
  end
  
  context "manejo de errores" do
    it "cuando hay un error" do
      savon.expects('FEParamGetTiposCbte').returns(:failure_1_error)
      expect { ws.tipos_comprobantes }.to raise_error { |e| 
        e.should be_a Afipws::WSError
        e.errors.should == [{ :code => "600", :msg => "No se corresponden token con firma" }] 
        e.message.should == "600: No se corresponden token con firma" 
      }
    end

    it "cuando hay varios errores" do
      savon.expects('FEParamGetTiposCbte').returns(:failure_2_errors)
      expect { ws.tipos_comprobantes }.to raise_error { |e| 
        e.should be_a Afipws::WSError
        e.errors.should == [{ :code => "600", :msg => "No se corresponden token con firma" }, { :code => "601", :msg => "CUIT representada no incluida en token" }] 
        e.message.should == "600: No se corresponden token con firma; 601: CUIT representada no incluida en token" 
      }
    end
  end
end