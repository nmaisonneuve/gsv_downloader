require 'faraday'
require 'fileutils'
require "subexec"

##
# Google Street View Images Downloader
#
class ImageDownloader

	def initialize(tmp_path = "./tmp")
		@tmp_path = tmp_path
		@conn = Faraday.new(:url => "http://cbk1.google.com") do |faraday|
			faraday.request :retry, max: 3, interval: 2
			#faraday.response :logger
			faraday.response :raise_error
			faraday.adapter  Faraday.default_adapter
		end
	end

	def download(panoID,  zoom_level = 4, dest_dir = "./images")

		dest_filename = create_filename(panoID, zoom_level, dest_dir)

		FileUtils.mkdir_p(dest_dir) #create dir if not already present

		if Pathname.new(dest_filename).exist?
			puts "images #{panoID} already existing in #{dest_dir}"
		else
			# puts "fetching #{panoID} to #{dest_dir}"
			# download each tile
			tiles_filenames = download_tiles(panoID, zoom_level)

			# combine tiles
			#puts "combining tiles"
			combine_tiles(tiles_filenames, zoom_level, panoID)

			# crop panorama
			#puts "croping panorama"
			crop_pano(panoID, zoom_level, dest_filename)

			# remove tmps
			# puts "removing tmp files"
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
			tiles_filenames << download_tile(zoom_level, x, y, panoID)
			#puts "downloaded tile  x=#{x},y=#{y}"
		end
		tiles_filenames
	end

	def download_tile(zoom, x, y, panoID)
		url = "/cbk?output=tile&zoom=#{zoom}&x=#{x}&y=#{y}&v=4&panoid=#{panoID}"
		#resp = Net::HTTP.get_response(URI.parse(url))
		resp = @conn.get do |req|
			req.url url
		  req.options[:timeout] = 2           # open/read timeout in seconds
  		req.options[:open_timeout] = 2
  	end
		filename = "#{@tmp_path}/tile-#{panoID}-#{x}-#{y}.jpg"
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

	def crop_pano(panoID, zoom_level, dest_filename)
		crop = case zoom_level
			when 3 then "#{3584 - 256}x#{2048 - 384}"
			when 4 then "#{6656}x#{3584 - 256}" #-256
			when 5 then "#{13312}x#{6656}"
		end
		# WARNING: may not overwrite previous file
		cmd = "convert #{@tmp_path}/#{panoID}.jpg  -crop #{crop}+0+0  #{dest_filename} "
 		 Subexec.run cmd, :timeout => 0
	end

	def get_nb_tiles(zoom_level, axis)
		zoom_level -= 1 if axis == :y
		case zoom_level
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

	def image_exists?(panoID, zoom_level, dest_dir)
		filename = create_filename(panoID,zoom_level,dest_dir)
		Pathname.new(filename).exist?
	end
end