module Afipws
  class ResponseError < Error
    attr_reader :errors

    def initialize errors
      raise ArgumentError, '`errors` must be an array of maps, each with :code and :msg keys' unless errors.is_a? Array

      super errors.map { |e| "#{e[:code]}: #{e[:msg]}" }.join '; '
      @errors = errors
    end

    def code? code
      @errors.any? { |e| e[:code].to_s == code.to_s }
    end
  end
end
