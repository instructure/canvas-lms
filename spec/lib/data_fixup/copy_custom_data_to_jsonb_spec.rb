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

require_relative "../../spec_helper"

describe DataFixup::CopyCustomDataToJsonb do
  before :once do
    @user = user_factory
    @namespace = "test.namespace"
    @custom_data = CustomData.create!(user: @user, namespace: @namespace, data: { "test" => "value" })

    # Ensure data_json is {} to simulate pre-migration state
    @custom_data.update_column(:data_json, {})
  end

  it "copies data to data_json" do
    expect(@custom_data["data"]).to eq({ "test" => "value" })
    expect(@custom_data["data_json"]).to eq({})
    DataFixup::CopyCustomDataToJsonb.run

    @custom_data.reload
    expect(@custom_data["data"]).to eq({ "test" => "value" })
    expect(@custom_data["data_json"]).to eq({ "test" => "value" })
  end

  it "skips records that already have data_json populated" do
    custom_data2 = CustomData.create!(user: @user, namespace: "#{@namespace}.2", data: { "original" => "data" })
    custom_data2.update_column(:data_json, { "already" => "migrated" })

    DataFixup::CopyCustomDataToJsonb.run

    custom_data2.reload
    expect(custom_data2["data"]).to eq({ "original" => "data" })
    expect(custom_data2["data_json"]).to eq({ "already" => "migrated" })
  end

  it "skips records with empty data" do
    custom_data_empty = CustomData.create!(user: @user, namespace: "#{@namespace}.empty", data: {})

    # This simulates a record that should be skipped because data_json is already populated
    custom_data_populated = CustomData.create!(user: @user, namespace: "#{@namespace}.populated", data: {})
    custom_data_populated.update_column(:data_json, { "already" => "populated" })

    DataFixup::CopyCustomDataToJsonb.run

    custom_data_empty.reload
    expect(custom_data_empty["data"]).to eq({})
    expect(custom_data_empty["data_json"]).to eq({})

    custom_data_populated.reload
    expect(custom_data_populated["data"]).to eq({})
    expect(custom_data_populated["data_json"]).to eq({ "already" => "populated" })
  end

  it "handles nested hash data" do
    nested_data = {
      "a" => {
        "b" => {
          "c" => "value"
        }
      }
    }
    custom_data2 = CustomData.create!(user: @user, namespace: "#{@namespace}.2", data: nested_data)
    custom_data2.update_column(:data_json, {})

    DataFixup::CopyCustomDataToJsonb.run

    custom_data2.reload
    expect(custom_data2["data"]).to eq(nested_data)
    expect(custom_data2["data_json"]).to eq(nested_data)
  end

  it "skips validations" do
    @custom_data.user.delete

    expect { DataFixup::CopyCustomDataToJsonb.run }.not_to raise_error
  end
end
