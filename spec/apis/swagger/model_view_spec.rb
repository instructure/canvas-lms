# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "swagger_helper"
require "model_view"

describe ModelView do
  let(:text) do
    "Example\n{\n \"properties\": [],\n \"deprecated\": true,\n \"deprecation_description\": \"A description.\" }"
  end

  let(:model) { double("Model", text:) }

  describe ".new_from_model" do
    it "is created from model" do
      view = ModelView.new_from_model(model)
      expect(view.name).to eq "Example"
      expect(view.properties).to eq []
    end

    it "parses the deprecated attribute" do
      view = ModelView.new_from_model(model)
      expect(view).to be_deprecated
    end

    it "parses the deprecation description" do
      view = ModelView.new_from_model(model)
      description = view.json_schema.dig("Example", "deprecation_description")
      expect(description).to eq "A description."
    end
  end

  it "generates a schema" do
    view = ModelView.new("Example", { "name" => { "type" => "string" } })
    expect(view.json_schema).to eq({
                                     "Example" => {
                                       "id" => "Example",
                                       "properties" => {
                                         "name" => {
                                           "type" => "string"
                                         }
                                       },
                                       "description" => "",
                                       "required" => [],
                                       "deprecated" => false,
                                       "deprecation_description" => ""
                                     }
                                   })
  end

  describe "#deprecated?" do
    let(:properties) do
      {
        "foo" => {
          "description" => "A description of the property.",
          "example" => "bar",
          "type" => "string"
        }
      }
    end

    it "returns true if the model is deprecated" do
      view = ModelView.new("Foo", properties, deprecated: true, deprecation_description: "A description.")
      expect(view).to be_deprecated
    end

    it "returns false if the model is not deprecated" do
      view = ModelView.new("Foo", properties)
      expect(view).not_to be_deprecated
    end
  end
end
