# -*- encoding: SHIFT_JIS -*-
# frozen_string_literal: false
#
require_relative "AddressIndexer/version"
require 'csv'
module AddressIndexer
  class Error < StandardError; end

  @@csvOutPath = File.expand_path('./resources/csv/out')
  @@csvInPath = File.expand_path('./resources/csv/in')
  @@joinedRecordsCsvName = '/KEN_JOINED.csv'
  @@LFbytesize = 1

  # 課題０１CSVのインデクスファイル作成
  def kadai01_create_index_files(file_name)
    if File.exist? @@csvInPath + file_name
      # 複数行にある同じレコードを結合
      AddressIndexer.join_same_records file_name
      # 新しい作成したCSVをインデックスする
      AddressIndexer.index_csv_file '/KEN_JOINED.csv'
      # 新しく作成したCSVngramインデクス作成
      AddressIndexer.create_ngram_index_file '/KEN_JOINED.csv'
    else
      puts 'File not found'
    end
  end

  # 課題０２ユーザ入力検索し、出力
  def kadai02_search_and_output_result(user_input)
    if File.exist? @@csvInPath + '/KEN_JOINED.csv'
      AddressIndexer.search_using_ngram_and_index_files(user_input,'/KEN_JOINED.csv')
    else
      puts 'File not found. Run kadai01 first in order to generate indexed files.'
    end
  end

  # 複数行に同じ住所が別れっているレコードの結合
  def join_same_records(file_name)
    compare_address = ''
    loop_counter = 0
    records = []
    # 元データのレコード確認し、必要に応じて結合し、recordsに格納
    CSV.foreach(@@csvInPath + file_name, :encoding => 'shift_jis', :headers => false) do |row|
      csv_string = row[0] + row[1] + row[2] + row[3] + row[4] + row[5]
      if (compare_address == csv_string)
        records[loop_counter - 1][8] = records[loop_counter - 1][8] + row[8].to_s
      else
        records[loop_counter] = row
        loop_counter += 1
      end
      compare_address = csv_string
    end
    # recordsに格納したデータが新規CSVに出力
    CSV.open(@@csvInPath + @@joinedRecordsCsvName, 'wb', :encoding => 'shift_jis') do |csv|
      records.each { |row|
        csv << row
      }
    end

  end

  # CSVレコードのインデクスファイル作成
  def index_csv_file(file_name)
    csvAddressPath = @@csvInPath + file_name
    # 書くためCSV開く
    CSV.open(@@csvInPath + '/csvIndexFile.csv', "wb") do |csv|
      lineNo = 0
      startByte = -1
      # 行ごとにループし、データがCSVに出力
      IO.foreach(csvAddressPath) do |line|
        lineStr = []
        lineStr.append lineNo, startByte + 1, line.bytesize - @@LFbytesize
        csv << lineStr
        lineNo += 1
        startByte += line.bytesize
      end
    end
  end

  # Ngramインデクス作成
  def create_ngram_index_file(file_name)
    csvAddressPath = @@csvInPath + file_name
    pairIndex = {}
    recordNo = 0
    ngramIndexOutPath = @@csvInPath + '/ngramIndex.csv'
    # 希望カラムを設定
    compareCols = [6, 7, 8]
    ######################################
    # N-gramインデクス作成したいCSVにループ
    ######################################
    CSV.foreach(csvAddressPath, :encoding => 'shift_jis', :headers => false) do |str|
      # 希望カラムにループ
      compareCols.each do |colNumber|
        # カラムの文字列のループ管理番号
        stringLoop = 0
        # カラムの文字列に２桁ごとでループする
        while stringLoop != str[colNumber].length - 1 do
          # キーが既に追加されたかどうか確認
          if pairIndex.has_key?(str[colNumber][stringLoop..stringLoop + 1])
            # 存在する場合は行番号の存在確認
            if (!pairIndex[str[colNumber][stringLoop..stringLoop + 1]].include? recordNo)
              # 追加されていなかったら、行番号が追加
              pairIndex[str[colNumber][stringLoop..stringLoop + 1]].push(recordNo)
            end
          else
            # キーが存在しない場合キー追加し、レコード番号追加
            pairIndex[str[colNumber][stringLoop..stringLoop + 1]] = [recordNo]
          end
          stringLoop = stringLoop + 1
        end
      end
      recordNo += 1
    end
    # 格納した情報がCSVに出力
    CSV.open(ngramIndexOutPath, 'wb') do |csv|
      pairIndex.each_key { |key|
        # csv にキー、値形保存しています。値が配列より文字列に変更なっているので、後でロードする時にint型に変更が必要
        csv << [key, pairIndex[key]]
      }
    end
  end

  # 検索結果がCSVに出力
  def search_using_ngram_and_index_files(userInput, file_name)
    # 要件定義よりスペースは文字として扱わない。WhiteSpace削除
    userInput = userInput.gsub(/[[:space:]]/, '')
    # 検索結果出力するCSVファイル
    csvOutPath = @@csvOutPath + '/' + userInput + Time.new.strftime("%Y%m%d%H%M%S") + '.csv'
    # CSVにユーザ入力が見つけたかどうかのフラグ
    keyExistsFlag = false
    # ユーザ入力と一致したＣＳＶ行番号のリスト
    lineNumberList = []
    # ユーザ入力の文字列のループ管理
    userInputCharLoop = 0
    # ngramをインデクスされた情報
    pairIndex = {}

    ########################
    # 作成したindexをロードする
    ########################
    # インデクスされたＣＳＶファイルをロード
    indexed_csv_entries = CSV.read(@@csvInPath + '/csvIndexFile.csv', :encoding => 'shift_jis', :headers => false)
    # NGRAMのINDEXがpairIndexにロードする
    CSV.foreach(@@csvInPath + '/ngramIndex.csv', :encoding => 'shift_jis', :headers => false) do |csvLine|
      # csvLine[1]はまだ文字列なので、配列に変化する
      pairIndex[csvLine[0]] = csvLine[1][1..-2].split(',')
    end

    ########################
    # 入力された文字列を検索する
    ########################
    # ユーザ入力文字列に２個文字ごとでループ
    while userInputCharLoop != userInput.length - 1 do
      # ユーザ入力した値がHashにあるかどうか確認
      if pairIndex.has_key? userInput[userInputCharLoop..userInputCharLoop + 1]
        # キー存在する場合はキー存在フラグをtrueに設定
        keyExistsFlag = true
        # リスト結合し、同じ値をコピーしない
        lineNumberList = lineNumberList | pairIndex[userInput[userInputCharLoop..userInputCharLoop + 1]]
      end
      userInputCharLoop += 1
    end

    ########################
    # 結果が出力する
    ########################
    CSV.open(csvOutPath, "wb") do |csv|
      # ユーザ入力がCSVに一致する値を見つけった場合
      if keyExistsFlag == true
        # step1で整理したデータファイルを開く
        yuubin_csv_file = IO.new(IO.sysopen(@@csvInPath + file_name))
        # lineNumberListに格納した情報にループ
        lineNumberList.each { |lineNo|
          # 開始バイト設定
          start_byte = indexed_csv_entries[lineNo.to_i][1].to_i
          # 行バイトサイズ設定
          line_sizebyte = indexed_csv_entries[lineNo.to_i][2].to_i
          # カーソルのバイト設定
          yuubin_csv_file.sysseek(start_byte)
          # ファイル読んだ情報が配列に変化し、CSVに出力
          csv << yuubin_csv_file.sysread(line_sizebyte).split(',')
        }
      else
        # 見つからなかった場合、レコード見つかりませんでした出力
        csv << '入力に対してレコードが見つかりませんでした'
      end
    end
  end

  module_function :kadai01_create_index_files
  module_function :kadai02_search_and_output_result
  module_function :join_same_records
  module_function :index_csv_file
  module_function :create_ngram_index_file
  module_function :search_using_ngram_and_index_files

end