# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

require 'spec_helper'# File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CanvasTextHelper do

  describe "#truncate_text" do
    it "should not split if max_length is exact text length" do
      str = "I am an exact length"
      CanvasTextHelper::truncate_text(str, :max_length => str.length).should == str
    end

    it "should split on multi-byte character boundaries" do
      str = "This\ntext\nhere\n获\nis\nutf-8"

      CanvasTextHelper::truncate_text(str, :max_length => 9).should ==  "This\nt..."
      CanvasTextHelper::truncate_text(str, :max_length => 18).should == "This\ntext\nhere\n..."
      CanvasTextHelper::truncate_text(str, :max_length => 19).should == "This\ntext\nhere\n获..."
      CanvasTextHelper::truncate_text(str, :max_length => 20).should == "This\ntext\nhere\n获\n..."
      CanvasTextHelper::truncate_text(str, :max_length => 21).should == "This\ntext\nhere\n获\ni..."
      CanvasTextHelper::truncate_text(str, :max_length => 22).should == "This\ntext\nhere\n获\nis..."
      CanvasTextHelper::truncate_text(str, :max_length => 23).should == "This\ntext\nhere\n获\nis\n..."
      CanvasTextHelper::truncate_text(str, :max_length => 80).should == str
    end

    it "should split on words if specified" do
      str = "I am a sentence with areallylongwordattheendthatcantbesplit and then a few more words"
      CanvasTextHelper::truncate_text(str, :max_words => 4, :max_length => 30).should == "I am a sentence"
      CanvasTextHelper::truncate_text(str, :max_words => 6, :max_length => 30).should == "I am a sentence with areall..."
      CanvasTextHelper::truncate_text(str, :max_words => 5, :max_length => 20).should == "I am a sentence with"
    end
  end

  describe "#indent" do
    it "should prepend two spaces to each line after the first by default" do
      CanvasTextHelper::indent("test string\nnext line\nanother line").should == "test string\n  next line\n  another line"
    end

    it "should prepend n spaces to each line after the first" do
      CanvasTextHelper::indent("test string\nnext line\nanother line", 0).should == "test string\nnext line\nanother line"
      CanvasTextHelper::indent("test string\nnext line\nanother line", 1).should == "test string\n next line\n another line"
      CanvasTextHelper::indent("test string\nnext line\nanother line", 2).should == "test string\n  next line\n  another line"
      CanvasTextHelper::indent("test string\nnext line\nanother line", 3).should == "test string\n   next line\n   another line"
    end
  end

  describe "cgi_escape_truncate" do
    it "should not truncate strings that fit" do
      CanvasTextHelper::cgi_escape_truncate('!!!', 9).should eql("%21%21%21")
    end

    it "should not split escape sequences" do
      CanvasTextHelper::cgi_escape_truncate('!!!', 8).should eql("%21%21")
    end

    it "should not split UTF-8 characters" do
      CanvasTextHelper::cgi_escape_truncate("\u2600\u2603", 15).should eql("%E2%98%80")
    end
  end
end
