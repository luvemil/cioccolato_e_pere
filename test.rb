#!/usr/bin/env ruby
require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'config'
require 'btcdata'

Dotenv.load

Bitfinex::Client.configure do |conf|
  conf.use_api_v2
end

out_dir = "test_feed"

Dir.mkdir(out_dir) unless Dir.exist? out_dir

client = Bitfinex::Client.new

options = {
  :market => "bitfinex",
  :pair => "btcusd",
}

book_feed = BTCData::FeedSlice.new options[:market], options[:pair], "book", out_dir


client.listen_book do |b|
  if b[1].size == 3
    b = b[1]
    book_feed.append b
  else
    book_snapshot = BTCData::BookSlice.new options[:market], options[:pair]
    book_snapshot.data["asks"] = b[1].select {|x| x[2] < 0}
    book_snapshot.data["bids"] = b[1].select {|x| x[2] > 0}
    book_snapshot.time = book_feed.time
    book_snapshot.save_csv out_dir
  end
end

client.listen!
