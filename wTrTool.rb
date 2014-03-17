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
require 'tk'

# parameter

Version = "v1.5a"

$inputfilename = "MemTrace.dat"
$outputfilename = "MemTool.txt"
$formatfilename = "wTrToolFormat.yaml"
$patternname = "u"
$endian = "little"
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

  opt.parse(argv)

  $stdout_str.push sprintf("inputfile\t= \"%s\"\n",$inputfilename)
  $stdout_str.push sprintf("outputfile\t= \"%s\"\n",$outputfilename)
  $stdout_str.push sprintf("formatfile\t= \"%s\"\n",$formatfilename)
  $stdout_str.push sprintf("patternname\t= \"%s\"\n",$patternname)
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
      union_format = Struct.new("Union_format",:label,:format)
      a = []
      member["union"].each do |m|
        union_member_format = []
        pre = (prefix == "" ? ("") : (prefix + ".")) + member["label"] + "." + m["label"] + "."
        format_convert(union_member_format,m["format"], pre, suffix)
        a.push union_member_format
      end
      uf = union_format.new(member["label"],a)
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
      m = Struct.new("Member", :type,:label)
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
      h = m.new(type,label)
      format.push h
    end
  end
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

  p "================================================================================"
  pp $format
  p "================================================================================"
  pp $format.class
  p "================================================================================"
  $format.each do |f|
    pp f.class
  end
  p "================================================================================"

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
  $format.each do |fmt|
    case fmt["type"]
    when *$DUMMY
    else
      header.push fmt["label"]
    end
  end


  out_str = header.join(",") + "\n"
  o_file.write out_str

  while binary.size > 0 do
    str = []
    
    $format.each do |fmt|
      f = $FORMAT_STR[fmt["type"]]
      length = f["length"]
      if binary.size < length then
        binary = [] # while を抜けるため
        break;
      end
      template = f[$endian]
      data = binary.unpack(template)
      num = data.pack(f["pack"]).unpack(f["unpack"])
      case fmt["type"]
      when *$DUMMY
      else
        str.push sprintf(f["sprintf"], num[0])
      end
      cut = data.pack(template)
      binary2 = binary[cut.size..binary.size]
      binary = binary2
    end
    
    out_str = str.join(",") + "\n"
    
    o_file.write out_str
  end

  o_file.close
  return 0
end

def getopenformatfile
  return Tk.getOpenFile('title' => 'ファイルを開く',
                        'defaultextension' => 'sgf', 
                        'filetypes' => "{YAMLファイル {.yaml}} {全てのファイル {.*}}")
end

def getopeninputfile
  return Tk.getOpenFile('title' => 'ファイルを開く',
                        'defaultextension' => 'sgf', 
                        'filetypes' => "{バイナリデータファイル {.dat}} {全てのファイル {.*}}")
end

def getsavefile
  return Tk.getSaveFile('title' => 'ファイルを開く',
                        'defaultextension' => 'sgf', 
                        'filetypes' => "{テキストファイル {.txt}} {全てのファイル {.*}}")
end

