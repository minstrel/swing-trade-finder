#!/usr/bin/ruby -w
# encoding: utf-8

require 'net/http'
require 'json'
require 'date'

# Check swing trade opportunities for Binance


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

# TODO
# Allow some flexibility in the length of the swing
# Like check if the value * profit falls within a 2 day period

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
  # puts "#{good} days good, #{bad} days bad for this swing"
  {good: good, bad: bad}
end

# Find the ideal value (best good / bad ratio)
def find_best(data)
  # TODO this is using the full range, we need to snip to size
  # TODO this is a kludge, clean up
  # Get the highest and lowest value for the period
  get_range = data.clone
  # Remove the day in progress
  get_range.slice!(-1)
  # If the remaining array is longer than 30, slice anything older then 30)
  if get_range.length > 30
    get_range.slice!(0..-31)
  end
  # Highest
  highest = (get_range.max_by { |x| x[2].to_f })[2].to_f
  puts "Highest value for period is " + highest.to_s
  # Lowest
  lowest = (get_range.min_by { |x| x[3].to_f })[3].to_f
  puts "Lowest value for period is " + lowest.to_s
  # Set best record (most # of good days) to 0
  best_record = 0
  # Create an array to hold best values
  best_values = []
  # Go down from highest to lowest, 1% at a time
  range = highest - lowest
  lowest.step(highest, range / 100.0).each do |test_val|
    # puts "Testing value: " + test_val.to_s
    results = swing_check(data.clone, value: test_val)
    # Calculate # good from the value
    # Set new best record if it's higher
    # Clear array of best values if it's higher
    if results[:good] > best_record
      # puts "Value #{test_val} has #{results[:good]} good values, new high"
      best_values = []
      best_record = results[:good]
    end
    # Skip to next if it's lower
    if results[:good] < best_record
      # puts "Value #{test_val} has #{results[:good]} good values, less than #{best_record}, skipping"
      next
    end
    # Add to array of best values if it's higher or equal
    if results[:good] == best_record
      # puts "Value #{test_val} matches high of #{best_record}, adding to array"
      best_values << test_val
    end
  end
  # Return array of best values
  best_values
end
