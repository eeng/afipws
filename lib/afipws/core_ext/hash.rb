module Afipws
  module CoreExt
    module Hash
      def fetch_path path
        path.split('/').drop(1).inject(self) do |hash, key| 
          if scan = key.scan(/\[[\d+]\]/).first
            key.sub! scan, ''
            idx = scan.scan(/\d+/).first.to_i
            hash.respond_to?(:has_key?) && hash.has_key?(key) ? hash[key][idx] : break
          else
            hash.respond_to?(:has_key?) && hash.has_key?(key) ? hash[key] : break
          end
        end
      end
  
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