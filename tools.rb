require 'rest-client'
require 'addressable'
require 'json'
require 'csv'

module BTCData
  @ohlc_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}{?periods}"
  @orderbook_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}"

  def BTCData.get_ohlc options = {}
    # Populate the api request to get OHLC
    # options = {
    #   :market => <market name>
    #   :pair => <pair name>
    #   :periods => <string or array of valid periods: 60,180,300,etc>
    # }
    # Returns:
    # {
    #   <period> => [[CloseTime, OpenPrice, HighPrice, LowPrice, ClosePrice, Volume],...]
    # }
    api_call = @ohlc_template.partial_expand({
      "function" => "ohlc"
    }).expand(options).to_s
    print "Trying url #{api_call}\n"
    res = JSON.parse RestClient.get(api_call)
    return res['result']
  end

  def BTCData.save_csv data_t, csv_file
    # Save an array of the form [[a_11,...,a_1n],[a_21,...,a_2n],...] to csv
    CSV.open(csv_file,'w') do |csv_object|
      data_t.each do |row_array|
        csv_object << row_array
      end
    end
  end

  def BTCData.get_orderbook market, pair
    api_call = @orderbook_template.expand({
      "market" => market,
      "pair" => pair,
      "function" => "orderbook",
    }).to_s
    print "Trying url #{api_call}\n"
    res = JSON.parse RestClient.get(api_call)
    return res['result']
  end

  def BTCData.date_prefix
    return Time.new.getgm.strftime('%Y%m%d%H%M%S')
  end

  def BTCData.parse_filename path
    # Return match objects with data spects to put in a Slice object
    split = [ File.dirname(path), File.basename(path) ]
    filename = split[1]
    mask = /(?<market>[^_]+)_(?<pair>[^_]+)_(?<date>[^_]+)_(?<function>[^_]+)(_(?<args>[^\.]+)|)\.csv/
    m = mask.match filename
  end

  class Slice
    attr_accessor :market, :pair, :function, :data

    def self.load filename
      data = CSV.read filename
      new_slice = self.new
      m = BTCData.parse_filename filename
      new_slice.market = m[:market]
      new_slice.pair = m[:pair]
      new_slice.function = m[:function]
      new_slice._loadData data, m[:args]
      return new_slice
    end

    def _loadData data, args
      @data = data
    end
  end

  class OhlcSlice < Slice
    def initialize
      @function = "ohlc"
      @data = {}
    end

    def _loadData data, args
      @data[args.to_s] = data
    end
  end
end
