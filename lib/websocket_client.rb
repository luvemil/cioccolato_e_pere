require 'faye/websocket'
require 'JSON'


module BTCData
  module Websocket
    class Client
      def initialize(options = {})
        # options = {
        #   :url => "<websocket url>",
        #   :name => "<exchange name>",
        #   :open => {
        #     [message to send on open to the stream]
        #   }
        # }
        @url = options[:url]
        @name = options[:name]
        @onopen_msg = options[:open]
      end

      def run!
        if EM.reactor_running?
          connect!
        else
          EM.run { connect! }
        end
      end

      def connect!
        @ws = Faye::WebSocket::Client.new(@url)

        @ws.onopen = method(:ws_onopen)
        @ws.onmessage = method(:ws_onmessage)
        @ws.onclose = method(:ws_onclose)
        @ws.onerror = method(:ws_onerror)
      end

      private
      def ws_onopen event
        p [:open, @name]
        @ws.send(JSON.dump(@onopen_msg))
      end

      def ws_onmessage event
        data = JSON.parse(event.data)
        # TODO: add a parser object somewhere
        @parser.parse data
      end

      def ws_onclose event
        p [:close, event.code, event.reason]
        @ws = nil

        # Force restart in case of closure
        # TODO: decide how to handle parser reconfiguration here
        @parser = setup_parser @name, @parser.save_dir

        connect!
      end

      def ws_onerror event
        raise WebsocketError, event.message
      end
    end
  end
end
