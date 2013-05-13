
Google Street View Downloader

## Description ##
Crawl and save Google Street view network (metadata + images) of a given geographical area. The metadata are saved into a redis db and the image in a directory


## installation ##
[http://redis.io redis] as light database

gem install gsv_downloader

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
paris_area.crawl_metadata("Np2alC97cgynvV_ZpJQZNA")

# number of saved panoramas (meta_data) within this area
paris_area.nb_panoramas()

# get the raw json metadata related to each saved panoID
pano_ids = paris_area.list_panoids()
pano_ids.each do |pano_id|
	meta_data = paris_area.get_meta_data(panoID)
	p JSON.parse(meta_data)
end

# download manually each related GSV image
pano_ids.each do |pano_id|
	paris_area.download_image(pano_id)
	# or with specific options zoom_level = 4, dest_dir = "./foo"
	# paris_area.download_image(pano_id, zoom_level, dest_dir)
end

# or let the manager find out the all missing images to download
# and organise the download directory
paris_area.download_images()

# you can also check the filename associated with each panoID
# the format of the filename is currently the following:
# filename =  {dest_dir}/{pano_id}_zoom_{zoom_level}.jpg
# if null , the images has not been downloaded
pano_ids.each do |pano_id|
	filename = paris_area.get_filename(panoID)
end
```
