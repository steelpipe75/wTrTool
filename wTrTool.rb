#!/usr/bin/ruby

# 
# wTrTool
# https://github.com/steelpipe75/wTrTool
# 
# Copyright(c) 2013 steelpipe75
# Released under the MIT license.
# https://github.com/steelpipe75/wTrTool/blob/master/MIT-LICENSE.txt
# 
# 
# Includes Kwalify
# http://www.kuwata-lab.com/kwalify/
# copyright(c) 2005-2010 kuwata-lab all rights reserved.
# Released under the MIT License. 
# 

###
### wTrTool.rb
###
require 'pp'
require 'optparse'
require 'yaml'
require 'kwalify'

# parameter

Version = "v1.1"

inputfilename = "MemTrace.dat"
outputfilename = "MemTool.txt"
formatfilename = "wTrToolFormat.yaml"
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

schema_def = <<EOS
type: seq
sequence:
  - type: map
    mapping:
      "patternname":
        required: true
        unique: yes
        type: str
      "format":
        required: true
        type: seq
        sequence:
          - type: map
            mapping:
              "label":
                type: str
              "type":
                required: true
                enum:
                  - UINT8
                  - SINT8
                  - BIT8
                  - OCT8
                  - HEX8
                  - DUMMY8
                  - UINT16
                  - SINT16
                  - BIT16
                  - OCT16
                  - HEX16
                  - DUMMY16
                  - UINT32
                  - SINT32
                  - BIT32
                  - OCT32
                  - HEX32
                  - DUMMY32
EOS

# option parser

opt = OptionParser.new
opt.on('-i inputfile',  '--input inputfile',    ) { |v| inputfilename = v }
opt.on('-o outputfile', '--output outputfile',  ) { |v| outputfilename = v }
opt.on('-f formatfile', '--format formatfile',  ) { |v| formatfilename = v }
opt.on('-p patternname','--pattern patternname',) { |v| patternname = v }
opt.on('-l',            '--littleend',          'little endian') { endian = "little" }
opt.on('-b',            '--bigend',             'big endian') { endian = "big" }

argv = opt.parse(ARGV)

printf("inputfile\t= \"%s\"\n",inputfilename)
printf("outputfile\t= \"%s\"\n",outputfilename)
printf("formatfile\t= \"%s\"\n",formatfilename)
printf("patternname\t= \"%s\"\n",patternname)

# schema

schema = YAML.load(schema_def)
validator = Kwalify::Validator.new(schema)

# format

begin
  f_file = File.read(formatfilename)
rescue => ex
  puts "Error: formatfile can not open"
  printf("\t%s\n" ,ex.message)
  exit 1
end

yaml = ""

f_file.each_line do |line|
  yaml << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }
end

yaml_data = YAML.load(yaml)

errors = validator.validate(yaml_data)
if !errors || errors.empty? then
else
  puts "Error: invalid format file"
  errors.each do |error|
    printf( "\t\"%s\" [%s}] %s\n",formatfilename,error.path,error.message)
  end
  exit(1)
end

yaml_data.each do |ptn|
  if ptn["patternname"] == patternname then
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

begin
  binary = File.binread(inputfilename)
rescue => ex
  puts "Error: inputfile can not open"
  printf("\t%s\n" ,ex.message)
  exit 1
end

begin
  o_file = File.open(outputfilename,"w")
rescue => ex
  puts "Error: outputfile can not open"
  printf("\t%s\n" ,ex.message)
  exit 1
end

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
