# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Utf8Cleaner do
  it "strips out invalid utf-8" do
    test_strings = {
      "hai\xfb" => "hai",
      "hai\xfb there" => "hai there",
      "hai\xfba" => "haia",
      "hai\xfbab" => "haiab",
      "hai\xfbabc" => "haiabc",
      "hai\xfbabcd" => "haiabcd",
      "o\bhai" => "ohai",
      "\x7Fohai" => "ohai"
    }

    test_strings.each do |input, output|
      input = input.dup.force_encoding("UTF-8")
      expect(Utf8Cleaner.strip_invalid_utf8(input)).to eq(output)
    end
  end

  it "strips out invalid characters from non-UTF-8 strings" do
    ascii = String.new("\x7Fohai", encoding: Encoding::ASCII)
    expect(Utf8Cleaner.strip_invalid_utf8(ascii)).to eql("ohai")
  end

  it "strips out invalid characters from frozen strings" do
    frozen = "\x7Fohai".freeze
    expect(Utf8Cleaner.strip_invalid_utf8(frozen)).to eql("ohai")
  end

  it "strips out invalid characters from frozen non-UTF-8 strings" do
    frigidus = String.new("\x7Ffrigidus", encoding: Encoding::ISO_8859_1)
    frigidus.freeze
    expect(Utf8Cleaner.strip_invalid_utf8(frigidus)).to eql("frigidus")
  end
end
