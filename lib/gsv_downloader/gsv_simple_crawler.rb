# Load libraries
require 'time'
require "typhoeus"
require 'json'

class GSVSimpleScrawler

  def initialize (area_validator, db)
    #Typhoeus::Config.memoize = false
  	@hydra = Typhoeus::Hydra.new()
  	@stats = Statistics.new
  	@db = db
    @area_validator = area_validator
    @max = 200
  end

  def start(panoID)
		scrawl(panoID)
    @hydra.run
  end

  # Create a connection and its callback.
  def scrawl(panoID)
    # p panoID
    url = "https://cbks1.google.com/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=#{panoID}"
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

 		# inside the area to scrawl? and not processed yet?
    if @area_validator.call(json_data)
     # @db.add_pano(panoID, response)

     # @db.mark_as_scrawled(panoID)
     # @db.add_to_area(panoID)
      @stats.count
      @db.set_metadata(panoID, response) #unless (!@db.metadata_exists?(panoID))

      # for each valid and new link
  		json["Links"].each do |link_json|
				link_id = link_json["panoId"]
      #  if (link_json["scene"] == "0") and (!@db.scrawled?(link_id))
			#	  scrawl(link_id) if @stats.processed < @max
         scrawl("Np2alC97cgynvV_ZpJQZNA")
       #  end
			end
    end
  end

  def extract_json(data)
    result = JSON.parse(data)
    raise "web service error" if result.has_key? 'Error'
    result
  end
end