require 'rubygems'
require 'gsv_downloader'

def crawl 
	area_validator = lambda { |json_response|			
			description = json_response["Location"]["description"]
				region = json_response["Location"]["region"]
			#p json_response["Location"]

			if region[/Vincennes/].nil?
				false
			else
				true
			end
	}

	options = {
		area_name: "vincennes",
		area_validator: area_validator
	}

	manager = GSVManager.new(options)
	#manager.reset_crawl
	# Np2alC97cgynvV_ZpJQZNA

	# manager.crawl_metadata("Xf0Yb8ePnZwE25F_doMQAA&w=88", true)
	manager.crawl_metadata()
end

def image

	area = "vincennes"
	options = {
		area_name: area,
		zoom_level: 1,
		dest_dir: "./#{area}",
		sub_dir_size: 1000
	}


		#downloader = ImageDownloader.new
	manager = GSVManager.new(options)
	manager.download_missing_images()

end

image()
