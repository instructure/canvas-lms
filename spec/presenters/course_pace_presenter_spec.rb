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

describe CoursePacePresenter do
  describe "#as_json" do
    before :once do
      course_with_teacher(active_all: true)
      @course.root_account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      student_in_course(active_all: true)
      course_pace_model(course: @course)

      @mod1 = @course.context_modules.create! name: "M1"
      @a1 = @course.assignments.create! name: "A1", points_possible: 100, workflow_state: "active"
      @ct1 = @mod1.add_item id: @a1.id, type: "assignment"

      @mod2 = @course.context_modules.create! name: "M2"
      @a2 = @course.assignments.create! name: "A2", points_possible: 50, workflow_state: "unpublished"
      @ct2 = @mod2.add_item id: @a2.id, type: "assignment"
      @a3 = @course.assignments.create! name: "A3", workflow_state: "active"
      @ct3 = @mod2.add_item id: @a3.id, type: "assignment"
    end

    it "returns all necessary data for the course pace" do
      formatted_plan = CoursePacePresenter.new(@course_pace).as_json

      expect(formatted_plan[:id]).to eq(@course_pace.id)
      expect(formatted_plan[:context_id]).to eq(@course_pace.course_id)
      expect(formatted_plan[:context_type]).to eq("Course")
      expect(formatted_plan[:course_id]).to eq(@course_pace.course_id)
      expect(formatted_plan[:course_section_id]).to eq(@course_pace.course_section_id)
      expect(formatted_plan[:user_id]).to eq(@course_pace.user_id)
      expect(formatted_plan[:workflow_state]).to eq(@course_pace.workflow_state)
      expect(formatted_plan[:end_date]).to eq(@course_pace.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(@course_pace.exclude_weekends)
      expect(formatted_plan[:hard_end_dates]).to eq(@course_pace.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(@course_pace.created_at)
      expect(formatted_plan[:updated_at]).to eq(@course_pace.updated_at)
      expect(formatted_plan[:published_at]).to eq(@course_pace.published_at)
      expect(formatted_plan[:root_account_id]).to eq(@course_pace.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(100)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct1.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(50)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct2.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:points_possible]).to be_nil
      expect(second_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct3.id}")
      expect(second_module_item[:module_item_type]).to eq("Assignment")
      expect(second_module_item[:published]).to be(true)
    end

    it "returns necessary data if the course pace is only instantiated" do
      course_pace = @course.course_paces.new
      @course.context_module_tags.each do |module_item|
        course_pace.course_pace_module_items.new module_item:, duration: 0
      end
      formatted_plan = CoursePacePresenter.new(course_pace).as_json

      expect(formatted_plan[:id]).to eq(course_pace.id)
      expect(formatted_plan[:context_id]).to eq(course_pace.course_id)
      expect(formatted_plan[:context_type]).to eq("Course")
      expect(formatted_plan[:course_id]).to eq(course_pace.course_id)
      expect(formatted_plan[:course_section_id]).to eq(course_pace.course_section_id)
      expect(formatted_plan[:user_id]).to eq(course_pace.user_id)
      expect(formatted_plan[:workflow_state]).to eq(course_pace.workflow_state)
      expect(formatted_plan[:end_date]).to eq(course_pace.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(course_pace.exclude_weekends)
      expect(formatted_plan[:hard_end_dates]).to eq(course_pace.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(course_pace.created_at)
      expect(formatted_plan[:updated_at]).to eq(course_pace.updated_at)
      expect(formatted_plan[:published_at]).to eq(course_pace.published_at)
      expect(formatted_plan[:root_account_id]).to eq(course_pace.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(100)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct1.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(50)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct2.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:points_possible]).to be_nil
      expect(second_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct3.id}")
      expect(second_module_item[:module_item_type]).to eq("Assignment")
      expect(second_module_item[:published]).to be(true)
    end
  end
end
