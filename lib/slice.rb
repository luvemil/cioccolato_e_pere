require 'csv'

require 'tools'


module BTCData
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

    def set_function new_function
      @function = new_function
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

  class TradesSlice < Slice
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
end
