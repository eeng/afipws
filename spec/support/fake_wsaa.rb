module Afipws
  class FakeWSAA
    def initialize ta:
      @ta = ta
    end

    def auth
      @ta
    end
  end
end
