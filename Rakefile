require "bundler/gem_tasks"
require "./lib/gsv_downloader.rb"

namespace :gsv do

	desc "download a specific image e.g. rake gsv:download_image panoid=Np2alC97cgynvV_ZpJQZNA zoom=3 dest=./images"
	task :download_image do

		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		zoom = ENV["zoom"] || "3"
		dest_dir = ENV["dest"] || "./images"

		downloader = ImageDownloader.new
		downloader.download(panoID,zoom.to_i,".")
	end

	task :metadata do

		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		db = DBRedis.new

		p JSON.parse(db.get_metadata(panoID))


		end

	desc "list"
	task :list do
  	options = {
			area_name: "paris"
		}

		manager = GSVManager.new(options)
		i = 0
		kml = "<?xml version='1.0' encoding='utf-8' ?><kml xmlns='http://www.opengis.net/kml/2.2'><Document>"
		manager.panoramas_index.each do |panoID|
			i += 1
			json = JSON.parse(manager.get_metadata(panoID))
			lat = json["Location"]["lat"]
			lng = json["Location"]["lng"]
			kml << "<Placemark><description>#{panoID}</description><Point><coordinates>#{lng}, #{lat}, 0</coordinates></Point></Placemark>\n"
		end
		kml << "</Document></kml>"
		File.open("test.kml", 'w') {|f| f.write(kml) }
		puts "#{i} panoID"
	end

	desc "crawl"
	task :crawl do
	 	# require 'perftools'
	  # PerfTools::CpuProfiler.start("tmp/add_numbers_profile") do
	  # end
	  area_validator = lambda { |json_response|
				description = json_response["Location"]["region"]
			#	p json_response["Location"]
				description[/Paris/].nil? == false
		}

  	options = {
			area_name: "paris",
			area_validator: area_validator
		}

		manager = GSVManager.new(options)
		# manager.reset_crawl
	  # manager.crawl_metadata("Np2alC97cgynvV_ZpJQZNA")
		manager.crawl_metadata()
	end

	desc "download all panoramas"
	task :download_all_images do
		options = {
			area_name: "paris",
			image_zoom: 3,
			dest_dir: "./paris",
			sub_dir_size: 1000
		}
		manager = GSVManager.new(options)
		manager.download_missing_images()
	end
end