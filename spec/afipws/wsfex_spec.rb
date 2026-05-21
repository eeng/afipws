require 'spec_helper'

module Afipws
  describe WSFEX do
    let(:ta) { {token: 't', sign: 's'} }
    let(:ws) { WSFEX.new(cuit: '1').tap { |service| service.wsaa.stubs auth: ta } }

    context 'métodos de negocio' do
      it 'ultimo_comprobante_autorizado' do
        savon.expects(:fex_get_last_cmp).with(message: has_path(
          '//Auth/Token' => 't',
          '//Auth/Pto_venta' => 3,
          '//Auth/Cbte_Tipo' => 19
        )).returns(fixture('wsfex/fex_get_last_cmp/success'))

        ws.ultimo_comprobante_autorizado(pto_vta: 3, cbte_tipo: 19).should == {
          cbte_nro: 20,
          cbte_fecha: Date.new(2026, 4, 10)
        }
      end

      it 'autorizar_comprobantes' do
        savon.expects(:fex_authorize).with(message: has_path(
          '//Auth/Token' => 't',
          '//Cmp/Id' => 44,
          '//Cmp/Cbte_Tipo' => 19,
          '//Cmp/Punto_vta' => 3,
          '//Cmp/Cbte_nro' => 44,
          '//Cmp/Fecha_cbte' => '20260414',
          '//Cmp/Tipo_expo' => 2,
          '//Cmp/Dst_cmp' => 200,
          '//Cmp/Cliente' => 'Cliente del exterior',
          '//Cmp/Cuit_pais_cliente' => 55_555_555_555,
          '//Cmp/Domicilio_cliente' => 'Rua Falsa 123',
          '//Cmp/Moneda_Id' => 'DOL',
          '//Cmp/Moneda_ctz' => 1,
          '//Cmp/Imp_total' => 121,
          '//Cmp/Forma_pago' => 'Transferencia',
          '//Cmp/Idioma_cbte' => 1,
          '//Cmp/Fecha_pago' => '20260420',
          '//Cmp/Items/Item[1]/Pro_ds' => 'Servicio mensual',
          '//Cmp/Items/Item[1]/Pro_qty' => 1,
          '//Cmp/Items/Item[1]/Pro_umed' => 7,
          '//Cmp/Items/Item[1]/Pro_precio_uni' => 121,
          '//Cmp/Items/Item[1]/Pro_total_item' => 121
        )).returns(fixture('wsfex/fex_authorize/autorizacion_1_cbte'))

        ws.autorizar_comprobantes(
          pto_vta: 3,
          cbte_tipo: 19,
          comprobantes: [{
            id: 44,
            cbte_nro: 44,
            fecha_cbte: Date.new(2026, 4, 14),
            tipo_expo: 2,
            dst_cmp: 200,
            cliente: 'Cliente del exterior',
            cuit_pais_cliente: 55_555_555_555,
            domicilio_cliente: 'Rua Falsa 123',
            moneda_id: 'DOL',
            moneda_ctz: 1,
            imp_total: 121,
            forma_pago: 'Transferencia',
            idioma_cbte: 1,
            fecha_pago: Date.new(2026, 4, 20),
            items: [{ pro_ds: 'Servicio mensual', pro_qty: 1, pro_umed: 7, pro_precio_uni: 121, pro_total_item: 121 }]
          }]
        ).should == [
          {
            resultado: 'A',
            cae: '12345678901234',
            cae_fch_vto: Date.new(2026, 5, 1),
            cbte_nro: 44,
            reproceso: false,
            observaciones: nil,
            errores: [],
            eventos: []
          }
        ]
      end

      it 'autorizar_comprobantes con observaciones' do
        savon.expects(:fex_authorize).with(message: :any).returns(fixture('wsfex/fex_authorize/una_observacion'))

        ws.autorizar_comprobantes(
          cbte_tipo: 19,
          pto_vta: 3,
          comprobantes: [{
            id: 45,
            cbte_nro: 45,
            cbte_fch: Date.new(2026, 4, 14),
            tipo_expo: 2,
            dst_cmp: 200,
            cliente: 'Cliente del exterior',
            id_impositivo: 'X123456',
            domicilio_cliente: 'Rua Falsa 123',
            moneda_id: 'DOL',
            moneda_ctz: 1,
            imp_total: 0,
            forma_pago: 'Transferencia',
            idioma_cbte: 1,
            fecha_pago: Date.new(2026, 4, 20),
            items: [{ pro_ds: 'Servicio mensual', pro_qty: 1, pro_umed: 7, pro_precio_uni: 0, pro_total_item: 0 }]
          }]
        ).should == [
          {
            resultado: 'R',
            cae: nil,
            cae_fch_vto: nil,
            cbte_nro: 45,
            reproceso: false,
            observaciones: 'Observacion',
            errores: [],
            eventos: [{ code: 2001, msg: 'Evento programado' }]
          }
        ]
      end

      it 'autorizar_comprobantes con error devuelve el error sin levantar excepción' do
        savon.expects(:fex_authorize).with(message: :any).returns(fixture('wsfex/fex_authorize/con_error'))

        ws.autorizar_comprobantes(
          cbte_tipo: 19,
          pto_vta: 3,
          comprobantes: [{
            id: 46,
            cbte_nro: 46,
            fecha_cbte: Date.new(2026, 4, 14),
            tipo_expo: 2,
            dst_cmp: 200,
            cliente: 'Cliente del exterior',
            cuit_pais_cliente: 55_555_555_555,
            domicilio_cliente: 'Rua Falsa 123',
            moneda_id: 'DOL',
            moneda_ctz: 1,
            imp_total: 121,
            forma_pago: 'Transferencia',
            idioma_cbte: 1,
            fecha_pago: Date.new(2026, 4, 20),
            items: [{ pro_ds: 'Servicio mensual', pro_qty: 1, pro_umed: 7, pro_precio_uni: 121, pro_total_item: 121 }]
          }]
        ).should == [
          {
            resultado: 'R',
            cae: nil,
            cae_fch_vto: nil,
            cbte_nro: 46,
            reproceso: false,
            observaciones: nil,
            errores: [{ code: 1570, msg: 'Cuit_pais_cliente invalido' }],
            eventos: []
          }
        ]
      end

      it 'valida campos obligatorios del comprobante' do
        -> { ws.autorizar_comprobantes(cbte_tipo: 19, pto_vta: 3, comprobantes: [{ cbte_nro: 44 }]) }.should raise_error(
          ArgumentError,
          /faltan campos obligatorios para WSFEX/
        )
      end

      it 'requiere fecha_pago para facturas de servicios' do
        -> do
          ws.autorizar_comprobantes(
            cbte_tipo: 19,
            pto_vta: 3,
            comprobantes: [{
              id: 47,
              cbte_nro: 47,
              fecha_cbte: Date.new(2026, 4, 14),
              tipo_expo: 2,
              dst_cmp: 200,
              cliente: 'Cliente del exterior',
              id_impositivo: 'X123456',
              domicilio_cliente: 'Rua Falsa 123',
              moneda_id: 'DOL',
              moneda_ctz: 1,
              imp_total: 121,
              forma_pago: 'Transferencia',
              idioma_cbte: 1,
              items: [{ pro_ds: 'Servicio mensual', pro_umed: 7, pro_qty: 1, pro_precio_uni: 121, pro_total_item: 121 }]
            }]
          )
        end.should raise_error(ArgumentError, /fecha_pago/)
      end

      it 'rechaza más de un cmps_asoc cuando no son todos remitos 88, 89, 91, 993 o 994' do
        -> do
          ws.autorizar_comprobantes(
            cbte_tipo: 20,
            pto_vta: 3,
            comprobantes: [{
              id: 49,
              cbte_nro: 49,
              fecha_cbte: Date.new(2026, 4, 14),
              tipo_expo: 1,
              dst_cmp: 200,
              cliente: 'Cliente del exterior',
              id_impositivo: 'X123456',
              domicilio_cliente: 'Rua Falsa 123',
              moneda_id: 'DOL',
              moneda_ctz: 1,
              imp_total: 121,
              forma_pago: 'Transferencia',
              idioma_cbte: 1,
              cmps_asoc: [
                { cbte_tipo: 19, cbte_punto_vta: 3, cbte_nro: 1 },
                { cbte_tipo: 19, cbte_punto_vta: 3, cbte_nro: 2 }
              ],
              items: [{ pro_ds: 'Producto', pro_umed: 7, pro_qty: 1, pro_precio_uni: 121, pro_total_item: 121 }]
            }]
          )
        end.should raise_error(ArgumentError, /más de un cmps_asoc/)
      end

      it 'rechaza pro_qty distinto de 0 cuando pro_umed es 0, 97 o 99' do
        -> do
          ws.autorizar_comprobantes(
            cbte_tipo: 19,
            pto_vta: 3,
            comprobantes: [{
              id: 50,
              cbte_nro: 50,
              fecha_cbte: Date.new(2026, 4, 14),
              tipo_expo: 2,
              dst_cmp: 200,
              cliente: 'Cliente del exterior',
              id_impositivo: 'X123456',
              domicilio_cliente: 'Rua Falsa 123',
              moneda_id: 'DOL',
              moneda_ctz: 1,
              imp_total: 121,
              forma_pago: 'Transferencia',
              idioma_cbte: 1,
              fecha_pago: Date.new(2026, 4, 20),
              items: [{ pro_ds: 'Servicio', pro_umed: 99, pro_qty: 5, pro_precio_uni: 0, pro_total_item: 121 }]
            }]
          )
        end.should raise_error(ArgumentError, /pro_qty igual a 0 o no informado/)
      end

      it 'requiere permiso_existente para facturas de productos' do
        -> do
          ws.autorizar_comprobantes(
            cbte_tipo: 19,
            pto_vta: 3,
            comprobantes: [{
              id: 48,
              cbte_nro: 48,
              fecha_cbte: Date.new(2026, 4, 14),
              tipo_expo: 1,
              dst_cmp: 200,
              cliente: 'Cliente del exterior',
              id_impositivo: 'X123456',
              domicilio_cliente: 'Rua Falsa 123',
              moneda_id: 'DOL',
              moneda_ctz: 1,
              imp_total: 121,
              forma_pago: 'Transferencia',
              incoterms: 'FOB',
              idioma_cbte: 1,
              items: [{ pro_ds: 'Producto', pro_umed: 7, pro_qty: 1, pro_precio_uni: 121, pro_total_item: 121 }]
            }]
          )
        end.should raise_error(ArgumentError, /permiso_existente/)
      end
    end
  end
end
