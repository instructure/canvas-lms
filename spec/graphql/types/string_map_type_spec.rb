# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "graphql"
require_relative "../graphql_spec_helper"

describe Types::StringMapType do
  let(:type) { described_class }

  describe ".coerce_input" do
    it "returns nil if the input is nil" do
      expect(type.coerce_input(nil, nil)).to be_nil
    end

    it "returns the input value if it is a valid StringMap" do
      input = { "key1" => "value1", "key2" => "value2" }
      expect(type.coerce_input(input, nil)).to eq(input)
    end

    it "raises a CoercionError if the input is not a Hash" do
      input = "not a hash"
      expect { type.coerce_input(input, nil) }.to raise_error(GraphQL::CoercionError)
    end

    it "raises a CoercionError if any key is not a String" do
      input = { :key1 => "value1", "key2" => "value2" }
      expect { type.coerce_input(input, nil) }.to raise_error(GraphQL::CoercionError)
    end

    it "raises a CoercionError if any value is not a String" do
      input = { "key1" => 1, "key2" => "value2" }
      expect { type.coerce_input(input, nil) }.to raise_error(GraphQL::CoercionError)
    end

    it "can handle ActionController::Parameters" do
      input = ActionController::Parameters.new({ "key1" => "value1", "key2" => "value2" })
      expect(type.coerce_input(input, nil)).to eq({ "key1" => "value1", "key2" => "value2" })
    end

    it "raises a CoercionError if ActionController::Parameters contains non-string keys or values" do
      input = ActionController::Parameters.new({ :key1 => "value1", "key2" => ActionController::Parameters.new("nested_key" => "nested_value") })
      expect { type.coerce_input(input, nil) }.to raise_error(GraphQL::CoercionError)
    end
  end

  describe ".coerce_result" do
    it "returns the result with stringified keys if it is a valid StringMap" do
      value = { :key1 => "value1", "key2" => "value2" }
      expected = { "key1" => "value1", "key2" => "value2" }
      expect(type.coerce_result(value, nil)).to eq(expected)
    end

    it "raises a CoercionError if the result is not a Hash" do
      value = "not a hash"
      expect { type.coerce_result(value, nil) }.to raise_error(GraphQL::CoercionError)
    end

    it "raises a CoercionError if any value is not a String" do
      value = { "key1" => 1, "key2" => "value2" }
      expect { type.coerce_result(value, nil) }.to raise_error(GraphQL::CoercionError)
    end
  end
end
