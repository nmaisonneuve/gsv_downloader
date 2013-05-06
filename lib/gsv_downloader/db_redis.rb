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

  def size()
		@redis.scard("area:#{@area}")
	end

  def list()
		@redis.smembers("area:#{@area}")
	end

	def add(panoID)
		@redis.sadd("area:#{@area}", panoID)
	end

	def metadata_exists?(panoID)
		@redis.exists(panoID)
	end

	def add_pano(panoID, data)
		@redis.pipelined do
			mark_as_scrawled(panoID)
			set_metadata(panoID, data)
			add(panoID)
		end
	end

	def set_filename(panoID, fullname)
			@redis.set("filepath:#{panoID}", fullname)
	end

	def get_filename(panoID)
			@redis.get("filepath:#{panoID}")
	end

	def images_to_download()
		pano_ids = []
		@redis.list().each do |pano_id|
			pano_ids << pano_id unless @redis.exists("filepath:#{panoID}")
		end
		pano_ids
	end


	def get_metadata(panoID)
		@redis.get(panoID)
	end

	def set_metadata(panoID, data)
			@redis.set(panoID, data)
	end
end