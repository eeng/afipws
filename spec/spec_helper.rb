require 'rspec'
require 'ruby-debug'
require 'afipws'
require 'savon_spec'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include Savon::Spec::Macros
end

Savon::Spec::Fixture.path = File.expand_path("../fixtures", __FILE__)
