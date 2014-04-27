require 'rubygems'
require 'gsv_downloader'

def crawl_from_postalcode(postalcode, lat = nil,lng = nil)
	
	data = GSVManager.get_info_from_postalcode(postalcode)
	
	city = data[:city]
	puts "---  CRAWLING #{city} - #{postalcode}"

	if (lat.nil?)
		start_panoID = data[:pano_id]
	else
		start_panoID = GSVManager.get_pano_id(lat,lng)
	end

	area_validator = lambda { |json_response|			
			# puts "checking validity" 
			description = json_response["Location"]["description"]
			region = json_response["Location"]["region"]
			if region[/#{city}/i].nil?
				false
			else
				true
			end
	}

	options = {
		area_name: postalcode,
		area_validator: area_validator
	}

	manager = GSVManager.new(options)	
 	manager.crawl_metadata(	start_panoID, true) 
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

	# downloader = ImageDownloader.new
	manager = GSVManager.new(options)
	manager.download_missing_images()
end

# crawl_from_postalcode("91390")
crawl_from_postalcode("95610",49.017751,2.104865)

