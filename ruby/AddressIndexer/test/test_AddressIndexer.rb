# -*- encoding: SHIFT_JIS -*-
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../test", __dir__)
require "test_helper"

class TestAddressIndexer < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AddressIndexer::VERSION
  end
  def test_kadai01
    AddressIndexer.kadai01_create_index_files '/KEN_ALL.csv'
  end
  def test_kadai02
    AddressIndexer.kadai02_search_and_output_result '東京都'
  end
end
