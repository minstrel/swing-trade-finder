# Swing trade checker

This is a script to check current buy prices (on binance at the moment)
and see if they'd be a potential buy for a swing trade.

Work in progress.  Right now I have two methods, one to pull in a trading
pair's daily history, another to check that data against a given buy value
and see how many days we could have made 5% on it.

## The logic

Nothing fancy, it just checks a given buy price and checks if, for each
day in the last 30:

- That buy price is above the day's low
- That buy price, plus the desired profit (5% right now), is below the day's high

If both of those are good, it gets marked as a good day, if not it's bad.
I don't really know how great a measure this is, but I'm going to play around
with it and find out.

The idea is that it's going to look for coins / tokens with a relatively stable
average value, but enough volatility to enable swing trading it.

Maybe in the future I could put in stuff to make sure it's not TOO volatile.
Something like if the low or high is too far below / above the buy value / profit.

## Still to write:

- Automate the task, and run through a pair every 30 seconds or so.
- Allow the user to specify the percent they'd like to make.
