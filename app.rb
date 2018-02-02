require 'json'
require 'csv'
require 'dotenv'


require 'config'
require 'btcdata'

Dotenv.load


require 'json'
require 'eventmachine'
require 'faye/websocket'

@clients = Targets.targets.map do |hash_conf|
  BTCData::Market::Client.create_new hash_conf
end


EM.run {
  @clients.each do |client|
    client.run!
  end
}
