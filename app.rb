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
    res = BTCData.get_ohlc options
    Config::DENSITIES.each do |density|
      data = res[density]
      outfile = "data/#{options[:market]}_#{options[:pair]}_#{BTCData.date_prefix()}_ohlc_#{density}.csv"
      BTCData.save_csv data, outfile
    end
  end
end
