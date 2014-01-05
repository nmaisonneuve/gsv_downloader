Google Street View Downloader

## Description ##
Crawl and save Google Street view network (metadata + images) of a given geographical area. The metadata are saved into a redis db and the image in a directory
(speed: meta_data of 200 locations processed / second  (= the complete meta_data of all the images of Paris are crawled in about 10 mins. for the images, it depends on the image zoom you set)


## requirement ##
you need to install 
- [http://redis.io redis] as light database
- [http://www.imagemagick.org/ imagemagick]  


## install on Ubunutu / Linux ##

ruby install 
https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-ubuntu-12-04-lts-precise-pangolin-with-rvm

redis install
https://www.digitalocean.com/community/articles/how-to-install-and-use-redis


## install on Mac ##

brew install redis

brew install imagemagick


## example ##
```ruby
require 'rubygems'
require 'gsv_downloader'

# first we define a function to delimite the geographical area to crawl
# It stops to crawl further links when the area_validator return false
# @param json_response  = the metadata received from of a PanoID (json)
# @return false or true whether this panoID is valid or not
area_validator = lambda { |json_response|
		description = json_response["Location"]["region"]
		!description[/Paris/].nil?
}

# basic/required crawling options
options = {

	# area name
	area_name: "paris",

	# area validator to delimit the crawling within a given area
	area_validator: area_validator ,
}

# more advanced options
options = {

	# area name
	area_name: "paris",

	# area validator to delimit the crawling within a given area
	area_validator: area_validator ,

	# zoom level of the panoramic images saved
	image_zoom: 3, # default value = 3

	# main directory where the images will be downloaded
	dest_dir: "./paris",  # default value = "./{area_name}"

	# nb of images for each subdirectory
	# (since lots of images can be downloaded
	# automatic subdirectories are generated)
	sub_dir_size: 100 # default value = 1000
}

paris_area  = GSVManager.new(options)

# crawl and save the metadata of all GSV images
# within the area delimited by the area_validator.
# The first crawl needs the panoID of a location
# https://cbks0.google.com/cbk?output=json&dm=1&pm=1&v=4&cb_client=maps_sv&fover=2&onerr=3&panoid=Np2alC97cgynvV_ZpJQZNA
# Speed 200 meta_data processed / seconds  (= Paris is crawled in 10 mins)
start_panoID = "Np2alC97cgynvV_ZpJQZNA"
paris_area.crawl_metadata(start_panoID)

# number of saved panoramas (meta_data) within this area
paris_area.nb_panoramas()

# get the raw json metadata related to each saved panoID
pano_ids = paris_area.panoramas()
pano_ids.each do |pano_id|
	meta_data = paris_area.get_meta_data(panoID)
	p JSON.parse(meta_data)
end

# download manually each related GSV image
img_downloader = ImageDownloader.new
pano_ids.each do |pano_id|
	img_downloader.download(pano_id)
	# or with specific options zoom_level = 4, dest_dir = "./foo"
	# paris_area.download_image(pano_id, zoom_level, dest_dir)
end

# parallel/multi-thread pool version, much faster
# download GSV images in parallel
img_downloader = ImageDownloaderParallel.new
pano_ids.each do |pano_id|
	img_downloader.download(pano_id)
end
img_downloader.start()

# or let the manager find out the all missing images to download
# and organise the download directory
paris_area.download_images()
```
