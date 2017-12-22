require 'btcdata'



module BTCData
  module Bitfinex
    class Parser
      def initialize feed_object, exchange_name, save_dir
        @feed_object = feed_object
        @exchange_name = exchange_name
        @save_dir = save_dir
      end

      def parse message
        # message should be JSON.parse(event.data) where event is the message
        # received from the websocket

        # START: parsing data
        data = message[1]
        if data.kind_of? Array and data.size == 3 and not data.kind_of? String
          # Case: update
          @feed_object.append data
        elsif data.kind_of? String
          # Case: heartbeat
        elsif data.kind_of? Array
          # Case: snapshot
          parse_snapshot data
        end
      end

      def parse_snapshot data
        bitfinex_orderbook_snapshot = BTCData::BookSlice.new @exchange_name, "btcusd"
        bitfinex_orderbook_snapshot.data["asks"] = data.select {|x| x[2] < 0}
        bitfinex_orderbook_snapshot.data["bids"] = data.select {|x| x[2] > 0}
        bitfinex_orderbook_snapshot.time = @feed_object.time
        bitfinex_orderbook_snapshot.save_csv @save_dir
      end

    end
  end
end

