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
      expect(CanvasTextHelper::truncate_text(str, :max_length => str.length)).to eq(str)
    end

    it "should split on multi-byte character boundaries" do
      str = "This\ntext\nhere\n获\nis\nutf-8"

      expect(CanvasTextHelper::truncate_text(str, :max_length => 9)).to eq("This\nt...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 18)).to eq("This\ntext\nhere\n...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 19)).to eq("This\ntext\nhere\n获...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 20)).to eq("This\ntext\nhere\n获\n...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 21)).to eq("This\ntext\nhere\n获\ni...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 22)).to eq("This\ntext\nhere\n获\nis...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 23)).to eq("This\ntext\nhere\n获\nis\n...")
      expect(CanvasTextHelper::truncate_text(str, :max_length => 80)).to eq(str)
    end

    it "should split on words if specified" do
      str = "I am a sentence with areallylongwordattheendthatcantbesplit and then a few more words"
      expect(CanvasTextHelper::truncate_text(str, :max_words => 4, :max_length => 30)).to eq("I am a sentence")
      expect(CanvasTextHelper::truncate_text(str, :max_words => 6, :max_length => 30)).to eq("I am a sentence with areall...")
      expect(CanvasTextHelper::truncate_text(str, :max_words => 5, :max_length => 20)).to eq("I am a sentence with")
    end
  end

  describe "#indent" do
    it "should prepend two spaces to each line after the first by default" do
      expect(CanvasTextHelper::indent("test string\nnext line\nanother line")).to eq("test string\n  next line\n  another line")
    end

    it "should prepend n spaces to each line after the first" do
      expect(CanvasTextHelper::indent("test string\nnext line\nanother line", 0)).to eq("test string\nnext line\nanother line")
      expect(CanvasTextHelper::indent("test string\nnext line\nanother line", 1)).to eq("test string\n next line\n another line")
      expect(CanvasTextHelper::indent("test string\nnext line\nanother line", 2)).to eq("test string\n  next line\n  another line")
      expect(CanvasTextHelper::indent("test string\nnext line\nanother line", 3)).to eq("test string\n   next line\n   another line")
    end
  end

  describe "cgi_escape_truncate" do
    it "should not truncate strings that fit" do
      expect(CanvasTextHelper::cgi_escape_truncate('!!!', 9)).to eql("%21%21%21")
    end

    it "should not split escape sequences" do
      expect(CanvasTextHelper::cgi_escape_truncate('!!!', 8)).to eql("%21%21")
    end

    it "should not split UTF-8 characters" do
      expect(CanvasTextHelper::cgi_escape_truncate("\u2600\u2603", 15)).to eql("%E2%98%80")
    end
  end
end
