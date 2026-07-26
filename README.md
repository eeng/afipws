# Afipws

Cliente Ruby para los web services de ARCA (antes AFIP), con soporte para los
entornos de homologación y producción.

[![Build Status](https://github.com/eeng/afipws/actions/workflows/ci.yml/badge.svg)](https://github.com/eeng/afipws/actions/workflows/ci.yml)

## Servicios disponibles

| Clase | Servicio WSAA | Uso |
| --- | --- | --- |
| `WSAA` | — | Autenticación y tickets de acceso |
| `WSFE` | `wsfe` | Facturación electrónica WSFEv1 |
| `WSConstanciaInscripcion` | `ws_sr_constancia_inscripcion` | Constancia de inscripción |
| `PersonaServiceA4` | `ws_sr_padron_a4` | Consultas de padrón |
| `PersonaServiceA5` | `ws_sr_padron_a5` | Consultas de padrón |
| `PersonaServiceA100` | `ws_sr_padron_a100` | Parámetros del padrón |
| `WConsDeclaracion` | `wconsdeclaracion` | Consultas de declaraciones aduaneras |

Cada servicio requiere que el certificado esté autorizado para ese servicio en
ARCA. Autorizar `wsfe` no autoriza automáticamente los servicios de padrón ni
los demás WSN.

## Instalación

```
gem install afipws
```

## Certificados y autenticación

ARCA utiliza certificados X.509 para autenticar al cliente mediante WSAA.
Homologación y producción usan certificados y autorizaciones independientes:

1. Generá una clave privada y un CSR. El `serialNumber` del CSR debe contener
   la misma CUIT con la que se ingresa a ARCA.
2. Para homologación, ingresá con clave fiscal a **WSASS – Autoservicio de
   Acceso a APIs de Homologación**, elegí **Nuevo Certificado**, cargá el CSR y
   guardá el certificado PEM devuelto.
3. En WSASS, creá una autorización para cada servicio que vayas a consumir.
4. Para producción, gestioná el certificado mediante el **Administrador de
   Certificados Digitales** y asociá cada servicio desde el **Administrador de
   Relaciones de Clave Fiscal**.

Documentación oficial: [WSAA](https://www.afip.gob.ar/ws/documentacion/wsaa.asp),
[certificados](https://www.arca.gob.ar/ws/documentacion/certificados.asp) y
[catálogo de web services](https://www.afip.gob.ar/ws/documentacion/catalogo.asp).

### Generar una clave y un CSR

No compartas ni commitees la clave privada.

```sh
mkdir -p keys
openssl genrsa -out keys/development.key 2048
openssl req -new \
  -key keys/development.key \
  -subj "/C=AR/O=[organizacion]/CN=[alias]/serialNumber=CUIT [cuit]" \
  -out keys/development.csr
```

El certificado y la clave deben corresponderse. Se puede verificar sin revelar
su contenido:

```sh
openssl x509 -in keys/development.crt -noout -subject -dates
openssl x509 -in keys/development.crt -noout -modulus | openssl md5
openssl rsa -in keys/development.key -noout -modulus | openssl md5
```

### Ejemplo WSFE

El siguiente ejemplo consulta la cotización del dólar en homologación:

```ruby
require 'afipws'

ws = Afipws::WSFE.new(
  env: :development,
  cuit: 'YOUR_CUIT',
  key: File.read('path/to/development.key'),
  cert: File.read('path/to/development.crt')
)

puts ws.cotizacion 'DOL'
```

Para producción, cambiá `env: :development` por `env: :production` y usá el
certificado de producción correspondiente.

Los endpoints y WSDL se seleccionan automáticamente según `env`. La
documentación oficial de [facturación electrónica](https://www.afip.gob.ar/ws/documentacion/ws-factura-electronica.asp)
incluye el manual de WSFEv1 y sus operaciones.

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

## Contribuir

Las contribuciones son bienvenidas. Consultá [AGENTS.md](AGENTS.md) para la
estructura del proyecto, estilo de código, pruebas y criterios para commits y
pull requests.

Antes de abrir un pull request, ejecutá la suite completa:

```sh
mise run test
```

Incluí una descripción breve del cambio y las pruebas realizadas. No incluyas
certificados, claves privadas ni credenciales en commits o ejemplos.
