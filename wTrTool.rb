#!/usr/bin/ruby -Ku

=begin

wTrTool
https://github.com/steelpipe75/wTrTool

Copyright(c) 2013 steelpipe75
Released under the MIT license.
https://github.com/steelpipe75/wTrTool/blob/master/MIT-LICENSE.txt


Includes Kwalify
http://www.kuwata-lab.com/kwalify/
copyright(c) 2005-2010 kuwata-lab all rights reserved.
Released under the MIT License.

=end

###
### wTrTool.rb
###
require 'pp'
require 'optparse'
require 'yaml'
require 'kwalify'

# parameter

Version = "v1.6"

$inputfilename = "MemTrace.dat"
$outputfilename = "MemTool.txt"
$formatfilename = "wTrToolFormat.yaml"
$patternname = "sample"
$endian = "little"
$delimiter = ","
$format = []

$FORMAT_STR = { 
  "UINT8"   => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "%d",      "length" => 1},
  "UINT16"  => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "%d",      "length" => 2},
  "UINT32"  => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "%d",      "length" => 4},
  "SINT8"   => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"c", "sprintf" => "%d",      "length" => 1},
  "SINT16"  => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"s", "sprintf" => "%d",      "length" => 2},
  "SINT32"  => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"i", "sprintf" => "%d",      "length" => 4},
  "BIT8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "0b%08b",  "length" => 1},
  "BIT16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "0b%016b", "length" => 2},
  "BIT32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "0b%032b", "length" => 4},
  "OCT8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "0%03o",   "length" => 1},
  "OCT16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "0%06o",   "length" => 2},
  "OCT32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "0%011o",  "length" => 4},
  "HEX8"    => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "0x%02X",  "length" => 1},
  "HEX16"   => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "0x%04X",  "length" => 2},
  "HEX32"   => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "0x%08X",  "length" => 4},
  "DUMMY8"  => {"little" => "C", "big" => "C", "pack" =>"C", "unpack" =>"C", "sprintf" => "",        "length" => 1},
  "DUMMY16" => {"little" => "v", "big" => "n", "pack" =>"v", "unpack" =>"S", "sprintf" => "",        "length" => 2},
  "DUMMY32" => {"little" => "V", "big" => "N", "pack" =>"V", "unpack" =>"I", "sprintf" => "",        "length" => 4},
}

$DUMMY = ["DUMMY8", "DUMMY16", "DUMMY32"]

$SCHEMA_DEF = <<EOS
type: seq
sequence:
  - type: map
    mapping:
      "patternname":
        required: true
        unique: yes
        type: str
      "description":
        type: str
      "format":
        &format-rule
        required: true
        type: seq
        sequence:
          - type: map
            name: format_member
            mapping:
              "label":
                type: str
                required: true
              "type":
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
              "array":
                type: map
                mapping:
                  "num":
                    type: int
                    required: true
                    range: { min: 1 }
                  "format": *format-rule
              "union":
                type: seq
                sequence:
                  - type: map
                    mapping:
                      "label":
                        type: str
                        required: true
                      "format": *format-rule
EOS

$UNION_FORMAT = Struct.new("Union_format",:label,:format)
$MEMBER = Struct.new("Member", :type,:label)

$yaml_data = nil
$stdout_str = []
$stderr_str = []

# option parser
def option_parse(argv)
  opt = OptionParser.new
  opt.on('-i inputfile',  '--input inputfile',    '入力ファイル指定') { |v| $inputfilename = v }
  opt.on('-o outputfile', '--output outputfile',  '出力ファイル指定') { |v| $outputfilename = v }
  opt.on('-f formatfile', '--format formatfile',  '整形パターン記述ファイル指定') { |v| $formatfilename = v }
  opt.on('-p patternname','--pattern patternname','整形パターン名指定') { |v| $patternname = v }
  opt.on('-l',            '--littleend',          '多バイトデータをlittle endianとして扱う') { $endian = "little" }
  opt.on('-b',            '--bigend',             '多バイトデータをbig endianとして扱う') { $endian = "big" }
  opt.on('-d delimiter',  '--delimiter delimiter','デリミタ指定') { |v| $delimiter = v }
  
  opt.parse(argv)
  
  $stdout_str.push sprintf("inputfile\t= \"%s\"\n",$inputfilename)
  $stdout_str.push sprintf("outputfile\t= \"%s\"\n",$outputfilename)
  $stdout_str.push sprintf("formatfile\t= \"%s\"\n",$formatfilename)
  $stdout_str.push sprintf("patternname\t= \"%s\"\n",$patternname)
  $stdout_str.push sprintf("delimiter\t= \"%s\"\n",$delimiter)
  if $delimiter == "\\t" || $delimiter == "\\T" then
    $delimiter = "\t"
  end
end

class FormatValidator < Kwalify::Validator
  @@schema = YAML.load($SCHEMA_DEF)
  
  def initialize()
    super(@@schema)
  end
  
  def validate_hook(value, rule, path, errors)
    case rule.name
    when "format_member"
      if value["array"] != nil then
        if value["type"] != nil then
          msg = "array format error"
          errors << Kwalify::ValidationError.new(msg, path)
        end
      end
    end
  end
end

