RSpec::Matchers.define :match_xpath do |xpath, expected_text|
  match do |xml|
    xml = Nokogiri::XML xml
    xml.xpath(xpath).text.should == expected_text
  end
end

require 'mocha/parameter_matchers/base'

module Mocha
  module ParameterMatchers
    def has_path(paths)
      HasPath.new(paths)
    end

    class HasPath < Base # :nodoc:
      def initialize(paths)
        @paths = paths
      end
      
      def matches?(available_parameters)
        parameter = available_parameters.shift
        return false unless parameter.is_a? Hash
        @paths.all? do |path| 
          path, expected_value = path
          actual_value = parameter.fetch_path path.gsub('/', '/wsdl:')
          @failed_path, @failed_value, @actual_value = path, expected_value, actual_value
          expected_value == actual_value
        end
      end
      
      def mocha_inspect
        "has_path(#{@failed_path.mocha_inspect} => #{@failed_value.mocha_inspect} | Actual: #{@actual_value.mocha_inspect})"
      end
    end
  end
end