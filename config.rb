$LOAD_PATH << "./lib"

def change_symbol hash, sym, tsym=nil
  new_hash = hash.clone
  new_hash[:symbol] = sym
  if new_hash.has_key? :open
    new_hash[:open]["symbol"] = tsym
  end
  new_hash
end

module Targets
  # Define here the targets

  @bitfinexbook = {
    :url => "wss://api.bitfinex.com/ws/2",
    :name => "bitfinex",
    :symbol => "btcusd",
    :function => "orderbook",
  }

  @bitfinextrades = {
    :url => "wss://api.bitfinex.com/ws/2",
    :name => "bitfinex",
    :symbol => "btcusd",
    :function => "trades",
  }

  @bitmexbook = {
    :url => "wss://www.bitmex.com/realtime",
    :name => "bitmex",
    :symbol => "btcusd",
    :function => "orderbook",
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
