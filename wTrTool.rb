#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'
require 'optparse'
opt = OptionParser.new

filename = "MemTrace.dat"
format = false

opt.on('-f VAL') {|v| filename = v }
opt.on('-u') {|v| format = v }

argv = opt.parse(ARGV)

binary = File.binread(filename)

if format== true
 puts binary.unpack("C*")
else
 puts binary.unpack("c*")
end
