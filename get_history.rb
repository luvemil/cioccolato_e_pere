require 'config'
require 'btcdata'

startTime = Date.new(2017,9,1)
endTime = Date.new(2017,9,4)

out_dir = "data"
Dir.mkdir(out_dir) unless Dir.exist? out_dir

startTime.upto(endTime) do |date|
  res = BTCData::Bitmex.getOhlcDate startTime=date
  data_t = BTCData::Bitmex._convert_named_cols res
  filename = "bitmex_XBTUSD_#{date.strftime('%Y-%m-%d')}_ohlc_5m.csv"
  BTCData.save_csv data_t, "#{out_dir}/#{filename}"
end

