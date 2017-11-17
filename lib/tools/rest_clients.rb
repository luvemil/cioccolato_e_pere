require 'rest-client'
require 'addressable'
require 'json'

require 'tools/io'

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

  def BTCData.get_orderbook options = {}
    api_call = @orderbook_template.partial_expand({
      "function" => "orderbook"
    }).expand(options).to_s
    print "Trying url #{api_call}\n"
    res = JSON.parse RestClient.get(api_call)
    return res['result']
  end
end
