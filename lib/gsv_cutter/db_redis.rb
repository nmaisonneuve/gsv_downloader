require 'redis'

class DBRedis

	def initialize(area_id = "paris")
		@redis = Redis.new(:driver =>  :hiredis) #:ruby
		@area = area_id
		reset_scrawl
	end

	def mark_as_scrawled(panoID)
		@redis.sadd("area:#{@area}:scrawled", panoID)
	end

	def scrawled?(panoID)
		@redis.sismember("area:#{@area}:scrawled", panoID)
	end

	def reset_scrawl
		@redis.del("area:#{@area}:scrawled")
	end

  def scrawled_count()
    @redis.scard("area:#{@area}:scrawled")
  end

	def metadata_exists?(panoID)
		@redis.exists(panoID)
	end

	def add_pano(panoID, data)
		@redis.pipelined do
			mark_as_scrawled(panoID)
			set_metadata(panoID, data)
			add_to_area(panoID)
		end
	end

	def set_metadata(panoID, data)
			@redis.set(panoID, data)
	end

	def set_file(panoID, fullname)
			@redis.set(panoID, data)
	end

	def add_to_area(panoID)
		@redis.sadd("area:#{@area}", panoID)
	end

	def get_metadata(panoID)
		@redis.get(panoID)
	end


  def area_count()
    @redis.scard("area:#{@area}")
  end

end