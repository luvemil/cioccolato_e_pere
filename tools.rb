require 'rest-client'
require 'addressable'
require 'json'
require 'csv'

module BTCData
  @ohlc_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}{?periods}"
  @orderbook_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}"

  def BTCData.get_ohlc options = {}
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
end
