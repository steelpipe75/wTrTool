#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'
require 'optparse'

opt = OptionParser.new

inputfilename = "MemTrace.dat"
outputfilename = "MemTool.txt"
format = "C"

opt.on('-i inputfile') {|v| inputfilename = v }
opt.on('-o outputfile') {|v| outputfilename = v }
opt.on('-f format') {|v| format = v }

argv = opt.parse(ARGV)

printf("inputfile = \"%s\"\n",inputfilename)
binary = File.binread(inputfilename)

printf("outputfile = \"%s\"\n",outputfilename)
o_file = File.open(outputfilename,"w")

printf("format = \"%s\"\n",format)

while binary.size > 0 do
  # pp binary
  str = binary.unpack(format)
  
  str.each do |s|
    o_file.printf("%s\t",s)
  end
  o_file.printf("\n")
  
  str2 = str.pack(format)
  binary2 = binary[str2.size..binary.size]
  binary = binary2
  # pp binary
end

o_file.close
