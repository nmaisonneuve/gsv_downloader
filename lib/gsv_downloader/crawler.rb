# Load libraries
require 'json'
require 'meta_data_downloader.rb'

class Crawler

  def initialize (area_validator, db)
    metadata_downloader  = MetaDataDownloader.new
  	@stats = Statistics.new
  	@db = db
    @area_validator = area_validator
    @max = 200
  end

  def start(pano_ids)
    pano_ids.each do |pano_id|
      crawl(pano_id)
    end
    metadata_downloader.start()
  end

  def crawl(panoID)
    @db.mark_to_crawl(panoID)
    metadata_downloader.download(panoID) do | response|

      json = extract_json(response)
      panoID = json["Location"]["panoId"]
      @stats.count

      unless @db.crawled?(panoID)
        @db.mark_as_crawled(panoID)

        # if inside the area
        if @area_validator.call(json)
          @db.add_pano(panoID, response) #TODO to save to save or whatever

          # for each valid and new link, crawl it
          extract_valid_links(json) do |link_id|
            crawl(link_id)
          end
        end
      end
    end
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
end