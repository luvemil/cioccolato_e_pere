$LOAD_PATH << "./lib"

def change_symbol hash, sym, tsym
  new_hash = hash.clone
  new_hash[:symbol] = sym
  new_hash[:open]["symbol"] = tsym
  new_hash
end

module Targets
  # Define here the targets

  @bitfinexbook = {
    :url => "wss://api.bitfinex.com/ws/2",
    :name => "bitfinex",
    :symbol => "btcusd",
    :function => "orderbook",
    :open => {
      "event" => "subscribe",
      "channel" => "book",
      "symbol" => "tBTCUSD",
      "prec" => "P1",
      "freq" => "F0",
      "len" => "100"
    },
    :close => {
      "event" => "unsubscribe"
    }
  }

  @bitfinextrades = {
    :url => "wss://api.bitfinex.com/ws/2",
    :name => "bitfinex",
    :symbol => "btcusd",
    :function => "trades",
    :open => {
      "event" => "subscribe",
      "channel" => "trades",
      "symbol" => "tBTCUSD",
    },
    :close => {
      "event" => "unsubscribe"
    }
  }

  @bitmexbook = {
    :url => "wss://www.bitmex.com/realtime",
    :name => "bitmex",
    :symbol => "btcusd",
    :function => "orderbook",
    :open => {
      "op" => "subscribe",
      "args" => ["orderBookL2:XBTUSD"]
    }
  }
  @targets = [
    @bitfinexbook,
    @bitfinextrades,
    change_symbol(@bitfinexbook, "ethusd", "tETHUSD"),
    change_symbol(@bitfinextrades, "ethusd", "tETHUSD"),
    @bitmexbook
  ]

  def self.targets
    @targets
  end
end



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
