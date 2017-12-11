require 'rest-client'
require 'addressable'
require 'json'

module BTCData
  module Bitmex
    module ApiCall
      @bitmex_api_url = Addressable::Template.new "https://www.bitmex.com/api/v1{/endpoint*}{?params*}"
      @density_size = {
        "m" => 1,
        "h" => 60,
        "d" => 60*24,
        "w" => 60*24*7
      }
      def ApiCall._density_to_minutes density
        m = /(?<qt>\d+)(?<unit>[mhdw])/.match density
        return nil unless m
        return m[:qt].to_i * @density_size[m[:unit]]
      end

      def ApiCall.openInstruments
        api_call = @bitmex_api_url.expand({
          "endpoint" => "instrument",
          "params" => {
            "filter" => JSON.generate({
              "state"=>"Open"
            }),
            "columns" => ["symbol","rootSymbol"]
          }
        }).to_s
        return api_call
      end

      def ApiCall.ohlcDate binSize="5m", symbol="XBTUSD", startTime
        api_call = @bitmex_api_url.expand({
          "endpoint" => ["trade","bucketed"],
          "params" => {
            "binSize" => binSize,
            "symbol" => symbol,
            "count" => @density_size["d"]/ApiCall._density_to_minutes(binSize),
            "startTime" => startTime.strftime("%Y-%m-%d")
          }
        }).to_s
        return api_call
      end
    end

    def Bitmex.callApi api_call
      puts "Trying: #{api_call}"
      res = JSON.parse RestClient.get(api_call)
      return res
    end

    def Bitmex.getOpenInstruments
      api_call = ApiCall.openInstruments
      return Bitmex.callApi api_call
    end

    def Bitmex.getOhlcDate binSize="5m", symbol="XBTUSD", startTime
      # startTime : @Time object
      api_call = ApiCall.ohlcDate binSize, symbol, startTime
      return Bitmex.callApi api_call
    end

    def Bitmex._convert_named_cols col_a
      # Take an array of the form [[col_1 => d_1_1,...],...,[col_1=>d_1_n]] to
      # [[col_1,...],[d_1_1,...],[d_1_n,...]]
      columns = col_a[0].keys
      data_t = Array.new col_a.size do |ix|
        Array.new columns.size do |col_n|
          col_a[ix][columns[col_n]]
        end
      end
      return data_t.unshift(columns)
    end

  end
end
