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
  :function => "orderbook",
  :open => {
    "event" => "subscribe",
    "channel" => "book",
    "symbol" => "tBTCUSD",
    "prec" => "P0",
    "freq" => "F0",
    "len" => "25"
  },
  :close => {
    "event" => "unsubscribe"
  }
}

@bitfinextrades = {
  :url => "wss://api.bitfinex.com/ws/2",
  :name => "bitfinex",
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

@bitmex = {
  :url => "wss://www.bitmex.com/realtime",
  :name => "bitmex",
  :function => "orderbook",
  :open => {
    "op" => "subscribe",
    "args" => ["orderBookL2:XBTUSD"]
  }
}

# Setup parsers

def setup_parser exchange, live_dir, function="orderbook"
  if function == "orderbook"
    feed = BTCData::FeedSlice.new exchange, "btcusd", "orderbook", live_dir
    if exchange == "bitmex"
      feed.set_header %W[Timestamp Price Amount]
      parser = BTCData::Bitmex::Parser.new feed, "bitmex", live_dir
    elsif exchange == "bitfinex"
      feed.set_header %W[Timestamp Price Count Amount]
      parser = BTCData::Bitfinex::Parser.new feed, "bitfinex", live_dir
    end
  elsif function == "trades"
    feed = BTCData::FeedSlice.new exchange, "btcusd", "trades", live_dir
    if exchange == "bitfinex"
      feed.set_header %W[Timestamp Id MTS Amount Price]
      parser = BTCData::Bitfinex::TradesParser.new feed, "bitfinex", live_dir
    end
  end
  return parser
end

@bitmex[:parser] = setup_parser "bitmex", live_dir
@bitfinex[:parser] = setup_parser "bitfinex", live_dir
@bitfinextrades[:parser] = setup_parser "bitfinex", live_dir, "trades"


def run_websocket exchange
  if EM.reactor_running?
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

      # Force restart in case of closure
      exchange[:parser] = setup_parser exchange[:name], exchange[:parser].save_dir, exchange[:function]
      run_websocket exchange
    end
  end
end

# Main EventMachine thread
EM.run {
  [@bitfinextrades,@bitfinex,@bitmex].each do |exchange|
    run_websocket exchange
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
