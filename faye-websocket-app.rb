require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'config'
require 'btcdata'

Dotenv.load

require 'faye/websocket'
require 'eventmachine'

@url = "wss://www.bitmex.com/realtime"
@bitfinex = "wss://api.bitfinex.com/ws/2"

EM.run {
  ws = Faye::WebSocket::Client.new(@bitfinex)

  ws.on :open do |event|
    p [:open]
#     ws.send(JSON.dump({
#       "op" => "subscribe",
#       "args" => ["orderBookL2"]
#     }))
    ws.send(JSON.dump({
      "event" => "subscribe",
      "channel" => "book",
      "symbol" => "tBTCUSD",
      "prec" => "P0",
      "freq" => "F0",
      "len" => "25"
    }))
  end

  ws.on :message do |event|
    p [:message, JSON.parse(event.data)]
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
