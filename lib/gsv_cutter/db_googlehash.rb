require "google_hash"

class DBGooglehash

  def initialize
    @_index_cache = GoogleHashDenseLongToInt.new
  end

  def exists?(panoID)
    @_index_cache.has_key?(panoID.hash)
  end

  def <<(panoID)
    @_index_cache[string.hash] = 1
  end
end