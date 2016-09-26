module Afipws
  Root = File.expand_path File.dirname(__FILE__) + '/..'
end

require 'forwardable'
require 'builder'
require 'base64'
require 'savon'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'afipws/core_ext/hash'
require 'afipws/excepciones'
require 'afipws/type_conversions'
require 'afipws/client'
require 'afipws/wsaa'
require 'afipws/wsfe'
