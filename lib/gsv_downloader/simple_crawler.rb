# Load libraries
require 'time'
require "typhoeus"
require 'json'
require 'faraday_middleware'
require 'typhoeus/adapters/faraday'

class SimpleCrawler

  def initialize (area_validator, db)
    # Typhoeus::Config.memoize = false
  	@conn = Faraday.new(:url => "http://cbk1.google.com") do |faraday|
      faraday.request :retry
      faraday.response :raise_error
      faraday.response :json #:content_type => /\bjson$/
      faraday.adapter  :typhoeus
    end
    @hydra = Typhoeus::Hydra.new
  	@stats = Statistics.new
  	@db = db
    @area_validator = area_validator
    @max = 200
  end

  def start(pano_ids)
    pano_ids.each do |pano_id|
      crawl(pano_id)
    end
    @hydra.run
  end

  # Create a connection and its callback.
  def crawl_v2(panoID)

    @db.mark_to_crawl(panoID)

    # p panoID
    response =   @conn.get "/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=#{panoID}"

    process_panorama(response.body)
  end

  # Create a connection and its callback.
  def crawl(panoID)

    @db.mark_to_crawl(panoID)
    # p panoID
    url = "https://cbks1.google.com/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=#{panoID}"

    # p url
		request = Typhoeus::Request.new(url, headers: {
			'User-Agent' => "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.10) Gecko/20100915 Ubuntu/10.04 (lucid) Firefox/3.6.10",
			"accept-charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3" })

    request.on_complete do |response|
    	if response.success?
      # Process the links in the response.
      	process_panorama(response.body)
      else
          puts "ERRORORORO"
        p response

      end
    end
    @hydra.queue request
  end

private

  def extract_json(data)
    result = JSON.parse(data)
    raise "web service error" if result.has_key? 'Error'
    result
  end

  def extract_valid_links(json)
    json["Links"].each do |link_json|
      link_id = link_json["panoId"]
      if (link_json["scene"] == "0") and (@db.to_crawl?(link_id)) and (!@db.crawled?(link_id))
        yield(link_id)
      end
    end
  end

  def process_panorama(response)
  	json = extract_json(response)

		panoID = json["Location"]["panoId"]

     unless @db.crawled?(panoID)
      @db.mark_as_crawled(panoID)

      @stats.count

   		# inside the area to scrawl?
      if @area_validator.call(json)

        @db.add_pano(panoID, response)

        # for each valid and new link
        extract_valid_links(json) do |link_id|
          crawl(link_id)
        end
      end
    else
      puts "already crawled #{panoID}"
    end
  end
end