#!/usr/bin/ruby -w
# encoding: utf-8

require 'net/http'
require 'json'
require 'date'

# Check swing trade opportunities for Binance

# TODO make sure we ignore the current day
# use the last 30 members of the array

# Get the full kline data for the symbol.
def get_kline(symbol)
  uri = URI('https://api.binance.com/api/v1/klines')

  args = {symbol: symbol, interval: '1d'}
  uri.query = URI.encode_www_form(args)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  req = Net::HTTP::Get.new(uri)
  req.content_type = 'application/json'

  res = http.request(req)
  JSON.parse(res.body)
end

# Check to see if it's a good opportunity
def swing_check(data, params={})
  # Buy value to check
  value = params[:value]
  # Reject if there's not 30 days worth (< 31 because today is dropped)
  return "Not enough data" if data.length < 31
  # Remove the day in progress
  data.slice!(-1)
  # If the remaining array is longer than 30, slice anything older then 30)
  if data.length > 30
    data.slice!(0..-31)
  end
  good = 0
  bad = 0
  data.each do |d|
    high = d[2].to_f
    low = d[3].to_f
    if value.between?(low, high) && ( (value * 1.05) < high )
      good += 1
    else
      bad += 1
    end
  end
  puts "#{good} days good, #{bad} days bad for this swing"
end
