require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'config'
require 'btcdata'

Dotenv.load


require 'json'
require 'eventmachine'
require 'faye/websocket'

# Setup output directories
live_dir = "live_feed"
snap_dir = "pre_snap"

[live_dir, snap_dir].each do |out_dir|
  Dir.mkdir(out_dir) unless Dir.exist? out_dir
end

# Setup exchange config hashes
@bitfinex = {
  :url => "wss://api.bitfinex.com/ws/2",
  :name => "bitfinex",
  :open => {
    "event" => "subscribe",
    "channel" => "book",
    "symbol" => "tBTCUSD",
    "prec" => "P0",
    "freq" => "F0",
    "len" => "25"
  }
}

@bitmex = {
  :url => "wss://www.bitmex.com/realtime",
  :name => "bitmex",
  :open => {
    "op" => "subscribe",
    "args" => ["orderBookL2:XBTUSD"]
  }
}


# Setup feeds
bitmex_orderbook_feed = BTCData::FeedSlice.new "bitmex", "btcusd", "orderbook", live_dir
bitmex_orderbook_feed.set_header %W[Timestamp Price Amount]


bitfinex_orderbook_feed = BTCData::FeedSlice.new "bitfinex", "btcusd", "orderbook", live_dir
bitfinex_orderbook_feed.set_header %W[Timestamp Price Count Amount]

# Setup parsers

bitmex_parser = BTCData::Bitmex::Parser.new bitmex_orderbook_feed, "bitmex", live_dir
@bitmex[:parser] = bitmex_parser

bitfinex_parser = BTCData::Bitfinex::Parser.new bitfinex_orderbook_feed, "bitfinex", live_dir
@bitfinex[:parser] = bitfinex_parser


# Main EventMachine thread
EM.run {
  [@bitmex, @bitfinex].each do |exchange|
    ws = Faye::WebSocket::Client.new(exchange[:url])

    ws.on :open do |event|
      p [:open, exchange[:name]]
      ws.send(JSON.dump(exchange[:open]))
    end

    ws.on :message do |event|
      data = JSON.parse(event.data)
      exchange[:parser].parse data
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end
}

# Helper methods

def log a
  @count ||= 0
  EM.stop if @count >= 4
  p a
  @count += 1
end

def manual_parse data
  if data["action"] == "update"
    if data["data"].kind_of? Array
      data["data"].each {|x| log [:message,"bitmex",x]}
    else
      log [:message,"bitmex",data]
    end
  end
  #log [:message, "bitmex", JSON.parse(event.data)]
end
