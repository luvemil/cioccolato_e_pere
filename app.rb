require 'rest-client'
require 'addressable'
require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'tools'
require 'config'

if __FILE__ == $0
  Config::OHLC_SOURCES.each do |options|
    new_slice = BTCData::OhlcSlice.new options[:market], options[:pair]
    new_slice.read_response BTCData.get_ohlc(options)
    new_slice.save_csv "data"
  end
  Config::BOOK_SOURCES.each do |options|
    new_slice = BTCData::BookSlice.new options[:market], options[:pair]
    new_slice.read_response BTCData.get_orderbook(options)
    new_slice.save_csv "data"
  end
end
