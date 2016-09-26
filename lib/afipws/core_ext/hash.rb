module Afipws
  module CoreExt
    module Hash
      def select_keys *keys
        select { |k, _| keys.include? k }
      end
  
      def has_entries? entries
        entries.each_pair.all? { |k, v| self[k] == v }
      end
    end
  end
end

class Hash
  include Afipws::CoreExt::Hash
end