require 'net/http'
require 'fileutils'
require "subexec"

class Downloader

	def initialize(dir_path = ".")
		@dir_path = dir_path
	end

	def fetch(panoID, zoom_level = 3, dir_path = ".")

		# download each tile
		tiles_filenames = []
		get_tiles(zoom_level) do |x, y|
			tiles_filenames << download_tile(zoom_level, x, y, panoID)
		end

		# combine
		combine_tiles(tiles_filenames, panoID)

		# remove tmps
		tiles_filenames.each do |tile_filename|
	  	FileUtils.rm_f(tile_filename)
	  end
	end

	def get_tiles( zoom_level = 3)
		nb_tiles_x = 3 * 2**(zoom_level-2)
		nb_tiles_y = 3 * 2**(zoom_level-3)
		(0..nb_tiles_y).each do |y|
			(0..nb_tiles_x).each do |x|
				yield(x,y)
			end
		end
	end

	def combine_tiles(tiles, panoID)
		comb = case(tiles.size)
			when (13*7) then "13x7"
			when (7*4) then  "7x4"
		end
		# 13(0...12) * 7 (0...6)
		cmd = "montage "
		cmd << tiles.join(" ")
		cmd << " -geometry +0+0 -tile #{comb} pano-#{panoID}.jpg"

		# X - overlapp if zoom < 3
		# width = 3584 - 256
		width = 6656

		# Y - black before 256 if zoom = 4  384 if zoom = 3
		height = 3584 - 256 #384

 		 Subexec.run cmd, :timeout => 0
 		cmd = "convert pano-#{panoID}.jpg  -crop #{width}x#{height}+0+0  pano-#{panoID}.jpg"
 		 Subexec.run cmd, :timeout => 0

 		#final=combined.crop(0, 0, combined.columns-190, combined.rows-220, true)
	end

	def download_tile(zoom, x, y, panoID)
		url = "http://cbk1.google.com/cbk?output=tile&zoom=#{zoom}&x=#{x}&y=#{y}&v=4&panoid=#{panoID}"
		resp = Net::HTTP.get_response(URI.parse(url))
		filename = "#{@dir_path}/tile-#{panoID}-#{x}-#{y}.jpg"
  	open(filename, 'wb') do |file|
    	file.write(resp.body)
  	end

  	filename
	end

end