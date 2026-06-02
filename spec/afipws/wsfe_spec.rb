require 'spec_helper'

module Afipws
  describe WSFE do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { WSFE.new(cuit: '1').tap { |ws| ws.wsaa.stubs auth: ta } }
    let(:auth) { {auth: ta.merge(cuit: '1')} }

    context 'métodos de negocio' do
      it 'dummy' do
        savon.expects(:fe_dummy).returns(fixture('wsfe/fe_dummy/success'))
        ws.dummy.should == { app_server: 'OK', db_server: 'OK', auth_server: 'OK' }
      end

      it 'tipos_comprobantes' do
        savon.expects(:fe_param_get_tipos_cbte).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_cbte/success'))
        ws.tipos_comprobantes.should == [
          { id: 1, desc: 'Factura A', fch_desde: Date.new(2010, 9, 17), fch_hasta: nil },
          { id: 2, desc: 'Nota de Débito A', fch_desde: Date.new(2010, 9, 18), fch_hasta: Date.new(2011, 9, 18) }
        ]
      end

      it 'tipos_documentos' do
        savon.expects(:fe_param_get_tipos_doc).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_doc/success'))
        ws.tipos_documentos.should == [{ id: 80, desc: 'CUIT', fch_desde: Date.new(2008, 7, 25), fch_hasta: nil }]
      end

      it 'tipos_concepto' do
        savon.expects(:fe_param_get_tipos_concepto).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_concepto/success'))
        ws.tipos_concepto.should == [{ id: 1, desc: 'Producto', fch_desde: Date.new(2008, 7, 25), fch_hasta: nil }]
      end

      it 'tipos_monedas' do
        savon.expects(:fe_param_get_tipos_monedas).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_monedas/success'))
        ws.tipos_monedas.should == [
          { id: 'PES', desc: 'Pesos Argentinos', fch_desde: Date.new(2009, 4, 3), fch_hasta: nil },
          { id: '002', desc: 'Dólar Libre EEUU', fch_desde: Date.new(2009, 4, 16), fch_hasta: nil }
        ]
      end

      it 'tipos_opcional' do
        savon.expects(:fe_param_get_tipos_opcional).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_opcional/success'))
        ws.tipos_opcional.should == []
      end

      it 'tipos_iva' do
        savon.expects(:fe_param_get_tipos_iva).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_iva/success'))
        ws.tipos_iva.should == [{ id: 5, desc: '21%', fch_desde: Date.new(2009, 2, 20), fch_hasta: nil }]
      end

      it 'tipos_tributos' do
        savon.expects(:fe_param_get_tipos_tributos).with(message: auth).returns(fixture('wsfe/fe_param_get_tipos_tributos/success'))
        ws.tipos_tributos.should == [{ id: 2, desc: 'Impuestos provinciales', fch_desde: Date.new(2010, 9, 17), fch_hasta: nil }]
      end

      it 'puntos_venta' do
        savon.expects(:fe_param_get_ptos_venta).with(message: auth).returns(fixture('wsfe/fe_param_get_ptos_venta/success'))
        ws.puntos_venta.should == [
          { nro: 1, emision_tipo: 'CAE', bloqueado: false, fch_baja: nil },
          { nro: 2, emision_tipo: 'CAEA', bloqueado: true, fch_baja: Date.new(2011, 1, 31) }
        ]
      end

      context 'cotizacion' do
        it 'cuando la moneda solicitada existe' do
          savon.expects(:fe_param_get_cotizacion).with(message: auth.merge(mon_id: 'DOL')).returns(fixture('wsfe/fe_param_get_cotizacion/dolar'))
          ws.cotizacion('DOL').should == 3.976
        end

        it 'cuando la moneda no existe' do
          savon.expects(:fe_param_get_cotizacion).with(message: auth.merge(mon_id: 'PES')).returns(fixture('wsfe/fe_param_get_cotizacion/inexistente'))
          -> { ws.cotizacion('PES') }.should raise_error { |error|
            error.should be_a ResponseError
            error.message.should match /602: Sin Resultados/
            error.code?(602).should be true
            error.code?(603).should be false
          }
        end
      end

      it 'cant_max_registros_x_lote' do
        savon.expects(:fe_comp_tot_x_request).with(message: auth).returns(fixture('wsfe/fe_comp_tot_x_request/success'))
        ws.cant_max_registros_x_lote.should == 250
      end

      context 'autorizar_comprobante' do
        it 'debería devolver un hash con el CAE y su fecha de vencimiento' do
          savon.expects(:fecae_solicitar).with(message: has_path(
            '//Auth/Token' => 't',
            '//FeCAEReq/FeCabReq/CantReg' => 1,
            '//FeCAEReq/FeCabReq/PtoVta' => 2,
            '//FeCAEReq/FeCabReq/CbteTipo' => 1,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/DocTipo' => 80,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/DocNro' => 30_521_189_203,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/CbteFch' => 20_110_113,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/ImpTotal' => 1270.48,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/ImpIVA' => 220.5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[1]/Id' => 5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[1]/Importe' => 220.5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Tributos/Tributo[1]/Id' => 0,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Tributos/Tributo[1]/BaseImp' => 150,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Tributos/Tributo[1]/Alic' => 5.2,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Tributos/Tributo[1]/Importe' => 7.8
          )).returns(fixture('wsfe/fecae_solicitar/autorizacion_1_cbte'))
          rta = ws.autorizar_comprobantes(cbte_tipo: 1, pto_vta: 2, comprobantes: [
            {
              cbte_nro: 1, concepto: 1, doc_nro: 30_521_189_203, doc_tipo: 80, cbte_fch: Date.new(2011, 0o1, 13),
              imp_total: 1270.48, imp_neto: 1049.98, imp_iva: 220.50, mon_id: 'PES', mon_cotiz: 1,
              iva: { alic_iva: [{ id: 5, base_imp: 1049.98, importe: 220.50 }]},
              tributos: { tributo: [{ id: 0, base_imp: 150, alic: 5.2, importe: 7.8 }] }
            }
          ])
          rta[0].should include(
            cae: '61023008595705', cae_fch_vto: Date.new(2011, 0o1, 23), cbte_nro: 1,
            resultado: 'A', observaciones: []
          )
          rta.size.should == 1
        end

        it 'con varias alicuotas iva' do
          savon.expects(:fecae_solicitar).with(message: has_path(
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[1]/Id' => 5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[1]/Importe' => 21,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[2]/Id' => 4,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/Iva/AlicIva[2]/Importe' => 5.25
          )).returns(fixture('wsfe/fecae_solicitar/autorizacion_1_cbte'))
          ws.autorizar_comprobantes(cbte_tipo: 1, pto_vta: 2, comprobantes: [{iva: {alic_iva: [
            { id: 5, base_imp: 100, importe: 21 },
            { id: 4, base_imp: 50, importe: 5.25 }
          ]}}])
        end

        it 'con varios comprobantes aprobados' do
          savon.expects(:fecae_solicitar).with(message: has_path(
            '//FeCAEReq/FeCabReq/CantReg' => 2,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/CbteDesde' => 5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[1]/CbteHasta' => 5,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[2]/CbteDesde' => 6,
            '//FeCAEReq/FeDetReq/FECAEDetRequest[2]/CbteHasta' => 6
          )).returns(fixture('wsfe/fecae_solicitar/autorizacion_2_cbtes'))
          rta = ws.autorizar_comprobantes(cbte_tipo: 1, pto_vta: 2, comprobantes: [{ cbte_nro: 5 }, { cbte_nro: 6 }])
          rta[0].should include cbte_nro: 5, cae: '61033008894096'
          rta[1].should include cbte_nro: 6, cae: '61033008894101'
        end

        it 'con 2 observaciones' do
          savon.expects(:fecae_solicitar).with(message: :any).returns(fixture('wsfe/fecae_solicitar/dos_observaciones'))
          rta = ws.autorizar_comprobantes comprobantes: []
          rta[0].should include cbte_nro: 3, cae: nil, resultado: 'R', observaciones: [
            {code: 10_048, msg: 'Msg 1'}, {code: 10_018, msg: 'Msg 2'}
          ]
        end

        it 'con 1 observación' do
          savon.expects(:fecae_solicitar).with(message: :any).returns(fixture('wsfe/fecae_solicitar/una_observacion'))
          rta = ws.autorizar_comprobantes comprobantes: []
          rta[0].should include observaciones: [{code: 10_048, msg: 'Msg 1'}]
        end
      end

      context 'solicitar_caea' do
        it 'debería mandar automáticamente el período y orden' do
          Date.stubs today: Date.new(2011, 1, 27)
          savon.expects(:fecaea_solicitar).with(message: has_path('//Periodo' => '201102', '//Orden' => 1)).returns(fixture('wsfe/fecaea_solicitar/success'))
          ws.solicitar_caea.should include(
            caea: '21043476341977', fch_tope_inf: Date.new(2011, 0o3, 17),
            fch_vig_desde: Date.new(2011, 0o2, 0o1), fch_vig_hasta: Date.new(2011, 0o2, 15)
          )
        end

        context 'periodo_para_solicitud_caea' do
          it 'cuando estoy en la primer quincena' do
            Date.stubs today: Date.new(2011, 1, 12)
            ws.periodo_para_solicitud_caea.should == { periodo: '201101', orden: 2 }
            Date.stubs today: Date.new(2011, 1, 15)
            ws.periodo_para_solicitud_caea.should == { periodo: '201101', orden: 2 }
          end

          it 'cuando estoy en la segunda quincena' do
            Date.stubs today: Date.new(2011, 1, 16)
            ws.periodo_para_solicitud_caea.should == { periodo: '201102', orden: 1 }
            Date.stubs today: Date.new(2011, 1, 31)
            ws.periodo_para_solicitud_caea.should == { periodo: '201102', orden: 1 }
          end
        end

        it 'cuando el caea ya fue otorgado debería consultarlo y devolverlo' do
          Date.stubs today: Date.new(2011, 1, 27)
          savon.expects(:fecaea_solicitar)
            .with(message: has_path('//Periodo' => '201102', '//Orden' => 1))
            .returns(fixture('wsfe/fecaea_solicitar/caea_ya_otorgado'))
          savon.expects(:fecaea_consultar)
            .with(message: has_path('//Periodo' => '201102', '//Orden' => 1))
            .returns(fixture('wsfe/fecaea_consultar/success'))
          ws.solicitar_caea.should include caea: '21043476341977', fch_vig_desde: Date.new(2011, 0o2, 0o1)
        end

        it 'cuando encapsular errores' do
          savon.expects(:fecaea_solicitar).with(message: :any).returns(fixture('wsfe/fecaea_solicitar/error_distinto'))
          -> { ws.solicitar_caea }.should raise_error ResponseError, /15007/
        end
      end

      it 'informar_comprobantes_caea' do
        savon.expects(:fecaea_reg_informativo).with(message: has_path(
          '//Auth/Token' => 't',
          '//FeCAEARegInfReq/FeCabReq/CantReg' => 2,
          '//FeCAEARegInfReq/FeCabReq/PtoVta' => 3,
          '//FeCAEARegInfReq/FeCabReq/CbteTipo' => 1,
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[1]/CbteDesde' => 1,
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[1]/CbteHasta' => 1,
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[1]/CAEA' => '21043476341977',
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[2]/CbteDesde' => 2,
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[2]/CbteHasta' => 2,
          '//FeCAEARegInfReq/FeDetReq/FECAEADetRequest[2]/CAEA' => '21043476341977'
        )).returns(fixture('wsfe/fecaea_reg_informativo/informe_rtdo_parcial'))
        rta = ws.informar_comprobantes_caea(cbte_tipo: 1, pto_vta: 3, comprobantes: [
          { cbte_nro: 1, caea: '21043476341977' }, { cbte_nro: 2, caea: '21043476341977' }
        ])
        rta[0].should include cbte_nro: 1, caea: '21043476341977', resultado: 'A', observaciones: []
        rta[1].should include cbte_nro: 2, caea: '21043476341977', resultado: 'R', observaciones: [{code: 724, msg: 'Msg'}]
      end

      it 'informar_caea_sin_movimientos' do
        savon.expects(:fecaea_sin_movimiento_informar).with(message: has_path(
          '//Auth/Token' => 't',
          '//PtoVta' => 4,
          '//CAEA' => '21043476341977'
        )).returns(fixture('wsfe/fecaea_sin_movimiento_informar/success'))
        rta = ws.informar_caea_sin_movimientos('21043476341977', 4)
        rta.should include caea: '21043476341977', resultado: 'A'
      end

      context 'consultar_caea' do
        it 'consultar_caea' do
          savon.expects(:fecaea_consultar).with(message: has_path('//Periodo' => '201101', '//Orden' => 1)).returns(fixture('wsfe/fecaea_consultar/success'))
          ws.consultar_caea(Date.new(2011, 1, 1)).should include caea: '21043476341977', fch_tope_inf: Date.new(2011, 0o3, 17)
        end
      end

      it 'ultimo_comprobante_autorizado' do
        savon.expects(:fe_comp_ultimo_autorizado).with(message: has_path('//PtoVta' => 1, '//CbteTipo' => 1)).returns(fixture('wsfe/fe_comp_ultimo_autorizado/success'))
        ws.ultimo_comprobante_autorizado(pto_vta: 1, cbte_tipo: 1).should == 20
      end

      it 'consultar_comprobante' do
        savon.expects(:fe_comp_consultar).with(message: has_path(
          '//Auth/Token' => 't', '//FeCompConsReq/PtoVta' => 1, '//FeCompConsReq/CbteTipo' => 2, '//FeCompConsReq/CbteNro' => 3
        )).returns(fixture('wsfe/fe_comp_consultar/success'))
        rta = ws.consultar_comprobante(pto_vta: 1, cbte_tipo: 2, cbte_nro: 3)
        rta[:cod_autorizacion].should == '61023008595705'
        rta[:emision_tipo].should == 'CAE'
      end
    end

    context 'autenticacion' do
      before { FileUtils.rm_rf Dir.glob('tmp/*-test-*-ta.dump') }

      it 'debería autenticarse usando el WSAA' do
        wsfe = WSFE.new cuit: '1', cert: 'cert', key: 'key'
        wsfe.wsaa.cert.should == 'cert'
        wsfe.wsaa.key.should == 'key'
        wsfe.wsaa.service.should == 'wsfe'
        wsfe.wsaa.expects(:login).returns(token: 't', sign: 's')
        savon.expects(:fe_param_get_tipos_cbte).with(message: has_path(
          '//Auth/Token' => 't', '//Auth/Sign' => 's', '//Auth/Cuit' => '1'
        )).returns(fixture('wsfe/fe_param_get_tipos_cbte/success'))
        wsfe.tipos_comprobantes
      end
    end

    context 'entorno' do
      it 'debería usar las url para development cuando el env es development' do
        Client.expects(:new).with(wsdl: 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl')
        Client.expects(:new).with(wsdl: 'https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL', convert_request_keys_to: :camelcase)
        WSFE.new env: :development
      end

      it 'debería usar las url para production cuando el env es production' do
        Client.expects(:new).with(wsdl: 'https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl')
        Client.expects(:new).with(wsdl: 'https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL', convert_request_keys_to: :camelcase)
        WSFE.new env: 'production'
      end
    end

    context 'manejo de errores' do
      it 'cuando hay un error' do
        savon.expects(:fe_param_get_tipos_cbte).with(message: :any).returns(fixture('wsfe/fe_param_get_tipos_cbte/failure_1_error'))
        -> { ws.tipos_comprobantes }.should raise_error { |e|
          e.should be_a ResponseError
          e.errors.should == [{ code: '600', msg: 'No se corresponden token con firma' }]
          e.message.should == '600: No se corresponden token con firma'
        }
      end

      it 'cuando hay varios errores' do
        savon.expects(:fe_param_get_tipos_cbte).with(message: :any).returns(fixture('wsfe/fe_param_get_tipos_cbte/failure_2_errors'))
        -> { ws.tipos_comprobantes }.should raise_error { |e|
          e.should be_a ResponseError
          e.errors.should == [
            { code: '600', msg: 'No se corresponden token con firma' },
            { code: '601', msg: 'CUIT representada no incluida en token' }
          ]
          e.message.should == '600: No se corresponden token con firma; 601: CUIT representada no incluida en token'
        }
      end
    end

    context 'cálculo de fechas y períodos' do
      it 'periodo_para_consulta_caea' do
        ws.periodo_para_consulta_caea(Date.new(2011, 1, 1)).should == { periodo: '201101', orden: 1 }
        ws.periodo_para_consulta_caea(Date.new(2011, 1, 15)).should == { periodo: '201101', orden: 1 }
        ws.periodo_para_consulta_caea(Date.new(2011, 1, 16)).should == { periodo: '201101', orden: 2 }
        ws.periodo_para_consulta_caea(Date.new(2011, 1, 31)).should == { periodo: '201101', orden: 2 }
        ws.periodo_para_consulta_caea(Date.new(2011, 2, 2)).should == { periodo: '201102', orden: 1 }
      end

      it 'fecha_inicio_quincena_siguiente' do
        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 1)).should == Date.new(2010, 1, 16)
        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 10)).should == Date.new(2010, 1, 16)
        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 15)).should == Date.new(2010, 1, 16)

        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 16)).should == Date.new(2010, 2, 1)
        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 20)).should == Date.new(2010, 2, 1)
        fecha_inicio_quincena_siguiente(Date.new(2010, 1, 31)).should == Date.new(2010, 2, 1)
        fecha_inicio_quincena_siguiente(Date.new(2010, 12, 31)).should == Date.new(2011, 1, 1)
      end

      def fecha_inicio_quincena_siguiente fecha
        Date.stubs(today: fecha)
        subject.fecha_inicio_quincena_siguiente
      end
    end

    context 'comprobante_to_request' do
      def c2r comprobante, opciones
        subject.comprobante_to_request comprobante, opciones
      end

      it 'no debería enviar tag tributos si el impTrib es 0' do
        c2r({imp_trib: 0.0, tributos: { tributo: [] }},{}).should_not have_key :tributos
      end
    end
  end
end
