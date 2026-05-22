# Afipws

Ruby client para los web services de la AFIP.

[![Build Status](https://github.com/eeng/afipws/actions/workflows/ci.yml/badge.svg)](https://github.com/eeng/afipws/actions/workflows/ci.yml)

## Servicios Disponibles

- wsaa (WSAA)
- wsfe (WSFE)
- wsfex (WSFEX)
- ws_sr_constancia_inscripcion (WSConstanciaInscripcion)
- ws_sr_padron_a100 (PersonaServiceA100)
- ws_sr_padron_a4 (PersonaServiceA4)
- ws_sr_padron_a5 (PersonaServiceA5)
- wconsdeclaracion (WConsDeclaracion)

## Uso

Primero hay que crear la clave privada y obtener el certificado correspondiente según los pasos indicados [aquí](http://www.afip.gov.ar/ws/WSAA/cert-req-howto.txt).

Luego hay que instalar la librería:

```
gem install afipws
```

Y por último usamos el web service de esta forma:

```ruby
require 'afipws'
ws = Afipws::WSFE.new env: :development, cuit: '...', key: File.read('test.key'), cert: File.read('test.crt')
puts ws.cotizacion 'DOL'
```

Para comprobantes de exportación (`Factura E`) se puede usar `Afipws::WSFEX`. Internamente autentica con `WSAA` usando `service: 'wsfex'`.

```ruby
require 'afipws'

ws = Afipws::WSFEX.new env: :development, cuit: '...', key: File.read('test.key'), cert: File.read('test.crt')
ultimo = ws.ultimo_comprobante_autorizado(pto_vta: 3, cbte_tipo: 19)

rta = ws.autorizar_comprobantes(
  pto_vta: 3,
  cbte_tipo: 19,
  comprobantes: [
    {
      cbte_nro: ultimo + 1,
      fecha_cbte: Date.today,
      tipo_expo: 2,
      permiso_existente: 'N',
      dst_cmp: 200,
      cliente: 'Cliente del exterior',
      cuit_pais_cliente: 55_555_555_555,
      domicilio_cliente: 'Rua Falsa 123',
      moneda_id: 'DOL',
      moneda_ctz: 1,
      imp_total: 121.0,
      idioma_cbte: 1,
      items: [
        { pro_ds: 'Servicio mensual', pro_umed: 7, pro_total_item: 121.0 }
      ]
    }
  ]
)
```

`WSFEX` expone actualmente estos métodos:

- `ultimo_comprobante_autorizado(opciones)`
- `autorizar_comprobantes(opciones)`

Para `autorizar_comprobantes`, el payload mínimo sigue la estructura documentada por AFIP para `FEXAuthorize`. A nivel comprobante se validan como obligatorios:

- `id` (se completa automáticamente con `cbte_nro` si no se envía)
- `fecha_cbte`
- `cbte_tipo`
- `punto_vta`
- `cbte_nro`
- `tipo_expo`
- `permiso_existente`
- `dst_cmp`
- `cliente`
- `domicilio_cliente`
- `moneda_id`
- `moneda_ctz` (no requerido si `can_mis_mon_ext` es `'S'`; debe ser mayor a 0)
- `imp_total`
- `idioma_cbte`
- `items`
- `cuit_pais_cliente` o `id_impositivo`

Cada item requiere al menos:

- `pro_ds`
- `pro_umed`
- `pro_total_item`

Ver specs para más ejemplos.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test, test, test (`guard`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
