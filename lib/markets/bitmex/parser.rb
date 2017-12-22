require 'btcdata'



module BTCData
  module Bitmex
    class Parser
      def initialize feed_object, exchange_name, save_dir
        # TODO: Define a better accessor for id_mappings, i.e. avoid halting
        # in case an id is missing
        @id_mappings = {}
        @feed_object = feed_object
        @ready = false
        @exchange_name = exchange_name
        @save_dir = save_dir
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
        bitmex_orderbook_snapshot.time = @feed_object.time

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

        bitmex_orderbook_snapshot.save_csv @save_dir

        @ready = true
      end

      def update_id_mappings data
        if data.kind_of? Array
          data.each do |x|
            @id_mappings[x["id"]] = x["price"]
          end
        else
          @id_mappings[data["id"]] = data["price"]
        end
      end

      def parse_update action, data
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
          sign = -1
        else
          sign = 1
        end

        @feed_object.append [ price, sign * data["size"]]
      end

      def delete_id data
        @id_mappings.delete data["id"]
      end
    end
  end
end

