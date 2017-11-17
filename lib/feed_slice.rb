require 'csv'

require 'tools'
require 'slice'

module BTCData
  class FeedSlice < Slice
    attr_accessor :save_dir

    def initialize market, pair, function, save_dir
      super market, pair
      @function = function
      @data = {
        "feed" => []
      }
      @save_dir = save_dir
      @time = Time.new.getgm
      @count = 0
    end

    def append data_a
      # Append data to the feed, adding a timestamp
      # The user should take care of separating snapshots from updates depending on the api
      @data["feed"] << data_a.unshift(Time.new.tv_sec)
      @count += 1
      if @count % 100 == 0
        self.dump_data
      end
    end

    def dump_data
      output = @data["feed"]
      @data["feed"] = []
      BTCData::append_csv output, "#{self.save_dir}/#{self.get_filename('feed')}"
    end
  end

  class OrderbookFeed < FeedSlice
    def initialize market, pair, save_dir
      super market, pair, "orderbook", save_dir
      @data = {
        "feed" => [
          %W[Timestamp Price Count Amount]
        ]
      }
    end
  end
end
