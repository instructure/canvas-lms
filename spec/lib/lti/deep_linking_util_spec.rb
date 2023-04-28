# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe Lti::DeepLinkingUtil do
  describe ".validate_custom_params" do
    it "returns nil if not a hash or JSON string of a hash" do
      [123, "foo", "123", "null", "true", "undefined", 1.0, 1, true, false, nil].each do |input|
        expect(described_class.validate_custom_params(input)).to be_nil
      end
    end

    it "parses JSON if necessary" do
      val = { "foo" => "bar" }
      expect(described_class.validate_custom_params(val)).to eq(val)
      expect(described_class.validate_custom_params(val.to_json)).to eq(val)
    end

    it "removes non-string keys and non-string/number/boolean/nil values" do
      val = {
        "foo" => "bar",
        "bool1" => true,
        "bool2" => false,
        "abc" => {},
        "def" => { "ghi" => "jkl" },
        "mno" => nil,
        "pqr" => 1,
        1 => "one",
        "badscalar" => Object.new
      }

      expected = {
        "foo" => "bar", "mno" => nil, "pqr" => 1, "bool1" => true, "bool2" => false
      }
      expect(described_class.validate_custom_params(val)).to eq(expected)
      expect(described_class.validate_custom_params(val.to_json)).to eq(
        expected.merge("1" => "one")
      )
    end

    it "stringifies keys" do
      # Not 100% sure necessary, but safer
      val = { foo: "bar" }
      expect(described_class.validate_custom_params(val)).to eq("foo" => "bar")
    end
  end
end
