require 'bundler/setup'
require 'afipws'
require 'pry'

ws = Afipws::PersonaServiceA100.new env: :development, cuit: ENV['CUIT'], key: File.read(ENV['KEY']), cert: File.read(ENV['CRT'])
# ws.jurisdictions

binding.pry
