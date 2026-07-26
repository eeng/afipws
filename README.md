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

## Desarrollo

Este proyecto usa [mise](https://mise.jdx.dev/) para seleccionar Ruby y ejecutar las tareas de desarrollo. El archivo `.ruby-version` fija la versión de Ruby requerida.

```sh
mise install
mise run setup
mise run test
```

También se puede abrir una consola interactiva con `mise run console`.

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
