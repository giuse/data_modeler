#!/bin/env ruby

# I want a demo dataset based on real data I have lying around which I
# know is easy to learn, but I want it totally anonymized.
# I'll fake time and series names, and normalize the data (feature scaling).

require 'csv'

filename = ARGV.first || abort("Call: `$ ruby #{__FILE__} <datafile>`")

# 50 lines ought to be plenty
nlines = 50
# won't need more than 5 time series
nseries = 5

# read data, discard headers
_, *data = CSV.foreach(filename, converters: :float).take(nlines+1) # headers
# fake headers
headers = nseries.times.collect { |i| "s#{i+1}" }
# transpose into columns list, drop time and extra series
columns = data.transpose[1..nseries]
# fake time too
time = nlines.times.collect { |i| i+1 }

# feature scaling on each column
norm = columns.collect do |column|
  min, max = column.minmax
  span = max-min
  column.collect { |v| ((v-min)/span).round(3) } # keep precision=size low
end

# add back (fake) time and switch back into rows
table = ([time]+norm).transpose

# dump a CSV
CSV.open('demo_ts.csv', 'w') do |csv|
  csv << [:time] + headers
  table.each { |row| csv << row }
end

puts 'Done!'
