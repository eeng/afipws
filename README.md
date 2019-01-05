# Afipws

Ruby client para los web services de la AFIP.

[![Build Status](https://travis-ci.org/eeng/afipws.svg?branch=master)](https://travis-ci.org/eeng/afipws)

## Servicios Disponibles

* wsaa (WSAA)
* wsfe (WSFE)
* ws_sr_constancia_inscripcion (WSConstanciaInscripcion)
* ws_sr_padron_a100 (PersonaServiceA100)
* ws_sr_padron_a4 (PersonaServiceA4)

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

Ver specs para más ejemplos.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test, test, test (`guard`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
