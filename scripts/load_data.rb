require 'pg'

$LOAD_PATH << '../lib/tools'
require 'files'
require 'yaml'

datadir = ARGV[0]

feedfiles = Dir.glob(File.join(datadir,"*feed.csv")).map {|x| File.basename x}

config = YAML.load_files("secrets.yml")

conn = PG.connect(config["db"])

# MAIN
feedfiles.each do |filename|

end
