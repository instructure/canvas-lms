# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe WidgetDashboardLayoutValidator do
  describe ".default_educator_layout" do
    subject(:layout) { described_class.default_educator_layout }

    it "returns a new hash on each call" do
      expect(layout).not_to equal(described_class.default_educator_layout)
    end

    it "has the expected columns" do
      expect(layout["columns"]).to eq(2)
    end

    it "includes all educator widget types" do
      types = layout["widgets"].pluck("type")
      expect(types).to contain_exactly(
        "educator_announcement_creation",
        "educator_todo_list",
        "educator_content_quality"
      )
    end

    it "has unique widget positions" do
      positions = layout["widgets"].map { |w| [w.dig("position", "col"), w.dig("position", "row")] }
      expect(positions.uniq.length).to eq(positions.length)
    end

    it "has translated titles" do
      layout["widgets"].each do |widget|
        expect(widget["title"]).to be_a(String)
        expect(widget["title"]).not_to be_empty
      end
    end

    it "validates against its own validator" do
      validator = described_class.new(layout)
      expect(validator).to be_valid
    end

    it "uses only registered widget types" do
      layout["widgets"].each do |widget|
        expect(WidgetDashboardLayoutValidator::VALID_WIDGET_TYPES).to include(widget["type"])
      end
    end
  end

  describe ".sanitize_educator_layout" do
    it "returns nil unchanged when config is nil" do
      expect(described_class.sanitize_educator_layout(nil)).to be_nil
    end

    it "returns the config unchanged when the layout key is missing" do
      input = { "other" => "stuff" }
      expect(described_class.sanitize_educator_layout(input)).to eq(input)
    end

    it "drops non-educator widget types from a saved layout" do
      polluted = {
        "layout" => {
          "columns" => 2,
          "widgets" => [
            { "type" => "educator_announcement_creation" },
            { "type" => "course_work_combined" },
            { "type" => "course_grades" },
            { "type" => "educator_todo_list" }
          ]
        }
      }
      result = described_class.sanitize_educator_layout(polluted)
      expect(result["layout"]["widgets"].pluck("type")).to contain_exactly(
        "educator_announcement_creation",
        "educator_todo_list"
      )
    end

    it "does not mutate the input" do
      input = { "layout" => { "widgets" => [{ "type" => "course_grades" }] } }
      described_class.sanitize_educator_layout(input)
      expect(input["layout"]["widgets"]).to eq([{ "type" => "course_grades" }])
    end

    it "returns the config unchanged when layout is not a hash" do
      input = { "layout" => "garbage" }
      expect(described_class.sanitize_educator_layout(input)).to eq(input)
    end

    it "drops widget entries that are not hashes" do
      polluted = {
        "layout" => {
          "columns" => 2,
          "widgets" => [
            { "type" => "educator_announcement_creation" },
            "not a widget",
            nil,
            42,
            { "type" => "educator_todo_list" }
          ]
        }
      }
      result = described_class.sanitize_educator_layout(polluted)
      expect(result["layout"]["widgets"].pluck("type")).to contain_exactly(
        "educator_announcement_creation",
        "educator_todo_list"
      )
    end
  end
end
