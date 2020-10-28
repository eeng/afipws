# Savon 2 sólo permite verificar los params del mensaje como un hash lo cual es poco flexible. Con esto permito pasarle xpaths.

module Savon
  module MessageMatcher
    def actual(operation_name, builder, globals, locals)
      super.update request: builder.to_s
    end

    def verify_message!
      if @expected[:message].respond_to? :verify!
        @expected[:message].verify! @actual[:request]
      else
        super
      end
    end
  end

  MockExpectation.prepend MessageMatcher
end

def has_path(paths)
  HasXPath.new(paths)
end

class HasXPath
  include RSpec::Matchers

  def initialize(paths)
    @paths = paths
  end

  def verify! xml
    @actual_xml = xml
    @paths.each do |(path, value)|
      @expected_xpath, @expected_value = path, value
      @actual_xml.should match_xpath @expected_xpath, @expected_value
    end
  end
end
