require "bundler/gem_tasks"
require "./lib/gsv_downloader.rb"

namespace :gsv do

	desc "download a specific image e.g. rake gsv:download_image panoid=Np2alC97cgynvV_ZpJQZNA zoom=3 dest=./images"
	task :image do
		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		zoom = ENV["zoom"] || "3"
		dest_dir = ENV["dest"] || "./images"

		downloader = ImageDownloader.new
		downloader.download(panoID,zoom.to_i,".")
	end

	desc "get the metadata of given panoID e.g. rake gsv:image panoid=Np2alC97cgynvV_ZpJQZNA"
	task :metadata do
		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		db = DBRedis.new
		p JSON.parse(db.get_metadata(panoID))
	end

	desc "get the metadata of given panoID e.g. rake gsv:image panoid=Np2alC97cgynvV_ZpJQZNA"
	task :metadata_list do
		require 'csv'
		downloader = MetaDataDownloader.new
		db = DBRedis.new
		CSV.foreach("../gsv_cutter/data/detections/pano_not_found.csv") do |row|
			downloader.download(row) do | response|
				panoID = JSON.parse(response)["Location"]["panoId"]
				puts "panoID found #{panoID}"
				db.add_pano(panoID, response)
			end
		end
		downloader.start()
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

	desc "stats"
	task :stats do
		area = ENV["area"] || "paris_v2"
		db = DBRedis.new (area)
		puts "nb of panorama in #{area}: #{db.nb_panoramas()}"
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
			area_name: "paris_v2",
			area_validator: area_validator
		}

		manager = GSVManager.new(options)
		#manager.reset_crawl
		# Np2alC97cgynvV_ZpJQZNA
	  # manager.crawl_metadata("C9n1hj8bYQ_sZdPiXylGoA")
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