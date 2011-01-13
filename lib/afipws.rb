require 'builder'
require 'base64'
require 'savon'
require 'nokogiri'
require 'active_support/core_ext/array/wrap'
require 'afipws/excepciones'
require 'afipws/wsaa'
require 'afipws/wsfe'

Savon.configure do |config|
  config.log = false
end