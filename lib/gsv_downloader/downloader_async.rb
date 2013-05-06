require "typhoeus"
require "downloader.rb"

##
# Google Street View Images Downloader
# Multi-thread version for downlaoding tiles

# Google Street View Image Downloader
# Asynchronous version
class DownloaderAsync < Downloader

	def download_tiles(panoID, zoom_level)

		data = []
		get_tiles(zoom_level) do |x, y|
			data << {
				url: "http://cbk1.google.com/cbk?output=tile&zoom=#{zoom_level}&x=#{x}&y=#{y}&v=4&panoid=#{panoID}",
				filename: "#{@tmp_path}/tile-#{panoID}-#{x}-#{y}.jpg"
			}
		end

		hydra = Typhoeus::Hydra.new()
		data.each do | datum|
			request = Typhoeus::Request.new(datum[:url])
			request.on_complete do |response|
				process_response(response, datum[:filename])
    	end
    	hydra.queue request
		end
		hydra.run

		tiles_filename = data.collect{ |datum| datum[:filename]}
		tiles_filename
	end

	def process_response(response, filename)
		if response.success?
	    open(filename, 'wb') do |file|
	    	file.write(response.body)
	  	end
	  	#puts "downloaded tile  x=#{x},y=#{y}"
	  else
	    raise Exception.new("tile #{x}-#{y} not downloaded")
	  end
	end
end