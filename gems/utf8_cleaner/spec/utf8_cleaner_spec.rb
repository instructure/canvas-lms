# encoding: UTF-8
#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require "spec_helper"

if RUBY_VERSION >= '2.0.0'
  require 'syck'
end
YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE)

describe Utf8Cleaner do
  it "should strip out invalid utf-8" do
    test_strings = {
        "hai\xfb" => "hai",
        "hai\xfb there" => "hai there",
        "hai\xfba" => "haia",
        "hai\xfbab" => "haiab",
        "hai\xfbabc" => "haiabc",
        "hai\xfbabcd" => "haiabcd"
    }

    test_strings.each do |input, output|
      input = input.dup.force_encoding("UTF-8")
      Utf8Cleaner.strip_invalid_utf8(input).should == output
    end
  end

  describe "YAML invalid UTF8 stripping" do
    it "should recursively strip out invalid utf-8" do
      data = YAML.load(<<-YAML)
---
answers:
- !map:Hash
  id: 2
  text: t\xEAwo
  valid_ascii: !binary |
    oHRleHSg
YAML
      answer = data['answers'][0]['text']
      answer.valid_encoding?.should be_false
      Utf8Cleaner.recursively_strip_invalid_utf8!(data, true)
      answer.should == "two"
      answer.encoding.should == Encoding::UTF_8
      answer.valid_encoding?.should be_true

      # in some edge cases, Syck will return a string as ASCII-8BIT if it's not valid UTF-8
      # so we added a force_encoding step to recursively_strip_invalid_utf8!
      ascii = data['answers'][0]['valid_ascii']
      ascii.should == 'text'
      ascii.encoding.should == Encoding::UTF_8
    end
  end
end