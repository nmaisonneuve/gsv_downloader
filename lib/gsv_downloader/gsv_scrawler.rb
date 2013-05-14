# Load libraries
require 'time'
require "typhoeus"

class GSVScrawler

  def initialize (regexp = /Paris/)
  	@hydra = Typhoeus::Hydra.new()
  	@stats = Statistics.new
    @regexp_location_filter = regexp
  end

  def start( panoID = nil)
	  if panoID.nil?
	    unprocessed = Pano.where(:processed_at => nil)
	    puts "#{unprocessed.count} unprocessed panorama"
	    unprocessed.each { |pano| scrawl(pano.panoID) }
	  else
	    scrawl(panoID)
	  end
	  @hydra.run
  end

  # Create a connection and its callback.
  def crawl(panoID)
    url = "https://cbks0.google.com/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=#{panoID}"
    #p url
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

 		# inside the area to scrawl?
    if inside_area?(json)
    	pano = Pano.find_or_create_by_panoID(panoID)
    	# not processed yet?
    	if pano.processed_at.nil?
    		@stats.count #for debug
	    	update_panorama(pano, json).each do |link_id|
	    		# scrawl if not processed yet?
	    		scrawl(link_id) if Pano.find_or_create_by_panoID(link_id).processed_at.nil?
	     	end
	    end
    end
  end

  def inside_area?(json_data)
    area_validator.call(json_data)
  end

  def update_panorama(pano, json)
  	# we collect only links of outside scenes (scene ==0), not inside scenes (scene =1)
  	links_ids = []
  	json["Links"].each { |link_json|
  		links_ids << link_json["panoId"] if link_json["scene"] == "0"
  	}

  	date = json["Data"]["image_date"]
  	unless date.nil?
  		date = Date.strptime(date, '%Y-%m')
  	else
  		puts "---NO DATE-- "
  		p "https://cbks0.google.com/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=#{pano.panoID}"
    #p url
  	end

  	pano.update_attributes({
	  	image_date: date,
	    yaw_deg: json["Projection"]["pano_yaw_deg"].to_f,
	    original_latlng: "POINT (#{json["Location"]["original_lng"]} #{json["Location"]["original_lat"]})",
	    num_zoom_level: json["Data"]["description"],
	    latlng: "POINT (#{json["Location"]["lng"]} #{json["Location"]["lat"]})",
	    elevation: json["Location"]["elevation_wgs84_m"].to_f,
	    description: json["Location"]["description"],
	    street: json["Location"]["streetRange"],
	    region: json["Location"]["region"],
	    country: json["Location"]["country"],
	    raw_json: json,
	    links: links_ids.join(","),
	    processed_at: Time.now
	  })
	  links_ids
  end

  def extract_json(data)
    result = JSON.parse(data)
    raise "web service error" if result.has_key? 'Error'
    result
  end
end