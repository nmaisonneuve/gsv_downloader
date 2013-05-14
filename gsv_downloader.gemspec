
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gsv_downloader/version'

Gem::Specification.new do |spec|
  spec.name          = "gsv_downloader"
  spec.version       = GSVDownloader::VERSION
  spec.authors       = ["nicolas maisonneuve"]
  spec.email         = ["n.maisonneuve@gmail.com"]
  spec.description   = %q{Crawl and save Google Street view network (metadata + images) of a given geographical area. The metadata are saved into a redis db and the image in a directory}
  spec.summary       = %q{GSV Downloader}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
