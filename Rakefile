require "bundler/gem_tasks"
require "./lib/gsv_cutter.rb"

namespace :gsv do
	desc "scrawl"
	task :scrawl do
	 require 'perftools'
	  PerfTools::CpuProfiler.start("tmp/add_numbers_profile") do


	 end
	end

	desc "download panorama e.g. rake gsv:download_image panoid=Np2alC97cgynvV_ZpJQZNA zoom=3"
	task :download_image do
		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		zoom = ENV["zoom"] || "4"

		manager = GSVManager.new
		manager.download_image(panoID,zoom.to_i)
	end

	desc "download all panoramas"
	task :download_all_images => ["standalone:connection"] do

	end
end