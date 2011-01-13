module Afipws
  class WSError < StandardError
    attr_reader :errors
    def initialize errors
      if errors.is_a? Array
        super errors.map { |e| "#{e[:code]}: #{e[:msg]}" }.join '; '
        @errors = errors
      else
        super
      end
    end
  end  
end
