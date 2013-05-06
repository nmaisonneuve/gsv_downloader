
# load all files from gsv_cutter directory
path = File.expand_path(File.join(File.dirname(__FILE__), "gsv_downloader"))
$LOAD_PATH << path
Dir[ File.join(path, "*.rb") ].each { |file|
	require File.basename(file)
}