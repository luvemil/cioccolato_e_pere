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

  def BTCData.get_function options = {}
    api_call = @orderbook_template.expand(options).to_s
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

  def BTCData.append_csv data_t, csv_file
    CSV.open(csv_file, 'a') do |csv_object|
      data_t.each do |row_array|
        csv_object << row_array
      end
    end
  end

  def BTCData.get_orderbook options = {}
    api_call = @orderbook_template.partial_expand({
      "function" => "orderbook"
    }).expand(options).to_s
    print "Trying url #{api_call}\n"
    res = JSON.parse RestClient.get(api_call)
    return res['result']
  end

  def BTCData.date_prefix
    return Time.new.getgm.strftime('%Y%m%d%H%M%S')
  end

  def BTCData._date_to_string time
    return time.strftime('%Y%m%d%H%M%S')
  end

  def BTCData.parse_filename path
    # Return match objects with data spects to put in a Slice object
    split = [ File.dirname(path), File.basename(path) ]
    filename = split[1]
    mask = /(?<market>[^_]+)_(?<pair>[^_]+)_(?<date>[^_]+)_(?<function>[^_]+)(_(?<args>[^\.]+)|)\.csv/
    m = mask.match filename
  end

  def BTCData.convert_date_string date_string
    # Return Time object from string
    year = date_string.slice(0,4)
    month = date_string.slice(4,2)
    day = date_string.slice(6,2)
    hour = date_string.slice(8,2)
    minutes = date_string.slice(10,2)
    seconds = date_string.slice(12,2)
    return Time.gm year, month, day, hour, minutes, seconds
  end

  class Slice
    attr_accessor :market, :pair, :function, :data, :time

    def initialize market, pair
      @market = market
      @pair = pair
    end

    def self.load filename
      # Returns a new Slice object containing the data

      # This test guarantees that, when using subclasses, we load the correct type of data
      m = BTCData.parse_filename filename
      market = m[:market]
      pair = m[:pair]

      new_slice = self.new market, pair
      unless new_slice.function.instance_of? NilClass
        if new_slice.function != m[:function]
          return nil
        end
      end
      data = CSV.read filename
      new_slice.time = BTCData.convert_date_string m[:date]
      new_slice._loadData data, m[:args]
      return new_slice
    end

    def read_response res
      # Load data from a response object, you should take care of calling the correct object
      @data = res
      @time = Time.new.getgm
    end

    def save_csv out_dir
      @data.keys.each do |key|
        outfile = "#{out_dir}/#{self.get_filename(key)}"
        BTCData.save_csv @data[key], outfile
      end
    end

    def get_filename key
      return "#{self.market}_#{self.pair}_#{BTCData._date_to_string(self.time)}_#{self.function}_#{key}.csv"
    end

    def _loadData data, args
      if args.instance_of? NilClass
        @data = {:all => data}
      else
        @data[args.to_s] = data
      end
    end
  end

  class OhlcSlice < Slice
    def initialize market, pair
      super market, pair
      @function = "ohlc"
      @data = {}
    end
  end

  class BookSlice < Slice
    def initialize market, pair
      super market, pair
      @function = "orderbook"
      @data = {
        "asks" => nil,
        "bids" => nil
      }
    end
  end

  class TradeSlice < Slice
    def initialize market, pair
      super market, pair
      @function = "trades"
      @data = {
        "trades" => []
      }
    end

    def read_response res
      # Load data from a response object, you should take care of calling the correct object
      @data["trades"] = res
      @time = Time.new.getgm
    end

  end

  class FeedSlice < Slice
    attr_accessor :save_dir

    def initialize market, pair, function, save_dir
      super market, pair
      @function = function
      @data = {
        :feed => []
      }
      @save_dir = save_dir
      @time = Time.new.getgm
      @count = 0
    end

    def append data_a
      # Append data to the feed, adding a timestamp
      @data[:feed] << data_a.unshift(Time.new.tv_sec)
      @count += 1
      if @count % 100 == 0
        self.dump_data
      end
    end

    def dump_data
      output = @data
      @data = []
      BTCData::append_csv output, "#{self.save_dir/self.get_filename("feed")}"
    end
  end
end
