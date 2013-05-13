require "bundler/gem_tasks"
require "./lib/gsv_downloader.rb"

namespace :gsv do

	desc "download a specific image e.g. rake gsv:download_image panoid=Np2alC97cgynvV_ZpJQZNA zoom=3 dest=./images"
	task :download_image do

		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		zoom = ENV["zoom"] || "3"
		dest_dir = ENV["dest"] || "./images"

		downloader = ImageDownloader.new
		downloader.download_image(panoID,zoom.to_i,".")
	end

	desc "crawl"
	task :crawl do
	 	# require 'perftools'
	  # PerfTools::CpuProfiler.start("tmp/add_numbers_profile") do
	  # end
	  area_validator = lambda { |json_response|
				description = json_response["Location"]["region"]
				description[/Paris/].nil? == false
		}

  	options = {
			area_name: "paris",
			area_validator: area_validator
		}

		manager = GSVManager.new(options)
		manager.reset_crawl
		manager.crawl_metadata("Np2alC97cgynvV_ZpJQZNA")
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