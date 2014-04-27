require 'redis'

class DBRedis

	def initialize(area_id = nil)
		@redis = Redis.new(:driver =>  :hiredis) #:ruby
		@area = area_id
	end

	def mark_as_crawled(panoID)
		@redis.sadd("area:#{@area}:crawled", panoID)
	end

	def crawled?(panoID)
		@redis.sismember("area:#{@area}:crawled", panoID)
	end

  def mark_to_crawl(panoID)
  	@redis.sadd("area:#{@area}:crawl_queue", panoID)
  end

	def to_crawl?(panoID)
		!@redis.sismember("area:#{@area}:crawl_queue", panoID)
	end

	def not_scrawled()
		list = @redis.sdiff("area:#{@area}:crawl_queue","area:#{@area}:crawled")
		test = @redis.sismember("area:#{@area}:crawl_queue",  list[0]) and (!@redis.sismember("area:#{@area}:crawled",  list[0]))
		puts "TEST #{test}"
		list
	end

	def reset_crawl
		@redis.del("area:#{@area}:crawled")
		@redis.del("area:#{@area}:crawl_queue")
		@redis.del("area:#{@area}")
	end

  def crawled_count()
    @redis.scard("area:#{@area}:crawled")
  end

  def to_crawl_count()
    @redis.scard("area:#{@area}:crawl_queue")
  end

  def nb_panoramas()
		@redis.scard("area:#{@area}")
	end

  def list()
		@redis.smembers("area:#{@area}")
	end

	def add_to_area(panoID)
		@redis.sadd("area:#{@area}", panoID)
	end

	def metadata_exists?(panoID)
		@redis.exists(panoID)
	end

	def add_pano(panoID, data)
		# @redis.pipelined do
			set_metadata(panoID, data) # unless metadata_exists?(panoID)
			add_to_area(panoID)
		 # end
	end

	def set_filename(panoID, fullname)
			@redis.set("filepath:#{panoID}", fullname)
	end

	def get_filename(panoID)
			@redis.get("filepath:#{panoID}")
	end

	def images_to_download()
		pano_ids = []
		list().each do |pano_id|
			pano_ids << pano_id unless @redis.exists("filepath:#{pano_id}")
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