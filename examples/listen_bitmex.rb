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

bitmex_orderbook_feed = BTCData::FeedSlice.new "bitfinex", "btcusd", "orderbook", live_dir
bitmex_orderbook_feed.append %W[Timestamp Price Count Amount]

class Parser
  def initialize feed_object, exchange_name, live_dir
    @id_mappings = {}
    @feed_object = feed_object
    @ready = false
    @exchange_name = exchange_name
  end

  def parse message
    if message["action"] == "partial"
      parse_snapshot message["data"]
    elsif
      if @ready
        data = message["data"]
        if data.kind_of? Array
          data.each do |update|
            parse_update message["action"], update
          end
        else
          parse_update message["action"], data
        end
      end
    end
  end

  def parse_snapshot data
    update_id_mappings data
    bitmex_orderbook_snapshot = BTCData::BookSlice.new @exchange_name, "btcusd"

    # The snapshot is divided in two tables of the form
    # [ Price, Amount ]
    # TODO: write a separate conversion table from ids to prices
    bitmex_orderbook_snapshot.data["asks"] = data.select {|x|
      x["side"] == "Sell"
    }.map { |x|
      [ x["price"], x["size"]]
    }

    bitmex_orderbook_snapshot.data["bids"] = data.select {|x|
      x["side"] == "Buy"
    }.map {|x|
      [ x["price"], x["size"]]
    }

    @ready = true
  end

  def update_id_mappings data
    data.each do |x|
      @id_mappings[x["id"]] = x["price"]
    end
  end

  def parse_update action, data
    p [:message, data]
    # Returns a row in a csv table of the form:
    # [Timestamp, Price, Ask/Bid, Amount]
    # Where Amount = 0 means that the offer is to be eliminated
    if action == "insert"
      update_id_mappings data
      price = data["price"]
    elsif action == "delete"
      data["size"] = 0
      price = @id_mappings[data["id"]]
      delete_id data
    else
      price = @id_mappings[data["id"]]
    end

    if data["side"]=="Sell"
      side = "ask"
    else
      side = "bid"
    end

    return [Time.now.tv_sec, price, side, data["size"]]
  end

  def delete_id data
    @id_mappings.delete data["id"]
  end
end

def log a
  @count ||= 0
  EM.stop if @count >= 4
  p a
  @count += 1
end

def bitfinex_parse event, exchange, bitfinex_orderbook_feed, live_dir
  b = JSON.parse(event.data)

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

bitmex_parser = Parser.new bitmex_orderbook_feed, "bitmex", live_dir

EM.run {
  #[@bitmex, @bitfinex].each do |exchange|
  [@bitmex].each do |exchange|
    ws = Faye::WebSocket::Client.new(exchange[:url])

    ws.on :open do |event|
      p [:open]
      ws.send(JSON.dump(exchange[:open]))
    end

    ws.on :message do |event|
      bitmex_parser.parse JSON.parse(event.data)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end
}
