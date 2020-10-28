module Afipws
  class Error < StandardError
    def code? _code
      false
    end
  end
end
