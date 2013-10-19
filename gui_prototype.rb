require 'tk'

def getopenfile
  return Tk.getOpenFile('title' => 'ファイルを開く',
                        'defaultextension' => 'sgf', 
                        'filetypes' => "{全てのファイル {.*}}")
end

def getsavefile
  return Tk.getSaveFile('title' => 'ファイルを開く',
			'defaultextension' => 'sgf', 
			'filetypes' => "{全てのファイル {.*}}")
end

endian = TkVariable.new("little")

formatfile_var = TkVariable.new('')
inputfile_var = TkVariable.new('')
outputfile_var = TkVariable.new('')

window = TkRoot.new {
  title 'wTrTool'
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

formatbutton.command( proc{ formatfile_var.value = getopenfile } )

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

inputbutton.command( proc{ inputfile.value = getopenfile } )

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
  width 40
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
  variable endian
  value 'little'
  width 15
  anchor 'w'
  select
  pack 'side'=>'left'
}

bigradiobutton = TkRadiobutton.new(endianframe) {
  text 'big'
  variable endian
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

Tk.mainloop
