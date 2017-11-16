#!/usr/bin/env ruby
require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'tools'
require 'config'

Dotenv.load

Bitfinex::Client.configure do |conf|
  conf.secret = ENV['BFX_API_SECRET']
  conf.api_key = ENV['BFX_API_KEY']
end

client = Bitfinex::Client.new

options = {
  :market => "bitfinex",
  :pair => "btcusd",
}

account_feed = BTCData::FeedSlice.new options[:market], options[:pair], "account", "live_feed"
ticker_feed = BTCData::FeedSlice.new options[:market], options[:pair], "ticker", "live_feed"
book_feed = BTCData::FeedSlice.new options[:market], options[:pair], "book", "live_feed"
trades_feed = BTCData::FeedSlice.new options[:market], options[:pair], "trades", "live_feed"


client.listen_account do |c|
  account_feed.append c
end

client.listen_ticker do |t|
  ticker_feed.append t
end

client.listen_book do |b|
  book_feed.append b
end

client.listen_trades do |b|
  trades_feed.append b
end

Config::BOOK_SOURCES.each do |options|
  new_slice = BTCData::BookSlice.new options[:market], options[:pair]
  new_slice.read_response BTCData.get_orderbook(options)
  new_slice.save_csv "live_feed"

  trade_slice = BTCData::TradeSlice.new options[:market], options[:pair]
  options[:function] = "trades"
  trade_slice.read_response BTCData.get_function(options)
  trade_slice.save_csv "live_feed"
end

client.listen!
