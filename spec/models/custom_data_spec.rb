# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CustomData do
  before :once do
    custom_data_model
  end

  describe "#get_data" do
    it "returns the same data that was set" do
      str = "lol hi"
      @custom_data.set_data(nil, str)
      expect(@custom_data.get_data(nil)).to eql str

      hsh = { "lol" => "hi", "wut" => "bye" }
      @custom_data.set_data(nil, hsh)
      expect(@custom_data.get_data(nil)).to eql hsh

      @custom_data.set_data("kewl/skope", str)
      expect(@custom_data.get_data("kewl/skope")).to eql str
    end

    it "recognizes sub-scopes of previously-set data" do
      @custom_data.set_data("kewl/skope", { "lol" => { "wut" => "ohai" } })
      expect(@custom_data.get_data("kewl/skope/lol/wut")).to eql "ohai"
    end

    it "returns sub-scopes when a wide scope is requested" do
      @custom_data.set_data("kewl/skope", { "lol" => { "wut" => "ohai" } })
      expect(@custom_data.get_data("kewl")).to eql({ "skope" => { "lol" => { "wut" => "ohai" } } })
    end

    it "raises ArgumentError for non-existing scopes" do
      @custom_data.set_data("kewl/skope", { "lol" => { "wut" => "ohai" } })
      expect { @custom_data.get_data("no/data/here") }.to raise_error(ArgumentError)
    end

    it "reads from data_json when available" do
      @custom_data.set_data("test", "value1")
      @custom_data.save!
      @custom_data.update_column(:data_json, { "d" => { "test" => "value2" } })

      expect(@custom_data["data"]).to eq({ "d" => { "test" => "value1" } })
      expect(@custom_data["data_json"]).to eq({ "d" => { "test" => "value2" } })
      expect(@custom_data.get_data("test")).to eq "value2"
    end

    it "reads from data when data_json is empty" do
      @custom_data.set_data("test", "value1")
      @custom_data.save!
      @custom_data.update_column(:data_json, {})

      expect(@custom_data["data"]).to eq({ "d" => { "test" => "value1" } })
      expect(@custom_data["data_json"]).to eq({})
      expect(@custom_data.get_data("test")).to eq "value1"
    end
  end

  describe "#set_data" do
    it "raises a WriteConflict when the requested scope is invalid" do
      @custom_data.set_data("kewl/skope", "ohai")
      expect { @custom_data.set_data("kewl/skope/plus/more", "bad idea dood") }.to raise_error(CustomData::WriteConflict)
    end

    it "writes to both data and data_json columns" do
      @custom_data.set_data("test_key", "test_value")
      @custom_data.save!

      expect(@custom_data["data"]).to include("d" => { "test_key" => "test_value" })
      expect(@custom_data["data_json"]).to include("d" => { "test_key" => "test_value" })
    end
  end

  describe "#delete_data" do
    it "deletes values" do
      @custom_data.set_data(nil, { "a" => 1, "b" => 2, "c" => 3 })
      expect(@custom_data.delete_data("a")).to be 1
      expect(@custom_data.get_data(nil)).to eql({ "b" => 2, "c" => 3 })
    end

    it "cleans up empty JSON Objects if they result from value removal" do
      @custom_data.set_data(nil, { "a" => { "b" => { "c" => "bonjour!" } }, "croissant" => "merci!" })
      expect(@custom_data.delete_data("a/b/c")).to eql "bonjour!"
      expect(@custom_data.get_data(nil)).to eql({ "croissant" => "merci!" })
    end

    it "destroys the entire record if all of its data is removed" do
      @custom_data.set_data(nil, { "a" => { "b" => { "c" => "bonjour!" } } })
      expect(@custom_data.delete_data("a/b/c")).to eql "bonjour!"
      expect(@custom_data.destroyed?).to be_truthy
    end

    it "raises ArgumentError for non-existing scopes" do
      @custom_data.set_data(nil, { "a" => 1, "b" => 2, "c" => 3 })
      expect { @custom_data.delete_data("d") }.to raise_error(ArgumentError)
    end
  end

  describe "#synchronize_data_fields" do
    it "synchronizes data when only data_json is changed" do
      @custom_data.set_data("test_key", "initial_value")
      @custom_data.save!

      expect(@custom_data["data"]).to include("d" => { "test_key" => "initial_value" })
      expect(@custom_data["data_json"]).to include("d" => { "test_key" => "initial_value" })

      @custom_data["data_json"] = { "d" => { "test_key" => "updated_value" } }
      @custom_data.save!

      expect(@custom_data["data"]).to eq({ "d" => { "test_key" => "updated_value" } })
      expect(@custom_data["data_json"]).to eq({ "d" => { "test_key" => "updated_value" } })
    end

    it "synchronizes data_json when only data is changed" do
      @custom_data.set_data("test_key", "initial_value")
      @custom_data.save!

      expect(@custom_data["data"]).to include("d" => { "test_key" => "initial_value" })
      expect(@custom_data["data_json"]).to include("d" => { "test_key" => "initial_value" })

      @custom_data["data"] = { "d" => { "test_key" => "updated_value" } }
      @custom_data.save!

      expect(@custom_data["data"]).to eq({ "d" => { "test_key" => "updated_value" } })
      expect(@custom_data["data_json"]).to eq({ "d" => { "test_key" => "updated_value" } })
    end

    it "prioritizes data_json when accessing data after manual column update" do
      @custom_data.set_data("test_key", "original_value")
      @custom_data.save!

      # Force data_json to be different using update_column
      @custom_data.update_column(:data_json, { "d" => { "test_key" => "forced_value" } })
      @custom_data.reload

      expect(@custom_data["data"]).to eq({ "d" => { "test_key" => "original_value" } })
      expect(@custom_data["data_json"]).to eq({ "d" => { "test_key" => "forced_value" } })
      expect(@custom_data.data).to eq({ "d" => { "test_key" => "forced_value" } })
      expect(@custom_data.data_json).to eq({ "d" => { "test_key" => "forced_value" } })
    end
  end
end
