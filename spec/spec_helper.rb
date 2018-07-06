require 'rspec'
require 'afipws'
require 'savon/mock/spec_helper'
require 'mocha'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include Savon::SpecHelper

  config.mock_with :mocha
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.alias_example_to :fit, focused: true
  config.filter_run focused: true
  config.run_all_when_everything_filtered = true

  config.before(:all) { savon.mock!   }
  config.after(:all)  { savon.unmock! }
end

def fixture file
  File.read("#{Afipws::Root}/spec/fixtures/#{file}.xml")
end