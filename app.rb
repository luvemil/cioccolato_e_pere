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
      :pairs => [
        "btcusd-perpetual-futures",
        "btcusd-quarterly-futures"
      ],
      :densities => DENSITIES
    },
    {
      :market => "bitfinex",
      :pairs => [ "btcusd" ],
      :densities => DENSITIES
    }
  ]

end

if __FILE__ == $0
  res = BTCData.get_ohlc "bitmex","btcusd-perpetual-futures","300"
  data_300 = res['300']
  outfile = "btcusd-perpetual-futures_#{BTCData.date_prefix()}_ohlc_300.csv"
  BTCData.save_csv data_300, outfile
end
