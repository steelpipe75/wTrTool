#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'
require 'optparse'
require 'yaml'

opt = OptionParser.new

inputfilename = "MemTrace.dat"
outputfilename = "MemTool.txt"
patternfilename = "wTrToolFormat.yaml"
patternname = "sample1"
format_str = "C"

opt.on('-i inputfile') {|v| inputfilename = v }
opt.on('-o outputfile') {|v| outputfilename = v }
opt.on('-f patternfile') {|v| patternfilename = v }
opt.on('-p patternname') {|v| patternname = v }

argv = opt.parse(ARGV)

printf("inputfile = \"%s\"\n",inputfilename)
binary = File.binread(inputfilename)

printf("patternfile = \"%s\"\n",patternfilename)
f_file = File.read(patternfilename)

yaml = ''

f_file.each_line do |line|
  yaml << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
end

data = YAML.load(yaml)

header = []
format = []
data[patternname].each do |member|
  header.push member["name"]
  format.push member["type"]
end

out_str = header.join("\t") + "\n"
format_str = format.join

printf("outputfile = \"%s\"\n",outputfilename)
o_file = File.open(outputfilename,"w")

o_file.write out_str

while binary.size > 0 do
  # pp binary
  str = binary.unpack(format_str)
  
  out_str = str.join("\t") + "\n"
  
  o_file.write out_str
  # puts out_str
  
  str2 = str.pack(format_str)
  binary2 = binary[str2.size..binary.size]
  binary = binary2
  # pp binary
end

o_file.close
