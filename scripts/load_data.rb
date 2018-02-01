require 'pg'

$LOAD_PATH << '../lib/tools'
require 'files'
require 'dbmethods'
require 'yaml'

datadir = ARGV[0]

feedfiles = Dir.glob(File.join(datadir,"*feed.csv")).map {|x| File.basename x}

feedfiles = feedfiles.select {|x| BTCData::Files.patt.match(x)['function']=='orderbook' }

config = YAML.load_files("secrets.yml")

conn = PG.connect(config["db"])

# MAIN
feedfiles.each do |filename|
  id = BTCData::DB.add_orderbook conn, filename
end
