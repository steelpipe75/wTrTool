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
patternname = "sample"
pattern = nil
endian = "little"

format_str = { 
  "UINT8"   => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "%d",  },
  "UINT16"  => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "%d",  },
  "UINT32"  => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "%d",  },
  "SINT8"   => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"c", "sprintf" => "%d",  },
  "SINT16"  => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "%d",  },
  "SINT32"  => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "%d",  },
  "BIT8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "%#b", },
  "BIT16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "%#b", },
  "BIT32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "%#b", },
  "OCT8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "%#o", },
  "OCT16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "%#o", },
  "OCT32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "%#o", },
  "HEX8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "%#x", },
  "HEX16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "%#x", },
  "HEX32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "%#x", },
  "DUMMY8"  => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "",    },
  "DUMMY16" => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "",    },
  "DUMMY32" => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "",    },
}

dummy = ["DUMMY8", "DUMMY16", "DUMMY32"]

opt.on('-i inputfile') { |v| inputfilename = v }
opt.on('-o outputfile') { |v| outputfilename = v }
opt.on('-f patternfile') { |v| patternfilename = v }
opt.on('-p patternname') { |v| patternname = v }
opt.on('-l') { endian = "little" }
opt.on('-b') { endian = "big" }

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

yaml_data = YAML.load(yaml)

errors = validator.validate(yaml_data)
if !errors || errors.empty? then
else
  puts "Error: invalid pattern file"
  errors.each do |error|
    printf( "\t\"%s\" [%s}] %s\n",patternfilename,error.path,error.message)
  end
  exit(1)
end

yaml_data.each do |ptn|
  if ptn["name"] == patternname then
    pattern = ptn["format"]
  end
end

if pattern == nil then
  puts "Error: pattern not found"
  printf("\tpatternfile = \"%s\", patternname = \"%s\"\n",patternfilename,patternname)
  exit(1)
end

header = []
format = []

pattern.each do |member|
  case member["type"]
  when *dummy
  else
    header.push member["label"]
  end
  format.push member["type"]
end

# convert

binary = File.binread(inputfilename)
o_file = File.open(outputfilename,"w")

out_str = header.join("\t") + "\n"
o_file.write out_str

while binary.size > 0 do
  str = []
  
  format.each do |fmt|
    f = format_str[fmt]
    template = f[endian]
    data = binary.unpack(template)
    num = data.pack(f["pack"]).unpack(f["unpack"])
    case fmt
    when *dummy
    else
      str.push sprintf(f["sprintf"], num[0])
    end
    cut = data.pack(template)
    binary2 = binary[cut.size..binary.size]
    binary = binary2
  end
  
  out_str = str.join("\t") + "\n"
  
  o_file.write out_str
end

o_file.close
