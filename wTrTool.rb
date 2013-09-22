#!/usr/bin/ruby

###
### wTrTool.rb
###
require 'pp'
require 'optparse'
require 'yaml'
require 'kwalify'

opt = OptionParser.new

inputfilename = "MemTrace.dat"
outputfilename = "MemTool.txt"
patternfilename = "wTrToolFormat.yaml"
patternname = "sample1"
format_str = ""
pattern = nil

opt.on('-i inputfile') { |v| inputfilename = v }
opt.on('-o outputfile') { |v| outputfilename = v }
opt.on('-f patternfile') { |v| patternfilename = v }
opt.on('-p patternname') { |v| patternname = v }

argv = opt.parse(ARGV)

printf("inputfile\t= \"%s\"\n",inputfilename)
printf("outputfile\t= \"%s\"\n",outputfilename)
printf("patternfile\t= \"%s\"\n",patternfilename)
printf("patternname\t= \"%s\"\n",patternname)

# schema

s_file = File.read("schema.yaml")

schema_def = ""

s_file.each_line do |line|
  schema_def << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
end

schema = YAML.load(schema_def)
validator = Kwalify::Validator.new(schema)

# format

f_file = File.read(patternfilename)

yaml = ""

f_file.each_line do |line|
  yaml << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
end

data = YAML.load(yaml)

errors = validator.validate(data)
if !errors || errors.empty? then
else
  errors.each do |error|
    puts ""
    puts "Error: invalid pattern file"
    printf( "\t\"%s\" [%s}] %s\n",patternfilename,error.path,error.message)
  end
  exit(1)
end

data.each do |ptn|
  if ptn["name"] == patternname then
    pattern = ptn["format"]
  end
end

if pattern == nil then
  puts ""
  puts "Error: pattern not found"
  printf("\tpatternfile = \"%s\", patternname = \"%s\"\n",patternfilename,patternname)
  exit(1)
end

header = []
format = []

pattern.each do |member|
  header.push member["label"]
  format.push member["type"]
end

out_str = header.join("\t") + "\n"
format_str = format.join

# convert

binary = File.binread(inputfilename)
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
