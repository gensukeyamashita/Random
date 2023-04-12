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

  # �ۑ�O�PCSV�̃C���f�N�X�t�@�C���쐬
  def kadai01_create_index_files(file_name)
    if File.exist? @@csvInPath + file_name
      # �����s�ɂ��铯�����R�[�h������
      AddressIndexer.join_same_records file_name
      # �V�����쐬����CSV���C���f�b�N�X����
      AddressIndexer.index_csv_file '/KEN_JOINED.csv'
      # �V�����쐬����CSVngram�C���f�N�X�쐬
      AddressIndexer.create_ngram_index_file '/KEN_JOINED.csv'
    else
      puts 'File not found'
    end
  end

  # �ۑ�O�Q���[�U���͌������A�o��
  def kadai02_search_and_output_result(user_input)
    if File.exist? @@csvInPath + '/KEN_JOINED.csv'
      AddressIndexer.search_using_ngram_and_index_files(user_input,'/KEN_JOINED.csv')
    else
      puts 'File not found. Run kadai01 first in order to generate indexed files.'
    end
  end

  # �����s�ɓ����Z�����ʂ���Ă��郌�R�[�h�̌���
  def join_same_records(file_name)
    compare_address = ''
    loop_counter = 0
    records = []
    # ���f�[�^�̃��R�[�h�m�F���A�K�v�ɉ����Č������Arecords�Ɋi�[
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
    # records�Ɋi�[�����f�[�^���V�KCSV�ɏo��
    CSV.open(@@csvInPath + @@joinedRecordsCsvName, 'wb', :encoding => 'shift_jis') do |csv|
      records.each { |row|
        csv << row
      }
    end

  end

  # CSV���R�[�h�̃C���f�N�X�t�@�C���쐬
  def index_csv_file(file_name)
    csvAddressPath = @@csvInPath + file_name
    # ��������CSV�J��
    CSV.open(@@csvInPath + '/csvIndexFile.csv', "wb") do |csv|
      lineNo = 0
      startByte = -1
      # �s���ƂɃ��[�v���A�f�[�^��CSV�ɏo��
      IO.foreach(csvAddressPath) do |line|
        lineStr = []
        lineStr.append lineNo, startByte + 1, line.bytesize - @@LFbytesize
        csv << lineStr
        lineNo += 1
        startByte += line.bytesize
      end
    end
  end

  # Ngram�C���f�N�X�쐬
  def create_ngram_index_file(file_name)
    csvAddressPath = @@csvInPath + file_name
    pairIndex = {}
    recordNo = 0
    ngramIndexOutPath = @@csvInPath + '/ngramIndex.csv'
    # ��]�J������ݒ�
    compareCols = [6, 7, 8]
    ######################################
    # N-gram�C���f�N�X�쐬������CSV�Ƀ��[�v
    ######################################
    CSV.foreach(csvAddressPath, :encoding => 'shift_jis', :headers => false) do |str|
      # ��]�J�����Ƀ��[�v
      compareCols.each do |colNumber|
        # �J�����̕�����̃��[�v�Ǘ��ԍ�
        stringLoop = 0
        # �J�����̕�����ɂQ�����ƂŃ��[�v����
        while stringLoop != str[colNumber].length - 1 do
          # �L�[�����ɒǉ����ꂽ���ǂ����m�F
          if pairIndex.has_key?(str[colNumber][stringLoop..stringLoop + 1])
            # ���݂���ꍇ�͍s�ԍ��̑��݊m�F
            if (!pairIndex[str[colNumber][stringLoop..stringLoop + 1]].include? recordNo)
              # �ǉ�����Ă��Ȃ�������A�s�ԍ����ǉ�
              pairIndex[str[colNumber][stringLoop..stringLoop + 1]].push(recordNo)
            end
          else
            # �L�[�����݂��Ȃ��ꍇ�L�[�ǉ����A���R�[�h�ԍ��ǉ�
            pairIndex[str[colNumber][stringLoop..stringLoop + 1]] = [recordNo]
          end
          stringLoop = stringLoop + 1
        end
      end
      recordNo += 1
    end
    # �i�[�������CSV�ɏo��
    CSV.open(ngramIndexOutPath, 'wb') do |csv|
      pairIndex.each_key { |key|
        # csv �ɃL�[�A�l�`�ۑ����Ă��܂��B�l���z���蕶����ɕύX�Ȃ��Ă���̂ŁA��Ń��[�h���鎞��int�^�ɕύX���K�v
        csv << [key, pairIndex[key]]
      }
    end
  end

  # �������ʂ�CSV�ɏo��
  def search_using_ngram_and_index_files(userInput, file_name)
    # �v����`���X�y�[�X�͕����Ƃ��Ĉ���Ȃ��BWhiteSpace�폜
    userInput = userInput.gsub(/[[:space:]]/, '')
    # �������ʏo�͂���CSV�t�@�C��
    csvOutPath = @@csvOutPath + '/' + userInput + Time.new.strftime("%Y%m%d%H%M%S") + '.csv'
    # CSV�Ƀ��[�U���͂����������ǂ����̃t���O
    keyExistsFlag = false
    # ���[�U���͂ƈ�v�����b�r�u�s�ԍ��̃��X�g
    lineNumberList = []
    # ���[�U���͂̕�����̃��[�v�Ǘ�
    userInputCharLoop = 0
    # ngram���C���f�N�X���ꂽ���
    pairIndex = {}

    ########################
    # �쐬����index�����[�h����
    ########################
    # �C���f�N�X���ꂽ�b�r�u�t�@�C�������[�h
    indexed_csv_entries = CSV.read(@@csvInPath + '/csvIndexFile.csv', :encoding => 'shift_jis', :headers => false)
    # NGRAM��INDEX��pairIndex�Ƀ��[�h����
    CSV.foreach(@@csvInPath + '/ngramIndex.csv', :encoding => 'shift_jis', :headers => false) do |csvLine|
      # csvLine[1]�͂܂�������Ȃ̂ŁA�z��ɕω�����
      pairIndex[csvLine[0]] = csvLine[1][1..-2].split(',')
    end

    ########################
    # ���͂��ꂽ���������������
    ########################
    # ���[�U���͕�����ɂQ�������ƂŃ��[�v
    while userInputCharLoop != userInput.length - 1 do
      # ���[�U���͂����l��Hash�ɂ��邩�ǂ����m�F
      if pairIndex.has_key? userInput[userInputCharLoop..userInputCharLoop + 1]
        # �L�[���݂���ꍇ�̓L�[���݃t���O��true�ɐݒ�
        keyExistsFlag = true
        # ���X�g�������A�����l���R�s�[���Ȃ�
        lineNumberList = lineNumberList | pairIndex[userInput[userInputCharLoop..userInputCharLoop + 1]]
      end
      userInputCharLoop += 1
    end

    ########################
    # ���ʂ��o�͂���
    ########################
    CSV.open(csvOutPath, "wb") do |csv|
      # ���[�U���͂�CSV�Ɉ�v����l�����������ꍇ
      if keyExistsFlag == true
        # step1�Ő��������f�[�^�t�@�C�����J��
        yuubin_csv_file = IO.new(IO.sysopen(@@csvInPath + file_name))
        # lineNumberList�Ɋi�[�������Ƀ��[�v
        lineNumberList.each { |lineNo|
          # �J�n�o�C�g�ݒ�
          start_byte = indexed_csv_entries[lineNo.to_i][1].to_i
          # �s�o�C�g�T�C�Y�ݒ�
          line_sizebyte = indexed_csv_entries[lineNo.to_i][2].to_i
          # �J�[�\���̃o�C�g�ݒ�
          yuubin_csv_file.sysseek(start_byte)
          # �t�@�C���ǂ񂾏�񂪔z��ɕω����ACSV�ɏo��
          csv << yuubin_csv_file.sysread(line_sizebyte).split(',')
        }
      else
        # ������Ȃ������ꍇ�A���R�[�h������܂���ł����o��
        csv << '���͂ɑ΂��ă��R�[�h��������܂���ł���'
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