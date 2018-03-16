# encoding: UTF-8
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

require "yaml"

describe Utf8Cleaner do
  it "should strip out invalid utf-8" do
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
end
