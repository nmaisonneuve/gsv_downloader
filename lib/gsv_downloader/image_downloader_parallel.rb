require "typhoeus"
require "image_downloader.rb"

# Google Street View Image Downloader
# multi_thread version (get the tiles in a multithread way)
class ImageDownloaderParallel < ImageDownloader

	def download_tiles(panoID, zoom_level)

		# prepare the information for each tile
		data = []
		get_tiles(zoom_level) do |x, y|
			data << {
				url: "http://cbk1.google.com/cbk?output=tile&zoom=#{zoom_level}&x=#{x}&y=#{y}&v=4&panoid=#{panoID}",
				filename: "#{@tmp_path}/tile-#{panoID}-#{x}-#{y}.jpg"
			}
		end

		# process
		data.each do | datum|
			request = Typhoeus::Request.new(datum[:url])
			request.on_complete do |response|
				process_response(response, datum[:filename])
    	end
    	hydra.queue request
		end
		hydra.run

		data.collect{ |datum| datum[:filename]}
	end

	def process_response(response, filename)
		if response.success?
	    open(filename, 'wb') do |file|
	    	file.write(response.body)
	  	end
	  else
	    raise Exception.new("tile #{filename} not downloaded")
	  end
	end
end