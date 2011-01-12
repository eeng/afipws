require 'builder'
require 'base64'
require 'savon'
require 'nokogiri'
require 'afipws/wsaa'

Savon.configure do |config|
  config.log = false
end