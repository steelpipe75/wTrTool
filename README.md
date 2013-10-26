# wTrTool

## 概要

バイナリデータを変換して出力

構造体のデータが繰り返し並んでいるバイナリデータファイルを整形するために使いたい
yamlで記述された構造体情報を受け取って整形パターンを決める

## 使い方

* CLIモード

    Usage: wTrTool [options]
        -i, --input inputfile            入力ファイル指定
        -o, --output outputfile          出力ファイル指定
        -f, --format formatfile          整形パターン記述ファイル指定
        -p, --pattern patternname        整形パターン名指定
        -l, --littleend                  多バイトデータをlittle endianとして扱う        -b, --bigend                     多バイトデータをbig endianとして扱う

* GUIモード

コマンドライン引数に何も指定しなかった場合 GUIモードで起動

## ライセンス

wTrTool  
Copyright(c) 2013 steelpipe75  
Released under the MIT license.  
https://github.com/steelpipe75/wTrTool/blob/master/MIT-LICENSE.txt
  
  
Includes Kwalify  
http://www.kuwata-lab.com/kwalify/  
copyright(c) 2005-2010 kuwata-lab all rights reserved.  
Released under the MIT License.
