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
end
