#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'

filename = ARGV[1]
size = File.size?(filename)

binary = File.binread(filename)

if ARGV[0] == "u"
 puts binary.unpack("C*")
else
 puts binary.unpack("c*")
end
