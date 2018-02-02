require 'btcdata'
require 'eventmachine'
require 'faye/websocket'


module BTCData
  module Market
    @@live_dir = "live_feed"
    def self.live_dir= value
      @@live_dir = value
    end
    def self.live_dir
      @@live_dir
    end

    def self.is_valid? hash
      if hash.kind_of? Hash
        [:name, :symbol, :function, :open].each do |key|
          if not hash.has_key? key
            return false
          end
        end
        if hash[:open].kind_of? Hash
          return true
        else
          return false
        end
      end
      return false
    end

    class Client
      attr_accessor :spec, :exchange, :parser, :symbol, :function, :live_dir
      def initialize exchange, symbol, function
        @exchange = exchange
        @symbol = symbol
        @function = function
        @live_dir = BTCData::Market.live_dir
        self.initial_setup
      end

      def run!
        if EM.reactor_running?
          @ws = Faye::WebSocket::Client.new(@url)

          @ws.on :open do |event|
            p [:open, @exchange]
            @ws.send(JSON.dump(@on_open))
          end

          @ws.on :message do |event|
            data = JSON.parse(event.data)
            @parser.parse data
          end

          @ws.on :close do |event|
            p [:close, event.code, event.reason]
            @ws = nil

            # Force restart in case of closure
            self.cleanup
            self.initial_setup
            self.run!
          end
        end
      end

      def initial_setup
        self.setup_feed
        self.setup_parser
      end

      def cleanup
        @parser.dump
      end

      def on_open hash
        @on_open = hash
      end

      def on_close hash
        @on_close = hash
      end

      def self.create_new hash_specs
        # hash_specs: {
        #   :name => exchange_name,
        #   :symbol => symbol_name,
        #   :function => function_name,
        #   :open => message to send on WebSocket::open,
        #   (optional) :close => message to send on WebSocket::close,
        #   (optional) :client => ClientClass
        # }
        unless BTCData::Market.is_valid? hash_specs
          p [:error, hash_specs]
          return 0
        end

        if hash_specs.has_key? :client
          client = hash_specs[:client].split('::').inject(Object) {|o,c| o.const_get c}.new hash_specs[:symbol], hash_specs[:function]
        else
          case hash_specs[:name]
          when "bitfinex"
            client = BTCData::Market::BitfinexClient.new hash_specs[:symbol], hash_specs[:function]
          when "bitmex"
            client = BTCData::Market::BitmexClient.new hash_specs[:symbol], hash_specs[:function]
          end
        end

        client.on_open hash_specs[:open]
        if hash_specs.has_key? :close
          client.on_close hash_specs[:close]
        end
        client
      end



      def setup_feed
        @feed =
          case @function
          when "orderbook"
            BTCData::FeedSlice.new @exchange, @symbol, "orderbook", @live_dir
          when "trades"
            BTCData::FeedSlice.new @exchange, @symbol, "trades", @live_dir
          end
        self.set_feed_headers
        self.post_setup_feed
      end

      def set_feed_headers
      end
      def post_setup_feed
      end

      def pre_setup_parser
        p "Setting up parser for #{@exchange}:#{@symbol}:#{@function}"
      end
      def setup_parser
      end
    end
    class BitfinexClient < BTCData::Market::Client
      def initialize symbol, function
        super "bitfinex", symbol, function
        @url = "wss://api.bitfinex.com/ws/2"
      end
      def set_feed_headers
        case @function
        when "orderbook"
          @feed.set_header %W[Timestamp Price Count Amount]
        when "trades"
          @feed.set_header %W[Timestamp Id MTS Amount Price]
        end
      end
      def setup_parser
        self.pre_setup_parser
        case @function
        when "orderbook"
          @parser = BTCData::Bitfinex::Parser.new @feed, @exchange, @live_dir
        when "trades"
          @parser = BTCData::Bitfinex::TradesParser.new @feed, @exchange, @live_dir
        end
      end
    end
    class BitmexClient < BTCData::Market::Client
      def initialize symbol, function
        super "bitmex", symbol, function
        @url = "wss://www.bitmex.com/realtime"
      end
      def set_feed_headers
        case @function
        when "orderbook"
          @feed.set_header %W[Timestamp Price Amount]
        when "trades"
          #TODO: add trades header here
        end
      end
      def setup_parser
        self.pre_setup_parser
        case @function
        when "orderbook"
          @parser = BTCData::Bitmex::Parser.new @feed, @exchange, @live_dir
        when "trades"
          #TODO: add trades parser
        end
      end
    end
  end
end

