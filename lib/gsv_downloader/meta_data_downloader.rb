require "typhoeus"
# require 'faraday_middleware'
# require 'typhoeus/adapters/faraday'

class MetaDataDownloader

#	BASE_URL = "https://cbks1.google.com/cbk?output=json&it=all&dmz=1&pmz=1&v=4&cb_client=apiv3&hl=en-US&oe=utf-8&token=78246"

	BASE_URL = "https://cbks1.google.com/cbk?output=json&v=4&cb_client=apiv3&hl=en-US&oe=utf-8"


	def initialize( include_depth = false)

		@base_url = if include_depth
			"#{BASE_URL}&dmz=1&pmz=1"
		else
			BASE_URL
		end

		#    # Typhoeus::Config.memoize = false
	  # @conn = Faraday.new(:url => "http://cbk1.google.com") do |faraday|
	  #    faraday.request :retry
	  #    faraday.response :raise_error
	  #    faraday.response :json #:content_type => /\bjson$/
	  #    faraday.adapter  :typhoeus
	  #  end
		@hydra = Typhoeus::Hydra.new
	end

	def start()
		@hydra.run
	end

	# enqueue a download
  def download(panoID)

    url = "#{@base_url}&panoid=#{panoID}"
    # p panoID
    # p url
		request = Typhoeus::Request.new(url, headers: {
			'User-Agent' => "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.10) Gecko/20100915 Ubuntu/10.04 (lucid) Firefox/3.6.10",
			"accept-charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3" })

    request.on_complete do |response|

    	if response.success?
      # Process the links in the response.
      	yield(response.body)
      else
         raise Exception.new("error to get meta_data of #{panoID} (response code #{response.code})")
      end
    end
    @hydra.queue request
  end

  def download_batch(panoIDs)
		@hydra = Typhoeus::Hydra.new
		panoIDs.each do |panoID|
			download(panoID)
		end
		start()
	end
end