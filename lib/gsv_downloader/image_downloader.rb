require 'faraday'
require 'fileutils'
require "subexec"
require 'pathname'

##
# Google Street View Images Downloader
#  gsv_images = imageDonwloader.new
#  gsv_images.download("3ed539212sSA",2, "./images")
#
class ImageDownloader

	def initialize(tmp_path = "./tmp")

		set_tmp_dir(tmp_path)

		@conn = Faraday.new(:url => "https://geo2.ggpht.com/") do |faraday|
			# faraday.request :retry, max: 3, interval: 2
			faraday.response :raise_error
			faraday.adapter  Faraday.default_adapter
		end
	end

	def set_tmp_dir(tmp_path)
		@tmp_path = tmp_path
		FileUtils.mkdir_p(@tmp_path)
	end


	def download(panoID,  zoom_level = 4, dest_dir = "./images")

		FileUtils.mkdir_p(dest_dir) #create dir if not already present

		dest_filename = create_filename(panoID, zoom_level, dest_dir)

		if Pathname.new(dest_filename).exist?
			puts "images #{panoID} already existing in #{dest_dir}"
		else
			# puts "fetching #{panoID} to #{dest_dir}"
			# download each tile
			tiles_filenames = download_tiles(panoID, zoom_level)

			# combine tiles
			combine_tiles(tiles_filenames, zoom_level, panoID)

			# crop panorama
			crop_pano(panoID, zoom_level, dest_filename)

			# remove tmps
			FileUtils.rm_f("#{@tmp_path}/#{panoID}.jpg")
			tiles_filenames.each do |tile_filename|
		  	FileUtils.rm_f(tile_filename)
		  end
		end
	  dest_filename
	end

	def download_tiles(panoID, zoom_level)
		tiles_filenames = []
		get_tiles(zoom_level) do |x, y|
			filename = "#{@tmp_path}/tile-#{panoID}-#{x}-#{y}.jpg"
			tiles_filenames << download_tile(zoom_level, x, y, panoID, filename)
			#puts "downloaded tile  x=#{x},y=#{y}"
		end
		tiles_filenames
	end

	def download_tile(zoom, x, y, panoID, filename)
		url = "/cbk?output=tile&zoom=#{zoom}&x=#{x}&y=#{y}&panoid=#{panoID}"

		#resp = Net::HTTP.get_response(URI.parse(url))
		begin
			resp = @conn.get do |req|
				req.url url
			  req.options[:timeout] = 2           # open/read timeout in seconds
	  		req.options[:open_timeout] = 2
	  		
	  	end
  	rescue Exception => err
  		p err
  		 raise Exception.new("error downloading tile #{panoID} #{x}x#{y} zoom:#{zoom}")
  	end


		open(filename, 'wb') do |file|
  		file.write(resp.body)
		end
		filename
	end

	def get_tiles( zoom_level = 3)
		last_x_tile = get_nb_tiles(zoom_level,:x) - 1
		last_y_tile = get_nb_tiles(zoom_level,:y) - 1
		(0..last_y_tile).each do |y|
			(0..last_x_tile).each do |x|
				yield(x,y)
			end
		end
	end

	def crop_pano(panoID, zoom_level, dest_filename, pov = true)
		
		if (pov)
			crop = case zoom_level
				when 1 then "#{440}x#{200}"
				when 2 then "#{2048 - 384}x#{1024 - 256}"
				when 3 then "#{3584 - 256}x#{2048 - 384}"
				when 4 then "#{6656}x#{3584 - 256}" #-256
				when 5 then "#{13312}x#{6656}"
			end
			offset = case zoom_level				
				when 1 then "#{180}+#{100}"
				when 2 then "#{2048 - 384}x#{1024 - 256}"
				when 3 then "#{3584 - 256}x#{2048 - 384}"
				when 4 then "#{6656}x#{3584 - 256}" #-256
				when 5 then "#{13312}x#{6656}"
			end
		else
			crop = case zoom_level
				when 0 then "#{512 - 96}x#{512 - 304}"
				when 1 then "#{1024 - 256}x#{512 - 128}"
				when 2 then "#{2048 - 384}x#{1024 - 256}"
				when 3 then "#{3584 - 256}x#{2048 - 384}"
				when 4 then "#{6656}x#{3584 - 256}" #-256
				when 5 then "#{13312}x#{6656}"
			end
			offset = "0+0"
		end

		


		# WARNING: may not overwrite previous file
		cmd = "convert #{@tmp_path}/#{panoID}.jpg  -crop #{crop}+#{offset}  #{dest_filename} "
 		 Subexec.run cmd, :timeout => 0
	end

	def get_nb_tiles(zoom_level, axis)
		zoom_level -= 1 if axis == :y and zoom_level> 0
		case zoom_level
		  when 0 then 1
			when 1 then 2
			when 2 then 4
			when 3 then 7
			when 4 then 13
			when 5 then 26
		end
	end

	def combine_tiles(tiles, zoom, panoID)
		cmd = "montage #{tiles.join(" ")} -geometry +0+0 -tile #{get_nb_tiles(zoom,:x)}x#{get_nb_tiles(zoom,:y)} #{@tmp_path}/#{panoID}.jpg"
		Subexec.run cmd, :timeout => 0
	end

	private

	def create_filename(pano_id, zoom_level, dest_dir)
		"#{dest_dir}/#{pano_id}_zoom_#{zoom_level}.jpg"
	end

	# def image_exists?(panoID, zoom_level, dest_dir)
	#	filename = create_filename(panoID,zoom_level,dest_dir)
	#	Pathname.new(filename).exist?
	# end
end