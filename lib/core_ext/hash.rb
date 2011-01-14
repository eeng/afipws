class Hash
  def fetch_path path
    path.split('/').drop(1).inject(self) { |hash, key| hash.respond_to?(:has_key?) && hash.has_key?(key) ? hash[key] : break }
  end
  
  def select_keys *keys
    select { |k, _| keys.include? k }
  end
end