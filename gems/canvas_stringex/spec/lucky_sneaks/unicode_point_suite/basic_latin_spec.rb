require "spec_helper"

require File.join(File.dirname(__FILE__), "codepoint_test_helper")
include CodepointTestHelper

describe "BasicLatin" do
  # This test suite is just regression test and debugging
  # to better transliterate the Basic Latin Unicode codepoints
  # 
  # http://unicode.org/charts/
  # http://unicode.org/charts/PDF/U0000.pdf
  
  # NOTE: I can't figure out how to test control characters.
  # Get weird results trying to pack them to unicode.
  
  it "spaces" do
    assert_equal_encoded " ", %w{0020 00a0}
    assert_equal_encoded "",  %w{200b 2060}
  end
  
  it "exclamation_marks" do
    assert_equal_encoded "!", %w{0021 2762}
    assert_equal_encoded "!!", "203c"
    assert_equal_encoded "", "00a1"
    assert_equal_encoded "?!", "203d"
  end
  
  it "quotation_marks" do
    assert_equal_encoded "\"", %w{0022 02ba 2033 3003}
  end
  
  it "apostrophes" do
    assert_equal_encoded "'", %w{0027 02b9 02bc 02c8 2032}
  end
  
  it "asterisks" do
    assert_equal_encoded "*", %w{002a 066d 204e 2217 26b9 2731}
  end
  
  it "commas" do
    assert_equal_encoded ",", %w{002c 060c}
  end
  
  it "periods" do
    assert_equal_encoded ".", %w{002e 06d4}
  end
  
  it "hyphens" do
    assert_equal_encoded "-", %w{002d 2010 2011 2012 2013 2212}
  end
  
  it "slashes" do
    assert_equal_encoded "/", %w{002f 2044 2215}
    assert_equal_encoded "\\", %w{005c 2216}
  end
  
  it "colons" do
    assert_equal_encoded ":", %w{003a 2236}
  end
  
  it "semicolons" do
    assert_equal_encoded ";", %w{003b 061b}
  end
  
  it "less_thans" do
    assert_equal_encoded "<", %w{003c 2039 2329 27e8 3008}
  end
  
  it "equals" do
    assert_equal_encoded "=", "003d"
  end
  
  it "greater_thans" do
    assert_equal_encoded ">", %w{003e 203a 232a 27e9 3009}
  end
  
  it "question_marks" do
    assert_equal_encoded "?", %w{003f 061f}
    assert_equal_encoded "", "00bf"
    assert_equal_encoded "?!", %w{203d 2048}
    assert_equal_encoded "!?", "2049"
  end
  
  it "circumflexes" do
    assert_equal_encoded "^", %w{005e 2038 2303}
  end
  
  it "underscores" do
    assert_equal_encoded "_", %w{005f 02cd 2017}
  end
  
  it "grave_accents" do
    assert_equal_encoded "`", %w{0060 02cb 2035}
  end
  
  it "bars" do
    assert_equal_encoded "|", %w{007c 2223 2758}
  end
  
  it "tildes" do
    assert_equal_encoded "~", %w{007e 02dc 2053 223c ff5e}
  end
  
  it "related_letters" do
    {
      "B" => "212c",
      "C" => %w{2102 212d},
      "E" => %w{2107 2130},
      "F" => "2131",
      "H" => %w{210b 210c 210d},
      "I" => %w{0130 0406 04c0 2110 2111 2160},
      "K" => "212a",
      "L" => "2112",
      "M" => "2133",
      "N" => "2115",
      "P" => "2119",
      "Q" => "211a",
      "R" => %w{211b 211c 211d},
      "Z" => %w{2124 2128}
    }.each do |expected, encode_mes|
      assert_equal_encoded expected, encode_mes
    end
  end
end