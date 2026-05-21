module Afipws
  module TypeConversions
    def r2x x, types
      convert x, types, marshall_fn
    end

    def x2r x, types
      convert x, types, parsing_fn
    end

    private

    # Hace una conversión recursiva de tipo de todos los values según los tipos de las keys indicados en types
    def convert object, types, convert_fn
      case object
      when Array then
        object.map { |e| convert e, types, convert_fn }
      when Hash then
        Hash[object.map do |k, v|
          [k, v.is_a?(Hash) || v.is_a?(Array) ? convert(v, types, convert_fn) : convert_fn[types[k]].call(v)]
        end]
      else
        object
      end
    end

    def parsing_fn
      @parsing_fn ||= Hash.new(proc { |v| v }).tap { |p|
        p[:date] = proc { |v| ::Date.parse(v) rescue nil }
        p[:integer] = proc { |v| v.to_i }
        p[:float] = proc { |v| v.to_f }
        p[:boolean] = proc { |v| v == 'S' }
      }
    end

    def marshall_fn
      @marshall_fn ||= Hash.new(proc { |other| other }).tap do |p|
        p[:date] = proc { |date| date.strftime('%Y%m%d') }
      end
    end
  end
end
