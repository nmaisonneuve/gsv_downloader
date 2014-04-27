require 'json'
require 'meta_data_downloader.rb'

class Crawler

  def initialize (area_validator, db)
    @metadata_downloader  = MetaDataDownloader.new
  	@stats = Statistics.new
  	@db = db
    @area_validator = area_validator
    @max = 200
    @bootrap_mode = true
  end

  def start(pano_ids, force = false)
    
    if (pano_ids.size == 1)
      @bootrap_mode = true 
    else 
      @bootrap_mode = false
    end
    
    pano_ids.each do |pano_id|
      crawl(pano_id, force)
    end

    @metadata_downloader.start()  
  end

  def crawl(panoID, force = false)

    @db.mark_to_crawl(panoID)
    if (@bootrap_mode)
      nb = @db.to_crawl_count()      
      if ( nb > @max)
        return 
      end
    end
    @metadata_downloader.download(panoID) do | response|

      json = extract_json(response)
      panoID = json["Location"]["panoId"]
      @stats.count

      if ((!@db.crawled?(panoID)) || force)
        @db.mark_as_crawled(panoID)
        #p json
        # if inside the area
     
        if @area_validator.call(json)
          @db.add_pano(panoID, response) #TODO to save to save or whatever

          # for each valid and new link, crawl it
          extract_valid_links(json) do |link_id|
            # puts "link #{link_id} put in the queue"
            crawl(link_id)
          end
        else
          # puts "-- Area not valid";
        end
      end
    end
  end

private

  def extract_json(data)
    result = JSON.parse(data)
    #p result
    raise "web service error" if result.has_key? 'Error'
    result
  end

  def extract_valid_links(json)
    json["Links"].each do |link_json|
      link_id = link_json["panoId"]
      # puts "links : #{link_id}"
      if (link_json["scene"] != "1") and (@db.to_crawl?(link_id)) and (!@db.crawled?(link_id))
        yield(link_id)
      end
    end
  end
end