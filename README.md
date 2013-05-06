Google Street View Downloader

## installation ##

Require redis http://redis.io as light database

gem install gsv_downloader

```ruby
require 'gsv_downloader'

options = {

	# area name
	area_name: "paris",

	# area validator to delimit the scrawling to a given area
	area_validator: lambda { |json_response|
		description = json_response["Location"]["region"]
		description[/Paris/].nil? == false
		},

	# zoom level of the panoramic images
	image_zoom: 3,

	# main directory where the images will be downloaded
	dest_dir: "./paris",

	# number of images in a subdirecty
	# since lots of images can be downloaded
	# automatic subdirectories are generated
	sub_dir_size: 1000
}


paris_area  = GSVManager.new(options)

# scrawl and save the metadata of GSV images geolocated within an Area.
# It uses a depth-first navigation of the street network provided by the GSV metadata.
# It stops to scrawl futher links when the area_validator return a false response 
# (see the area validator function in the options).
# The scrawler needs a start point starts from the panoID = "Y76d7989a9A9x9".

paris_area.scrawl_metadata("Y76d7989a9A9x9")

# number of panoramas saved for this area
paris_area.nb_panoramas()

# Array of of panora IDs
pano_ids = paris_area.list_pano_ids()

# get the metadata related to each panoID
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
