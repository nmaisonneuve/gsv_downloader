require 'parallel'
require 'ruby-progressbar'
require 'fileutils'

# Google Street View manager
class GSVManager
	#		options = {
	#			crawl_session: "paris",
	#			area_validator: lambda { |json_response|
	#				description = json_response["Location"]["region"]
	#				description[/Paris/].nil? == false
	#				},
	#			image_zoom: 3,
	#			dest_dir: "./paris",
	#			sub_dir_size: 1000
	#		}

	def initialize(options)
		@options = options
		@downloader = ImageDownloaderParallel.new
		@db = DBRedis.new(options[:area_name])
		@scrawler = Crawler.new(options[:area_validator],@db)
		@images_per_subfolder = options[:sub_dir_size] || 1000
		@zoom_level = options[:zoom_level] || 3
		@dest_dir = options[:dest_dir] || "./images/#{options[:area_name]}"
	end

	def panoramas_index
		@db.list()
	end

	def crawl_metadata(from_pano_id = nil)
			puts "#{@db.scrawled_count()} panoramas scrawled, #{@db.nb_panoramas()} withing the area"
			if (from_pano_id.nil?)
				pano_ids = @db.not_scrawled()
				puts " #{pano_ids.size} panorama in the queue"
				@scrawler.start(pano_ids) if pano_ids.size > 0
			else
				@scrawler.start([from_pano_id])
			end
	end

	def reset_crawl
		puts "#{@db.scrawled_count()} panoramas scrawled, #{@db.nb_panoramas()} withing the area"
		@db.reset_crawl
	end

	def get_metadata(pano_id)
		@db.get_metadata(pano_id)
	end

	def download_missing_images()
		pano_ids = @db.images_to_download()

		progress = ProgressBar.create(
			:title => "images download for #{@options[:area_name]}",
			:total => pano_ids.size)

		# by default  1 thread but you can increase the multi-tread
		i = 0
		Parallel.each(pano_ids,
			:in_threads => 20,
			:finish => lambda { |i, item| progress.increment }) do |pano_id|
				@downloader.download(pano_id, @zoom_level, get_dir(i))
				i += 1
		end
	end

	private

	# get the related directory for the ith element
	def get_dir(i)

	  # if we used sub directory
	  dir_dest = if @images_per_subfolder > 0
	  	sub_idx = i / @images_per_subfolder
			"#{@dest_dir}/#{sub_idx}"
		else
			@dest_dir
		end

		FileUtils.mkdir_p(dir_dest) unless FileUtils.exists?(dir_dest)
		dir_dest
	end
end