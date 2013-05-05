	require 'parallel'
	require 'benchmark'
	require 'ruby-progressbar'
	require 'fileutils'

# Google Street View manager
class GSVManager

	def initialize()
		@downloader = GSVAsyncDownloader.new
		@chunk_dir = false
		@chunk_size = 1000
	end

	def scrawl(area_name, options)
			{onlymetadata: true}
	end

	def download_image(pano_id, zoom_level = 3, dest_dir = "./images")
		@downloader.fetch(pano_id, zoom_level, dest_dir)
	end

	def download_images(pano_ids, zoom_level = 3, dest_dir = "images")

		progress = ProgressBar.create(
			:title => "images download for #{area_name}",
			:total => pano_ids.size)

		active_chunk_dir if (pano_ids > 1000)

		# by default  1 thread but you can increase the multi-tread
		i = 0
		current_dir = dest_dir
		Parallel.each(pano_ids,
			:in_threads => 10,
			:finish => lambda { |i, item| progress.increment }) do |pano_id|

				# change directory
				if @chunk_dir and (i % chunk_size) == 0
					current_dir = change_dir(dest_dir, i / chunk_size)
					i += 1
				end

				download_image(pano_id, zoom_level, current_dir)
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