def start_gui
  endian_var = TkVariable.new("little")

  formatfile_var = TkVariable.new('')
  inputfile_var = TkVariable.new('')
  outputfile_var = TkVariable.new('')
  patternname_var = TkVariable.new('')

  gui_title = sprintf("wTrTool %s", Version)

  window = TkRoot.new {
    title gui_title
    resizable [0,0]
  }

  fomrat_row = 0

  formatlabel = TkLabel.new {
    text 'formatfile'
    width 10
    anchor 'w'
    grid 'row'=>fomrat_row, 'column'=>0, 'sticky' => 'news'
  }

  formatfile = TkEntry.new {
    width 40
    grid 'row'=>fomrat_row, 'column'=>1, 'sticky' => 'news'
  }

  formatfile.textvariable = formatfile_var

  formatbutton = TkButton.new {
    text 'select'
    width 10
    grid 'row'=>fomrat_row, 'column'=>2, 'sticky' => 'news'
  }

  input_row = 1

  inputlabel = TkLabel.new {
    text 'inputfile'
    width 10
    anchor 'w'
    grid 'row'=>input_row, 'column'=>0, 'sticky' => 'news'
  }

  inputfile = TkEntry.new {
    width 40
    grid 'row'=>input_row, 'column'=>1, 'sticky' => 'news'
  }

  inputfile.textvariable = inputfile_var

  inputbutton = TkButton.new {
    text 'select'
    width 10
    grid 'row'=>input_row, 'column'=>2, 'sticky' => 'news'
  }

  inputbutton.command( proc{ inputfile.value = getopeninputfile } )

  output_row = 2

  outputlabel = TkLabel.new {
    text 'outputfile'
    width 10
    anchor 'w'
    grid 'row'=>output_row, 'column'=>0, 'sticky' => 'news'
  }

  outputfile = TkEntry.new {
    width 40
    grid 'row'=>output_row, 'column'=>1, 'sticky' => 'news'
  }

  outputfile.textvariable = outputfile_var

  outputbutton = TkButton.new {
    text 'select'
    width 10
    grid 'row'=>output_row, 'column'=>2, 'sticky' => 'news'
  }

  outputbutton.command( proc{ outputfile.value = getsavefile } )

  pattern_row = 3

  patternlabel = TkLabel.new {
    text 'pattern'
    width 10
    anchor 'nw'
    grid 'row'=>pattern_row, 'column'=>0, 'sticky' => 'news'
  }

  listframe = TkFrame.new
  listscrollbar = TkScrollbar.new(listframe)
  list = TkListbox.new(listframe) {
    height 4
    width 70
    selectmode 'browse'
    yscrollbar listscrollbar
  }

  list.pack('side'=>'left')
  listscrollbar.pack('side'=>'left', 'fill'=>'y')

  listframe.grid('row'=>pattern_row, 'column'=>1, "columnspan" => 2, 'sticky' => 'news')

  endian_row = 4

  endianlabel = TkLabel.new {
    text 'endian'
    width 10
    anchor 'nw'
    grid 'row'=>endian_row, 'column'=>0, 'sticky' => 'news'
  }

  endianframe = TkFrame.new

  littleradiobutton = TkRadiobutton.new(endianframe) {
    text 'little'
    variable endian_var
    value 'little'
    width 15
    anchor 'w'
    select
    pack 'side'=>'left'
  }

  bigradiobutton = TkRadiobutton.new(endianframe) {
    text 'big'
    variable endian_var
    value 'big'
    width 15
    anchor 'w'
    deselect
    pack 'side'=>'left'
  }

  endianframe.grid('row'=>endian_row, 'column'=>1, "columnspan" => 2, 'sticky' => 'news')

  exec_row = 6

  execbutton = TkButton.new {
    text 'exec'
    grid 'row'=>exec_row, 'column'=>0, 'columnspan'=>3, 'sticky' => 'news'
  }

  resultlabel = TkLabel.new {
    text 'result'
    width 10
    anchor 'w'
    grid 'row'=>exec_row+1, 'column'=>0, 'sticky' => 'news'
  }

  result_text = TkText.new {
    state 'disabled'
    height 10
    grid 'row'=>exec_row+2, 'column'=>0, 'columnspan'=>3, 'sticky' => 'news'
  }

  formatbutton.command(
    proc{
      formatfile_var.value = getopenformatfile
      fmt_file = formatfile_var.value
      $stdout_str = []
      $stderr_str = []
      result_text.state 'normal'
      result_text.delete('0.0', 'end')
      list.clear
      if fmt_file.length != 0 then
        ret = format_schema_validation(fmt_file)
        if ret == 1 then
          $stderr_str.each do |str|
           result_text.insert('end', str)
          end
        else
          $yaml_data.each do |ptn|
            l_str = sprintf("%s : %s", ptn["patternname"] ,ptn["description"])
            list.insert('end', l_str)
          end
          list.selection_set (0)
        end
      end
      result_text.state 'disabled'
    }
  )

  execbutton.command(
    proc {
      $stdout_str = []
      $stderr_str = []
      result_text.state 'normal'
      result_text.delete('0.0', 'end')
      gui_arg = []
      if formatfile_var.to_s.length > 0 then
        gui_arg.push '-f'
        gui_arg.push formatfile_var.to_s
      end
      if inputfile_var.to_s.length > 0 then
        gui_arg.push '-i'
        gui_arg.push inputfile_var.to_s
      end
      if outputfile_var.to_s.length > 0 then
        gui_arg.push '-o'
        gui_arg.push outputfile_var.to_s
      end
      if list.curselection.size != 0 then
        idx = list.curselection[0]
        ptn = $yaml_data[idx]
        gui_arg.push '-p'
        gui_arg.push ptn["patternname"]
      end
      if endian_var.to_s == 'little' then
        gui_arg.push '-l'
      else
        gui_arg.push '-b'
      end
      data_convert(gui_arg)
      $stdout_str.each do |str|
        result_text.insert('end', str)
      end
      separator = sprintf("========================\n")
      result_text.insert('end', separator)
      if $stderr_str.empty? then
        result_text.insert('end', 'Success')
      else
        $stderr_str.each do |str|
         result_text.insert('end', str)
        end
      end
      result_text.state 'disabled'
    }
  )

  Tk.mainloop
end

#if ARGV.empty? then
#  start_gui
#else
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
#end
