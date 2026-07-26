# Afipws

Ruby client para los web services de la AFIP.

[![Build Status](https://github.com/eeng/afipws/actions/workflows/ci.yml/badge.svg)](https://github.com/eeng/afipws/actions/workflows/ci.yml)

## Servicios Disponibles

- wsaa (WSAA)
- wsfe (WSFE)
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

Ver specs para más ejemplos.

### WSFE en producción

El endpoint de producción de WSFE utiliza actualmente parámetros Diffie-Hellman
que OpenSSL rechaza con su nivel de seguridad predeterminado. `WSFE` aplica
automáticamente una compatibilidad limitada a ese endpoint (`DEFAULT@SECLEVEL=1`):
mantiene TLS 1.2, la verificación del certificado y no modifica otros servicios.
El ajuste se puede reemplazar pasando `savon: {ssl_ciphers: '...'}`; debe usarse
únicamente mientras ARCA mantenga este problema de infraestructura.

## Desarrollo

Este proyecto usa [mise](https://mise.jdx.dev/) para seleccionar Ruby y ejecutar las tareas de desarrollo. El archivo `.ruby-version` fija la versión de Ruby requerida.

```sh
mise install
mise run setup
mise run test
```

También se puede abrir una consola interactiva con `mise run console`.

### Smoke test manual

El script `script/smoke_test.rb` ejecuta consultas de solo lectura contra el
entorno de homologación. Requiere un certificado vigente y autorizado para los
servicios consultados:

```sh
ARCA_CUIT='...' \
ARCA_KEY='path/to/development.key' \
ARCA_CERT='path/to/development.crt' \
bundle exec ruby -Ilib script/smoke_test.rb
```

```sh
ARCA_ENV=production \
ARCA_CUIT='...' ARCA_KEY='path/to/production.key' \
ARCA_CERT='path/to/production.crt' \
bundle exec ruby -Ilib script/smoke_test.rb
```

Las consultas de padrón requieren además `ARCA_PERSONA_ID`. La consulta de
`wconsdeclaracion` es opcional y requiere `ARCA_RUN_WCONS=1`, además de los
valores correctos para `ARCA_TIPO_AGENTE` y `ARCA_ROL`.

## Contributing

Las contribuciones son bienvenidas. Consultá [AGENTS.md](AGENTS.md) para la
estructura del proyecto, estilo de código, pruebas y criterios para commits y
pull requests.

Antes de abrir un pull request, ejecutá la suite completa:

```sh
mise run test
```

Incluí una descripción breve del cambio y las pruebas realizadas. No incluyas
certificados, claves privadas ni credenciales en commits o ejemplos.
