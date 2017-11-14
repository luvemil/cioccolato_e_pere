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
      :market => "bitfinex",
      :pair => "btcusd",
      :periods => DENSITIES
    }
  ]

end

if __FILE__ == $0
  res = BTCData.get_ohlc App::OHLC_SOURCES[0]
  App::DENSITIES.each do |density|
    data = res[density]
    outfile = "btcusd-perpetual-futures_#{BTCData.date_prefix()}_ohlc_#{density}.csv"
    BTCData.save_csv data, outfile
  end
end
