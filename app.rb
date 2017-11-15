require 'rest-client'
require 'addressable'
require 'json'
require 'csv'
require 'tools'

module App
  DENSITIES = [
    "60",
    "300",
    "3600"
  ]

  OHLC_SOURCES = [
    {
      :market => "bitmex",
      :pair => "btcusd-perpetual-futures",
      :periods => DENSITIES
    },
    {
      :market => "bitmex",
      :pair => "btcusd-quarterly-futures",
      :periods => DENSITIES
    },
    {
      :market => "bitfinex",
      :pair => "btcusd",
      :periods => DENSITIES
    }
  ]

end

if __FILE__ == $0
  App::OHLC_SOURCES.each do |options|
    res = BTCData.get_ohlc options
    App::DENSITIES.each do |density|
      data = res[density]
      outfile = "data/#{options[:market]}_#{options[:pair]}_#{BTCData.date_prefix()}_ohlc_#{density}.csv"
      BTCData.save_csv data, outfile
    end
  end
end
