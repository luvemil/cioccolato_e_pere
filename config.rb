module Config
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

  BOOK_SOURCES = [
    {
      :market => "bitfinex",
      :pair => "btcusd"
    }
  ]
end
