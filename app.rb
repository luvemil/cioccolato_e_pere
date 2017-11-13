require 'rest-client'
require 'addressable'
require 'json'
require 'csv'

api_url = "https://api.cryptowat.ch"

@ohlc_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}{?periods}"
@orderbook_template = Addressable::Template.new "https://api.cryptowat.ch/markets{/market}{/pair}{/function}"

def get_ohlc market, pair, density
  api_call = @ohlc_template.expand({
    "market" => market,
    "pair" => pair,
    "function" => "ohlc",
    "periods" => density
  }).to_s
  print "Trying url #{api_call}\n"
  res = JSON.parse RestClient.get(api_call)
  ohlc_l = res['result'][density.to_s]
  return ohlc_l
end

def save_csv data_t, csv_file
  # Save an array of the form [[a_11,...,a_1n],[a_21,...,a_2n],...] to csv
  CSV.open(csv_file,'w') do |csv_object|
    data_t.each do |row_array|
      csv_object << row_array
    end
  end
end

def get_orderbook market, pair
  api_call = @orderbook_template.expand({
    "market" => market,
    "pair" => pair,
    "function" => "orderbook",
  }).to_s
  print "Trying url #{api_call}\n"
  res = JSON.parse RestClient.get(api_call)
  return res['result']
end

def date_prefix
  return Time.new.getgm.strftime('%Y%m%d%H%M%S')
end
