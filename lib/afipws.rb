module Afipws
  Root = File.expand_path File.dirname(__FILE__) + '/..'
end

require 'forwardable'
require 'builder'
require 'base64'
require 'savon'
require 'nokogiri'
require 'active_support/core_ext/array/wrap'
# TODO reemplazar wrap x un local
require 'core_ext/string'
require 'afipws/excepciones'
require 'afipws/client'
require 'afipws/wsaa'
require 'afipws/wsfe'

Savon.configure do |config|
  config.soap_version = 2
  config.log = false
end
