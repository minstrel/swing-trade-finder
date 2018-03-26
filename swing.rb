#!/usr/bin/ruby -w
# encoding: utf-8

require 'net/http'
require 'json'
require 'date'

# Check swing trade opportunities for Binance

# A single day's data
class Candle
  attr_accessor :high, :low, :time
  def initialize( params = {} )
    @high = params[:high]
    @low = params[:low]
    @time = params[:time]
  end
end

# A series of Candles
class CandleGroup
  attr_accessor :candles
  def initialize(symbol)
    # Get the full data for the given symbol from the Binance API
    args = {symbol: symbol, interval: '1d'}

    uri = URI('https://api.binance.com/api/v1/klines')
    uri.query = URI.encode_www_form(args)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Get.new(uri)
    req.content_type = 'application/json'

    res = http.request(req)
    candle_data = JSON.parse(res.body)

    # Initialize the group of candles
    @candles = []

    candle_data.each do |data|
      @candles << Candle.new(:high => data[2].to_f,
                             :low => data[3].to_f,
                             :time => Time.at(data[0].to_i / 1000.0)
                            )
    end

    # Delete today's incomplete data
    @candles.delete(
      @candles.max_by { |c| c.time }
    )
  end

  # Return the most recent X days data
  def return_data_by_days(days)
    raise "Not enough data" if @candles.length < days
    @candles.max_by(days) { |c| c.time }
  end

  # Check a value over a range of days and return good and bad days as a hash
  # TODO check the following day also, or allow an option to do so
  # TODO allow data to be passed in so we're not polling it every time
  def swing_check(params={})
    # Buy value to check
    value = params[:value]
    # Number of days to check
    days = params[:days]
    # Get the data for the requested period
    # Sort it oldest first for future use in checking next days
    data = return_data_by_days(days).sort_by { |d| d.time }
    # Starting good and bad days
    good = 0
    bad = 0
    # Good day has value between low and high, and value * 1.05 under high
    data.each do |d|
      if value.between?(d.low, d.high) && ( (value * 1.05) < d.high )
        good += 1
      else
        bad += 1
      end
    end
    {good: good, bad: bad}
  end

  # Find the best swings for the given period
  def find_best(params = {})
    # Number of days to check
    days = params[:days]
    # Get the data for the requested period
    # Sort it oldest first
    data = return_data_by_days(days).sort_by { |d| d.time }
    # Highest
    highest = (data.max_by { |x| x.high }).high
    # Lowest
    lowest = (data.min_by { |x| x.low }).low
    # Set best record (most # of good days) to 0
    best_record = 0
    # Create an array to hold best values
    best_values = []
    # Go down from highest to lowest, 1% at a time
    range = highest - lowest
    lowest.step(highest, range / 100.0).each do |test_val|
      # puts "Testing value: " + test_val.to_s
      results = swing_check(days: days, value: test_val)
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

end

