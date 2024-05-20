# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe CoursePacing::PacePresenter do
  let(:pace) { course_pace_model }
  let(:presenter) { CoursePacing::PacePresenter.new(pace) }

  describe "#as_json" do
    it "requires implementation" do
      expect do
        presenter.as_json
      end.to raise_error NotImplementedError
    end
  end

  describe "private methods" do
    describe "default_json" do
      it "requires implementation" do
        expect do
          presenter.send(:default_json)
        end.to raise_error NotImplementedError
      end
    end

    describe "modules_json" do
      let(:course) { course_model }
      let(:my_module) { course.context_modules.create! }
      let(:assignment) { course.assignments.create! }
      let(:pace) { course_pace_model(course:) }

      before do
        assignment.context_module_tags.create!(
          context_module: my_module,
          context: course,
          tag_type: "context_module",
          workflow_state: "unpublished"
        )
      end

      it "returns an array of valid json" do
        json = presenter.send(:modules_json)
        expect(json.length).to eq 1
        module_json = json.first
        expect(module_json[:id]).to eq my_module.id
        expect(module_json[:name]).to eq my_module.name
        expect(module_json[:position]).to eq my_module.position
      end
    end

    describe "items_json" do
      let(:course) { course_model }
      let(:my_module) { course.context_modules.create! }
      let(:assignment) { course.assignments.create! }
      let(:pace) { course_pace_model(course:) }

      before do
        assignment.context_module_tags.create!(
          context_module: my_module,
          context: course,
          tag_type: "context_module",
          workflow_state: "unpublished"
        )
      end

      it "returns an empty array if no items are provided" do
        expect(presenter.send(:items_json, nil)).to eq []
      end

      it "returns json for the provided items" do
        pace_module_items = pace.course_pace_module_items
        pace_module_item = pace_module_items.first
        json_array = presenter.send(:items_json, pace_module_items)
        expect(json_array.length).to eq 1
        json = json_array.first
        expect(json[:id]).to eq pace_module_item.id
      end
    end

    describe "context_id" do
      it "requires implementation" do
        expect do
          presenter.send(:context_id)
        end.to raise_error NotImplementedError
      end
    end

    describe "context_type" do
      it "requires implementation" do
        expect do
          presenter.send(:context_type)
        end.to raise_error NotImplementedError
      end
    end
  end
end
