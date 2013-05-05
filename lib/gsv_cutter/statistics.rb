	# Optional Statistics
	# - number of processed images
	# - speed/seconds
	class Statistics
		def initialize()
			@processed = 0
			reset_speed_session
		end

		def processed
			@processed
		end

		def reset_speed_session
			 @start_time = Time.now
			 @session_count = 0
		end

		def speed
			time = Time.now - @start_time
			@session_count.to_f / time.to_f
		end

		def count
	    if (@processed % 100) == 0
	      puts "#{@processed} GSV Images processed (speed: #{speed}/s)"
	      reset_speed_session
	    end
    	@processed += 1
			@session_count += 1
  	end
	end