# schema validation
def format_schema_validation(fmt_file)
  validator = FormatValidator.new
  
  begin
    f_file = File.read(fmt_file)
  rescue => ex
    $stderr_str.push "Error: formatfile can not open\n"
    $stderr_str.push sprintf("\t%s\n" ,ex.message)
    return 1
  end
  
  yaml = ""
  
  f_file.each_line do |line|
    while /\t+/ =~ line
      n = $&.size * 8 - $`.size % 8
      line.sub!(/\t+/, " " * n)
    end
    yaml << line
  end
  
  parser = Kwalify::Parser.new(yaml)
  $yaml_data = parser.parse()
  
  errors = validator.validate($yaml_data)
  if !errors || errors.empty? then
  else
    $stderr_str.push "Error: invalid format file\n"
    parser.set_errors_linenum(errors)
    errors.each do |error|
      $stderr_str.push sprintf( "\t%s (line %s) [%s] %s\n",fmt_file,error.linenum,error.path,error.message)
    end
    return 1
  end
end

def format_convert(format,pattern,prefix,suffix)
  pattern.each do |member|
    if member["union"] != nil then
      a = []
      member["union"].each do |m|
        union_member_format = []
        pre = (prefix == "" ? ("") : (prefix + ".")) + member["label"] + "." + m["label"] + "."
        format_convert(union_member_format,m["format"], pre, suffix)
        a.push union_member_format
      end
      uf = $UNION_FORMAT.new(member["label"],a)
      format.push uf
    elsif member["array"] != nil then
      i = 0
      while i < member["array"]["num"] do
        suf = sprintf("[%d]",i)
        if prefix == "" then
          pre = member["label"]
        else
          pre = prefix + suffix + "." + member["label"]
        end
        format_convert(format,member["array"]["format"], pre, suf)
        i = i+1
      end
    else
      type = member["type"]
      if suffix == "" then
        label = prefix + member["label"]
      else
        if member["label"] == "" then
          label = prefix + suffix
        else
          label = prefix + suffix + "." + member["label"]
        end
      end
      h = $MEMBER.new(type,label)
      format.push h
    end
  end
end

def make_header_str(header,format)
  case format
  when Array
    format.each do |fmt|
      make_header_str(header,fmt)
    end
  when $UNION_FORMAT
    make_header_str(header,format["format"])
  when $MEMBER
    case format["type"]
    when *$DUMMY
    else
      header.push format["label"]
    end
  end
end

def make_convert_str(str,binary,format)
  case format
  when Array
    format.each do |fmt|
      binary = make_convert_str(str,binary,fmt)
    end
  when $UNION_FORMAT
    min_binary = binary
    format["format"].each do |fmt|
      tmp_binary = make_convert_str(str,binary,fmt)
      if min_binary.size > tmp_binary.size then
        min_binary = tmp_binary
      end
    end
    return min_binary
  when $MEMBER
    f = $FORMAT_STR[format["type"]]
    length = f["length"]
    if binary.size < length then
      binary = [] # while を抜けるため
      return binary
    end
    template = f[$endian]
    data = binary.unpack(template)
    num = data.pack(f["pack"]).unpack(f["unpack"])
    case format["type"]
    when *$DUMMY
    else
      str.push sprintf(f["sprintf"], num[0])
    end
    cut = data.pack(template)
    binary2 = binary[cut.size..binary.size]
    binary = binary2
  end
  return binary
end

def data_convert(argv)
  option_parse(argv)
  ret = format_schema_validation($formatfilename)
  if ret == 1 then
    return 1
  end
  # pattern
  
  pattern = nil
  
  $yaml_data.each do |ptn|
    if ptn["patternname"] == $patternname then
      pattern = ptn["format"]
    end
  end
  
  if pattern == nil then
    $stderr_str.push "Error: pattern not found\n"
    $stderr_str.push sprintf("\tformatfile = \"%s\", patternname = \"%s\"\n",$formatfilename,$patternname)
    return 1
  end
  
  $format = []
  
  format_convert($format,pattern,"","")
  
  if $format == [] then
    $stderr_str.push "Error: invalid pattern\n"
    return 1
  end
  
  # convert
  
  begin
    binary = File.binread($inputfilename)
  rescue => ex
    $stderr_str.push "Error: inputfile can not open\n"
    $stderr_str.push sprintf("\t%s\n" ,ex.message)
    return 1
  end
  
  begin
    o_file = File.open($outputfilename,"w")
  rescue => ex
    $stderr_str.push "Error: outputfile can not open\n"
    $stderr_str.push sprintf("\t%s\n" ,ex.message)
    return 1
  end
  
  header = []
  make_header_str(header,$format)
  
  out_str = header.join($delimiter) + "\n"
  o_file.write out_str
  
  while binary.size > 0 do
    str = []
    
    binary = make_convert_str(str,binary,$format)
    
    out_str = str.join($delimiter) + "\n"
    
    o_file.write out_str
  end
  
  o_file.close
  return 0
end

# entry point
$stdout_str = []
$stderr_str = []
ret = data_convert(ARGV)
$stdout_str.each do |str|
  STDOUT.puts(str)
end
puts "========================"
$stdout.flush
if ret != 0 then
  $stderr_str.each do |str|
    STDERR.puts(str)
  end
  exit ret
else
  puts "Success"
end
