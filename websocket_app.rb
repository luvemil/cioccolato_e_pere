require 'json'
require 'csv'
require 'dotenv'

require 'bitfinex-rb'

require 'tools'
require 'config'

Dotenv.load

Bitfinex::Client.configure do |conf|
  conf.secret = ENV['BFX_API_SECRET']
  conf.api_key = ENV['BFX_API_KEY']
end

client = Bitfinex::Client.new

client.listen_account do |c|
  puts "account: #{c.inspect}"
end

client.listen_ticker do |t|
  puts "tick: #{t.inspect}"
end

client.listen_book do |b|
  puts "book: #{b.inspect}"
end

client.listen_trades do |b|
  puts "trades: #{b.inspect}"
end

client.listen!
