require 'btcdata'
require 'markets/parser'



module BTCData
  module Bitfinex
    class Parser < BTCData::Parser
      def post_init
        @update_array_size = 3
      end

      def parse message
        # message should be JSON.parse(event.data) where event is the message
        # received from the websocket
        super message

        # START: parsing data
        data = message[1]
        if data.kind_of? Array and data.size == @update_array_size and not data.kind_of? String
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
        # Data is
        # [
        #   PRICE,
        #   COUNT,
        #   AMOUNT
        # ]
        bitfinex_orderbook_snapshot.data["asks"] = data.select {|x| x[2] < 0}
        bitfinex_orderbook_snapshot.data["bids"] = data.select {|x| x[2] > 0}
        bitfinex_orderbook_snapshot.time = @feed_object.time
        bitfinex_orderbook_snapshot.save_csv @save_dir
      end

    end

    class FundingParser < Parser
      def post_init
        @update_array_size = 4
      end

      def parse_snapshot data
        bitfinex_orderbook_snapshot = BTCData::BookSlice.new @exchange_name, "fusd"
        # Data is
        # [
        #   RATE,
        #   PERIOD,
        #   COUNT,
        #   AMOUNT
        # ]
        bitfinex_orderbook_snapshot.data["asks"] = data.select {|x| x[3] > 0}
        bitfinex_orderbook_snapshot.data["bids"] = data.select {|x| x[3] < 0}
        bitfinex_orderbook_snapshot.time = @feed_object.time
        bitfinex_orderbook_snapshot.save_csv @save_dir
      end
    end

    class TradesParser < Parser
      def post_init
        @update_array_size = 4
      end

      def parse message
        # message should be JSON.parse(event.data) where event is the message
        # received from the websocket
        super message

        # START: parsing data
        data = message[1]
        if message.kind_of? Array and message.size == 3
          # Case: Update
          if message[1] == "te"
            # Case: te
            data = message[2]
            @feed_object.append data
          end
        elsif message.kind_of? Array and message.size == 2 and not message[1].kind_of? String
          # Case: Snapshot
          data = message[1]
          parse_snapshot data
        end
      end

      def parse_snapshot data
        bitfinex_trades_snapshot = BTCData::TradesSlice.new @exchange_name, "btcusd"
        # Data is
        # [
        #   ID,
        #   MTS,
        #   AMOUNT,
        #   PRICE
        # ]
        bitfinex_trades_snapshot.data["trades"] = data
        bitfinex_trades_snapshot.time = @feed_object.time
        bitfinex_trades_snapshot.save_csv @save_dir
      end
    end
  end
end

