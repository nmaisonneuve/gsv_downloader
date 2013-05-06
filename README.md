Google Street View Downloader

## installation ##

Require redis http://redis.io as light database

gem install gsv_downloader

require 'gsv_downloader'


client  = GSVManager.new

options =  {
	pano_ids: ["Np2alC97cgynvV_ZpJQZNA"],
 	zoom_level: 4,
 	dest_dir: "./images"
}

client.download_images(options)