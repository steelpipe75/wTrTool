#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'

filename = ARGV[0]
size = File.size?(filename)

binary = File.binread(filename)

puts binary.unpack("C*")
