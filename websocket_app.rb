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

client = Bitfinex::Client.new

options = {
  :market => "bitfinex",
  :pair => "btcusd",
}

live_dir = "live_feed"
snap_dir = "pre_snap"

[live_dir, snap_dir].each do |out_dir|
  Dir.mkdir(out_dir) unless Dir.exist? out_dir
end

ticker_feed = BTCData::FeedSlice.new options[:market], options[:pair], "ticker", "live_feed"
book_feed = BTCData::FeedSlice.new options[:market], options[:pair], "book", live_dir
book_feed.data["feed"] = %W[Timestamp Price Count Amount]
trades_feed = BTCData::FeedSlice.new options[:market], options[:pair], "trades", live_dir
trades_feed.data["feed"] = %W[Timestamp te/u Id Mts Amount Price]

client.listen_book do |b|
  if b[1].kind_of?(Array) and b[1].size == 3 and not b[1].kind_of?(String)
    b = b[1]
    book_feed.append b
  else
    book_snapshot = BTCData::BookSlice.new options[:market], options[:pair]
    book_snapshot.data["asks"] = b[1].select {|x| x[2] < 0}
    book_snapshot.data["bids"] = b[1].select {|x| x[2] > 0}
    book_snapshot.time = book_feed.time
    book_snapshot.save_csv live_dir
  end
end

client.listen_trades do |b|
  if b.size == 3
    data_a = b[2]
    data_a.unshift b[1]
    trades_feed.append data_a
  else
    trades_snapshot = BTCData::TradeSlice.new options[:market], options[:pair]
    trades_snapshot.data["trades"] = b[1]
    trades_snapshot.time = trades_feed.time
    trades_snapshot.save_csv live_dir
  end
end

Config::BOOK_SOURCES.each do |options|
  new_slice = BTCData::BookSlice.new options[:market], options[:pair]
  new_slice.read_response BTCData.get_orderbook(options)
  new_slice.save_csv snap_dir

  trade_slice = BTCData::TradeSlice.new options[:market], options[:pair]
  options[:function] = "trades"
  trade_slice.read_response BTCData.get_function(options)
  trade_slice.save_csv snap_dir
end

client.listen!
