require "bundler/gem_tasks"
require "./lib/gsv_downloader.rb"

namespace :gsv do

	desc "download a specific image e.g. rake gsv:download_image panoid=Np2alC97cgynvV_ZpJQZNA zoom=3 dest=./images"
	task :image do
		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		zoom = ENV["zoom"] || "3"
		dest_dir = ENV["dest"] || "./images"

		downloader = ImageDownloaderParallel.new
		downloader.download(panoID,zoom.to_i,".")
	end

	desc "get the metadata of given panoID e.g. rake gsv:image panoid=Np2alC97cgynvV_ZpJQZNA"
	task :metadata do
		panoID = ENV["panoid"] || "Np2alC97cgynvV_ZpJQZNA"
		db = DBRedis.new
		p JSON.parse(db.get_metadata(panoID))
	end

	desc "get the metadata of given panoID e.g. rake gsv:image panoid=Np2alC97cgynvV_ZpJQZNA"
	task :metadata_list do
		require 'csv'
		downloader = MetaDataDownloader.new
		db = DBRedis.new
		CSV.foreach("../gsv_cutter/data/detections/pano_not_found.csv") do |row|
			downloader.download(row) do | response|
				panoID = JSON.parse(response)["Location"]["panoId"]
				puts "panoID found #{panoID}"
				db.add_pano(panoID, response)
			end
		end
		downloader.start()
	end

	desc "generate a kml of panorama images"
	task :kml do
  	options = {
			area_name: "A6"
		}

		manager = GSVManager.new(options)
		db = manager.get_db
		i = 0
		kml = "<?xml version='1.0' encoding='utf-8' ?><kml xmlns='http://www.opengis.net/kml/2.2'><Document>
			<Style id='MyStyle11'>
		<IconStyle>
			<color>ffbfc03f</color>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pal4/icon25.png</href>
			</Icon>
		</IconStyle>
		<LineStyle>
			<width>3.1</width>
		</LineStyle>
		<PolyStyle>
			<color>ffbfc03f</color>
		</PolyStyle>
	</Style>
	<Style id='MyStyle10'>
		<IconStyle>
			<color>ffbfc03f</color>
			<Icon>
				<href>http://maps.google.com/mapfiles/kml/pal4/icon25.png</href>
			</Icon>
		</IconStyle>
		<LineStyle>
			<width>3.1</width>
		</LineStyle>
		<PolyStyle>
			<color>ffbfc03f</color>
		</PolyStyle>
	</Style>
	<StyleMap id='MyStyle1'>
		<Pair>
			<key>normal</key>
			<styleUrl>#MyStyle10</styleUrl>
		</Pair>
		<Pair>
			<key>highlight</key>
			<styleUrl>#MyStyle11</styleUrl>
		</Pair>
	</StyleMap>"

		kml << "<Folder>
		<name>intensity</name>
		<visibility>0</visibility>
		<open>1</open>"
		manager.panoramas_index.each do |panoID|
			detection = db.get_metadata(panoID+":sign")
			p detection
			i += 1
			json = JSON.parse(manager.get_metadata(panoID))
			lat = json["Location"]["lat"]
			lng = json["Location"]["lng"]
			if (detection.to_i > 0)
			kml <<"<Placemark>
			<visibility>1</visibility>
			<styleUrl>#MyStyle1</styleUrl>
			<LineString>
				<extrude>1</extrude>
				<tessellate>1</tessellate>
				<altitudeMode>absolute</altitudeMode>
				<coordinates>#{lng},#{lat},#{400 * detection.to_i} "
				kml << "</coordinates></LineString></Placemark>"
			end
		end
		kml << "</Folder>"
		kml << "<Folder><name>points</name>"

		manager.panoramas_index.each do |panoID|
			detection = db.get_metadata(panoID+":sign")
			p detection
			i += 1
			json = JSON.parse(manager.get_metadata(panoID))
			lat = json["Location"]["lat"]
			lng = json["Location"]["lng"]
			if (detection.to_i > 0)
				kml <<"<Placemark>
				<name>t1</name>
				<description><img src='file:///Users/nico/work/data/images/A6/tile-#{panoID}-3-1.jpg'/>("+detection+")</description>
				<visibility>1</visibility>
				<styleUrl>#MyStyle1</styleUrl>
				<Point>
	    <coordinates>#{lng},#{lat},0</coordinates></Point></Placemark>"
  		end
		end

		kml << "</Folder></Document></kml>"
		File.open("test.kml", 'w') {|f| f.write(kml) }
		puts "#{i} panoID"
	end

	desc "stats"
	task :stats do
		area = ENV["area"] || "paris_v2"
		db = DBRedis.new (area)
		puts "nb of panorama in #{area}: #{db.nb_panoramas()}"
	end

	desc "crawl"
	task :crawl do
	 	# require 'perftools'
	  # PerfTools::CpuProfiler.start("tmp/add_numbers_profile") do
	  # end
	  badly_described_panos = ["eJyt9NHF8uWRIolpck6v9w",
	  "oINiMvJco2RzGZTC1Ib71g",
		"DmpdHWaTSdVS3d4tW4QkCg"]

	  area_validator = lambda { |json_response|
			panoID = json_response["Location"]["panoId"]
			if badly_described_panos.include?(panoID)
				true
			else
				description = json_response["Location"]["description"]
				p json_response["Location"]

				if description == ''
					true
				else
					description[/A6A/].nil? == false || description[/du Soleil/].nil? == false || description[/E15/].nil? == false || description[/E60/].nil? == false
				end
			end
		}

  	options = {
			area_name: "A6",
			area_validator: area_validator
		}

		manager = GSVManager.new(options)
		#manager.reset_crawl
		# Np2alC97cgynvV_ZpJQZNA
	   manager.crawl_metadata("DmpdHWaTSdVS3d4tW4QkCg", true)
		# manager.crawl_metadata()
	end


	desc "download all panoramas in parallel mode"
	task :download_all_images_par do
		area = "paris"
		x = 3
		y = 1
		zoom_level = 3
		data = []
		db = DBRedis.new("paris")
		db.images_to_download.each do |panoID|
			filename = "./images/#{area}/tile-#{panoID}-#{x}-#{y}.jpg"
			unless Pathname.new(filename).exist?
				data << {
					url: "http://cbk1.google.com/cbk?output=tile&zoom=#{zoom_level}&x=#{x}&y=#{y}&v=4&panoid=#{panoID}",
					filename: filename
				}
			end
		end
		puts " #{data.size} images to download"
		downloader = ImageDownloaderParallel.new
		downloader.parallel_download(data)
	end

	desc "download all panoramas"
	task :download_all_images do
		area = "paris"
		options = {
			area_name: area,
			zoom_level: 3,
			dest_dir: "./#{area}",
			sub_dir_size: 1000
		}
		#downloader = ImageDownloader.new
		manager = GSVManager.new(options)
		 manager.download_missing_images()
	end
end