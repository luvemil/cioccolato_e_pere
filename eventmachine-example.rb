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

live_dir = "live_feed"
snap_dir = "pre_snap"

[live_dir, snap_dir].each do |out_dir|
  Dir.mkdir(out_dir) unless Dir.exist? out_dir
end

bitfinex_orderbook_feed = BTCData::FeedSlice.new "bitfinex", "btcusd", "orderbook", live_dir
bitfinex_orderbook_feed.data["feed"] = %W[Timestamp Price Count Amount]

EM.run {
  #[@bitmex, @bitfinex].each do |exchange|
  [@bitfinex].each do |exchange|
    ws = Faye::WebSocket::Client.new(exchange[:url])

    ws.on :open do |event|
      p [:open]
      ws.send(JSON.dump(exchange[:open]))
    end

    ws.on :message do |event|
      b = JSON.parse(event.data)
      #p [:message, exchange[:name], b]

      # START: parsing data
      data = b[1]
      if data.kind_of? Array and data.size == 3 and not data.kind_of? String
        # Case: update
        bitfinex_orderbook_feed.append data
      elsif data.kind_of? String
        # Case: heartbeat
        p [:message, exchange[:name], b]
      elsif data.kind_of? Array
        # Case: snapshot
        bitfinex_orderbook_snapshot = BTCData::BookSlice.new exchange[:name], "BTCUSD"
        bitfinex_orderbook_snapshot.data["asks"] = data.select {|x| x[2] < 0}
        bitfinex_orderbook_snapshot.data["bids"] = data.select {|x| x[2] > 0}
        bitfinex_orderbook_snapshot.time = bitfinex_orderbook_feed.time
        bitfinex_orderbook_snapshot.save_csv live_dir
      end
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end
}
