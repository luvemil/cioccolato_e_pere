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
      # TODO: rewrite this method in a more understandable way
      if hash.kind_of? Hash
        [:name, :symbol, :function].each do |key|
          if not hash.has_key? key
            return false
          end
        end
        if hash.has_key? :open
          if hash[:open].kind_of? Hash
            return true
          else
            return false
          end
        else
          return true
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

      def initial_setup
        self.setup_feed
        self.setup_parser
      end

      def cleanup
        @parser.dump
      end

      def restart
        self.cleanup
        self.initial_setup
        self.run!
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

      def on_open= hash
        @on_open = hash
      end

      def on_close= hash
        @on_close = hash
      end

      def run!
        if EM.reactor_running?
          @ws = Faye::WebSocket::Client.new(@url)

          @ws.onopen = method(:ws_onopen)

          @ws.onmessage = method(:ws_onmessage)

          @ws.onclose = method(:ws_onclose)
        end
      end

      # START - definition of the websocket callbacks, can be redefined in children class
      # to have more functionality
      def ws_onopen event
        p [:open, @exchange]
        @ws.send(JSON.dump(@on_open))
      end

      def ws_onmessage event
        data = JSON.parse(event.data)
        @parser.parse data
        # TODO: add logic to check if the stream is still alive.
        # IDEAS: @parser.parse could return some data, e.g. could return true if the massage is an
        # hearthbeat in case the exchange supports it, and then force a channel ping/pong if last message
        # was too far in the past
      end

      def ws_onclose event
        p [:close, event.code, event.reason]
        @ws = nil

        # Force restart in case of closure
        self.restart
      end
      # END

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

        if hash_specs.has_key? :open
          client.on_open = hash_specs[:open]
        end
        if hash_specs.has_key? :close
          client.on_close = hash_specs[:close]
        end
        client
      end
    end

    class BitfinexClient < BTCData::Market::Client
      def initialize symbol, function
        super "bitfinex", symbol, function
        @url = "wss://api.bitfinex.com/ws/2"

        self.set_on_open symbol, function
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

      def set_on_open symbol, function
        req_symbol = "t#{symbol.upcase}"
        case function
        when "orderbook"
          @on_open = {
            "event" => "subscribe",
            "channel" => "book",
            "symbol" => req_symbol,
            "prec" => "P1",
            "freq" => "F0",
            "len" => "100"
          }
        when "trades"
          @on_open = {
            "event" => "subscribe",
            "channel" => "trades",
            "symbol" => req_symbol,
          }
        end
      end
    end

    class BitmexClient < BTCData::Market::Client
      def initialize symbol, function
        super "bitmex", symbol, function
        @url = "wss://www.bitmex.com/realtime"
        self.set_on_open symbol, function
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

      def set_on_open symbol, function
        case function
        when "orderbook"
          @on_open = {
            "op" => "subscribe",
            "args" => ["orderBookL2:XBTUSD"] #TODO change this request with a function
          }
        end
      end
    end
  end
end

