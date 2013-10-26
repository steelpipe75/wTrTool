wTrTool

バイナリデータを変換して出力

------------

構造体のデータが繰り返し並んでいるバイナリデータファイルを整形するために使いたい

yamlで記述された構造体情報を受け取って整形パターンを決める

------------

	Usage: wTrTool [options]
	    -i, --input inputfile            入力ファイル指定
	    -o, --output outputfile          出力ファイル指定
	    -f, --format formatfile          整形パターン記述ファイル指定
	    -p, --pattern patternname        整形パターン名指定
	    -l, --littleend                  多バイトデータをlittle endianとして扱う
	    -b, --bigend                     多バイトデータをbig endianとして扱う

------------

コマンドライン引数に何も指定しなかった場合 GUIモードで起動
