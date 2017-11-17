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

    def append data_a
      # This way we handle differently the first response which should be a snapshot of the orderbook
      if data_a.size == 3
        super data_a
      else
        new_slice = BTCData::BookSlice.new self.market, self.pair
        new_slice.data["asks"] = data_a.select {|x| x[2] < 0}
        new_slice.data["bids"] = data_a.select {|x| x[2] > 0}
        new_slice.time = Time.new.getgm
        new_slice.save_csv @save_dir
      end
    end
  end
end
