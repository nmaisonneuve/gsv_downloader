# Load libraries
require 'time'
require "typhoeus"
require 'json'

class SimpleCrawler

  def initialize (area_validator, db)
    #Typhoeus::Config.memoize = false
  	@hydra = Typhoeus::Hydra.new()
  	@stats = Statistics.new
  	@db = db
    @area_validator = area_validator
    @max = 200
  end

  def start(pano_ids)
    pano_ids.each do |pano_id|
      crawl(pano_id)
    end
    redis.subscribe(:queue) do |on|
      on.message do |channel, msg|
        crawl(panoID)
      end
    end

    @hydra.run
  end

  # Create a connection and its callback.
  def crawl(panoID)

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
      end
    end
    @hydra.queue request
  end

  def process_panorama(response)
  	json = extract_json(response)
		panoID = json["Location"]["panoId"]

    unless (@db.scrawled?(panoID))

      @db.mark_as_scrawled(panoID)

   		# inside the area to scrawl? and not processed yet?
      if @area_validator.call(json)
        @db.add_pano(panoID, response)
        @stats.count

        # for each valid and new link
    		json["Links"].each do |link_json|
  				link_id = link_json["panoId"]
          if (link_json["scene"] == "0") and (!@db.scrawled?(link_id))
            #$redis.publish()
           #@db.mark_to_scrawl(link_id)
  				 crawl(link_id)
          end
  			end
      end
    end
  end

  def extract_json(data)
    result = JSON.parse(data)
    raise "web service error" if result.has_key? 'Error'
    result
  end
end