#!/usr/bin/env ruby

require 'date'
require 'afipws'

environment = (ENV['ARCA_ENV'] || 'development').to_sym

cuit = ENV.fetch('ARCA_CUIT')
key_path = ENV.fetch('ARCA_KEY', 'keys/arca-dev.key')
cert_path = ENV.fetch('ARCA_CERT', 'keys/arca-dev.crt')

options = {
  env: environment,
  cuit: cuit,
  key: File.read(key_path),
  cert: File.read(cert_path),
  ta_path: "tmp/#{cuit}-#{environment}-smoke-wsaa-ta.dump"
}

failures = 0

def summarize(value)
  case value
  when Array
    "#{value.size} records"
  when Hash
    "#{value.size} fields"
  else
    value.inspect
  end
end

def run_check(name)
  value = yield
  puts "PASS #{name} (#{summarize(value)})"
rescue StandardError => e
  message = e.message.gsub(/\s+/, ' ').strip
  puts "FAIL #{name}: #{e.class}: #{message}"
  false
end

def check(name)
  result = yield
  result == false ? 1 : 0
end

wsfe = Afipws::WSFE.new(options.merge(ta_path: "tmp/#{cuit}-#{environment}-smoke-wsfe-ta.dump"))
failures += check('WSFE dummy') { run_check('WSFE dummy') { wsfe.dummy } }
failures += check('WSFE cotizacion') { run_check('WSFE cotizacion DOL') { wsfe.cotizacion('DOL') } }
failures += check('WSFE tipos_comprobantes') { run_check('WSFE tipos_comprobantes') { wsfe.tipos_comprobantes } }
failures += check('WSFE tipos_documentos') { run_check('WSFE tipos_documentos') { wsfe.tipos_documentos } }
failures += check('WSFE tipos_concepto') { run_check('WSFE tipos_concepto') { wsfe.tipos_concepto } }
failures += check('WSFE tipos_monedas') { run_check('WSFE tipos_monedas') { wsfe.tipos_monedas } }
failures += check('WSFE tipos_iva') { run_check('WSFE tipos_iva') { wsfe.tipos_iva } }
failures += check('WSFE tipos_tributos') { run_check('WSFE tipos_tributos') { wsfe.tipos_tributos } }
failures += check('WSFE tipos_opcional') { run_check('WSFE tipos_opcional') { wsfe.tipos_opcional } }
failures += check('WSFE cant_max_registros_x_lote') { run_check('WSFE cant_max_registros_x_lote') { wsfe.cant_max_registros_x_lote } }

a100 = Afipws::PersonaServiceA100.new(options.merge(ta_path: "tmp/#{cuit}-#{environment}-smoke-a100-ta.dump"))
failures += check('PersonaServiceA100 dummy') { run_check('PersonaServiceA100 dummy') { a100.dummy } }
failures += check('PersonaServiceA100 jurisdictions') { run_check('PersonaServiceA100 jurisdictions') { a100.jurisdictions } }
failures += check('PersonaServiceA100 company_types') { run_check('PersonaServiceA100 company_types') { a100.company_types } }
failures += check('PersonaServiceA100 public_organisms') { run_check('PersonaServiceA100 public_organisms') { a100.public_organisms } }

if (persona_id = ENV['ARCA_PERSONA_ID'])
  a4 = Afipws::PersonaServiceA4.new(options.merge(ta_path: "tmp/#{cuit}-#{environment}-smoke-a4-ta.dump"))
  failures += check('PersonaServiceA4 get_persona') { run_check('PersonaServiceA4 get_persona') { a4.get_persona(persona_id) } }

  a5 = Afipws::PersonaServiceA5.new(options.merge(ta_path: "tmp/#{cuit}-#{environment}-smoke-a5-ta.dump"))
  failures += check('PersonaServiceA5 get_persona') { run_check('PersonaServiceA5 get_persona') { a5.get_persona(persona_id) } }

  constancia = Afipws::WSConstanciaInscripcion.new(options.merge(ta_path: "tmp/#{cuit}-#{environment}-smoke-constancia-ta.dump"))
  failures += check('WSConstanciaInscripcion get_persona') do
    run_check('WSConstanciaInscripcion get_persona') { constancia.get_persona(persona_id) }
  end
else
  puts 'SKIP persona lookups (set ARCA_PERSONA_ID to run them)'
end

if ENV['ARCA_RUN_WCONS'] == '1'
  wcons = Afipws::WConsDeclaracion.new(
    **options.merge(
      tipo_agente: ENV.fetch('ARCA_TIPO_AGENTE', 'IMEX'),
      rol: ENV.fetch('ARCA_ROL', 'IMEX'),
      ta_path: "tmp/#{cuit}-#{environment}-smoke-wcons-ta.dump"
    )
  )
  failures += check('WConsDeclaracion dummy') { run_check('WConsDeclaracion dummy') { wcons.dummy } }
  failures += check('WConsDeclaracion list') do
    run_check('WConsDeclaracion list') do
      wcons.detallada_lista_declaraciones(
        fecha_oficializacion_desde: Date.new(2020, 1, 1),
        fecha_oficializacion_hasta: Date.today
      )
    end
  end
else
  puts 'SKIP WConsDeclaracion (set ARCA_RUN_WCONS=1 to run it)'
end

abort "#{failures} smoke check(s) failed" unless failures.zero?
puts "Smoke test passed for #{environment}."
