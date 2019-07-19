module Afipws
  class WSError < StandardError
    attr_reader :errors

    def initialize errors
      if errors.is_a? Array
        super errors.map { |e| "#{e[:code]}: #{e[:msg]}" }.join '; '
        @errors = errors
      else
        super
        @errors = []
      end
    end

    def code? code
      @errors.any? { |e| e[:code].to_s == code.to_s }
    end
  end
end
