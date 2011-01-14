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
        Hash[object.map { |k, v| [k, v.is_a?(Hash) || v.is_a?(Array) ? convert(v, types, convert_fn) : convert_fn[types[k]].call(v)] }]
      else 
        object
      end
    end
    
    def parsing_fn
      @parsing ||= Hash.new(Proc.new { |other| other }).tap { |p|
        p[:date] = Proc.new { |date| ::Date.parse(date) rescue nil }
        p[:integer] = Proc.new { |integer| integer.to_i }
        p[:float] = Proc.new { |float| float.to_f }
      }
    end

    def marshall_fn
      @marshall ||= Hash.new(Proc.new { |other| other }).tap { |p|
        p[:date] = Proc.new { |date| date.strftime('%Y%m%d') }
      }
    end    
  end
end