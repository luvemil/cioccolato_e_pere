require 'json'
require 'eventmachine'
require 'faye/websocket'


@bitfinex = {
  :url => "wss://api.bitfinex.com/ws/2",
  :name => "Bitfinex",
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
  :name => "Bitmex",
  :open => {
    "op" => "subscribe",
    "args" => ["orderBookL2"]
  }
}


EM.run {
  [@bitmex, @bitfinex].each do |exchange|
    ws = Faye::WebSocket::Client.new(exchange[:url])

    ws.on :open do |event|
      p [:open]
      ws.send(JSON.dump(exchange[:open]))
    end

    ws.on :message do |event|
      p [:message, exchange[:name], JSON.parse(event.data)]
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end
}
