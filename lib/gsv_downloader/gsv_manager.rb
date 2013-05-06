require 'parallel'
require 'ruby-progressbar'
require 'fileutils'

# Google Street View manager
class GSVManager

	#		options = {
	#			area_name: "paris",
	#			area_validator: lambda { |json_response|
	#				description = json_response["Location"]["region"]
	#				description[/Paris/].nil? == false
	#				},
	#			image_zoom: 3,
	#			dest_dir: "./paris",
	#			sub_dir_size: 1000
	#		}
	def initialize(options)
		@downloader = DownloaderAsync.new
		@db = DBRedis.new(options[:area_name])
		@scrawler = SimpleCrawler.new(@db, options[:area_validator])
		@chunk_size = options[:sub_dir_size] || 1000
		@zoom_level = options[:zoom_level] || 3
		@dest_dir = options[:dest_dir] || "./images/#{options[:area_name]}"
	end

	def scrawl_metadata(from_pano_id = nil)
			@scrawler.start(from_pano_id)
	end

	# shortcut
	def download_image(pano_id, zoom_level, dest_dir)
		@downloader.fetch(pano_id, zoom_level, dest_dir)
	end

	def download_images()
		pano_ids = @db.images_to_download()

		progress = ProgressBar.create(
			:title => "images download for #{area_name}",
			:total => pano_ids.size)

		active_chunk_dir if (pano_ids.size > 1000)

		# by default  1 thread but you can increase the multi-tread
		i = 0
		current_dir = @dest_dir
		Parallel.each(pano_ids,
			:in_threads => 10,
			:finish => lambda { |i, item| progress.increment }) do |pano_id|
				# change directory
				if @chunk_dir and (i % chunk_size) == 0
					current_dir = change_dir(@dest_dir, i / chunk_size)
					i += 1
				end
				@downloader.fetch(pano_id, @zoom_level, current_dir)
		end
	end

	private

	def active_chunk_dir
		@chunk_dir = true
	end

	def  change_dir(dest_dir, i)
		dir_dest = "#{dest_dir}/#{i}"
		FileUtils.mkdir_p(dir_dest)
		dir_dest
	end
end