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

describe PacePlanPresenter do
  describe '#as_json' do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      pace_plan_model(course: @course)

      @mod1 = @course.context_modules.create! name: 'M1'
      @a1 = @course.assignments.create! name: 'A1', workflow_state: 'active'
      @mod1.add_item id: @a1.id, type: 'assignment'

      @mod2 = @course.context_modules.create! name: 'M2'
      @a2 = @course.assignments.create! name: 'A2', workflow_state: 'unpublished'
      @mod2.add_item id: @a2.id, type: 'assignment'
      @a3 = @course.assignments.create! name: 'A3', workflow_state: 'active'
      @mod2.add_item id: @a3.id, type: 'assignment'

      @course.context_module_tags.each do |tag|
        @pace_plan.pace_plan_module_items.create! module_item: tag
      end
    end

    it 'returns all necessary data for the pace plan' do
      formatted_plan = PacePlanPresenter.new(@pace_plan).as_json

      expect(formatted_plan[:id]).to eq(@pace_plan.id)
      expect(formatted_plan[:context_id]).to eq(@pace_plan.course_id)
      expect(formatted_plan[:context_type]).to eq('Course')
      expect(formatted_plan[:course_id]).to eq(@pace_plan.course_id)
      expect(formatted_plan[:course_section_id]).to eq(@pace_plan.course_section_id)
      expect(formatted_plan[:user_id]).to eq(@pace_plan.user_id)
      expect(formatted_plan[:workflow_state]).to eq(@pace_plan.workflow_state)
      expect(formatted_plan[:end_date]).to eq(@pace_plan.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(@pace_plan.exclude_weekends)
      expect(formatted_plan[:hard_end_dates]).to eq(@pace_plan.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(@pace_plan.created_at)
      expect(formatted_plan[:updated_at]).to eq(@pace_plan.updated_at)
      expect(formatted_plan[:published_at]).to eq(@pace_plan.published_at)
      expect(formatted_plan[:root_account_id]).to eq(@pace_plan.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:module_item_type]).to eq('Assignment')
      expect(first_module_item[:published]).to eq(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:module_item_type]).to eq('Assignment')
      expect(first_module_item[:published]).to eq(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:module_item_type]).to eq('Assignment')
      expect(second_module_item[:published]).to eq(true)
    end

    it 'returns necessary data if the pace plan is only instantiated' do
      pace_plan = @course.pace_plans.new
      @course.context_module_tags.each do |module_item|
        pace_plan.pace_plan_module_items.new module_item: module_item, duration: 0
      end
      formatted_plan = PacePlanPresenter.new(pace_plan).as_json

      expect(formatted_plan[:id]).to eq(pace_plan.id)
      expect(formatted_plan[:context_id]).to eq(pace_plan.course_id)
      expect(formatted_plan[:context_type]).to eq('Course')
      expect(formatted_plan[:course_id]).to eq(pace_plan.course_id)
      expect(formatted_plan[:course_section_id]).to eq(pace_plan.course_section_id)
      expect(formatted_plan[:user_id]).to eq(pace_plan.user_id)
      expect(formatted_plan[:workflow_state]).to eq(pace_plan.workflow_state)
      expect(formatted_plan[:end_date]).to eq(pace_plan.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(pace_plan.exclude_weekends)
      expect(formatted_plan[:hard_end_dates]).to eq(pace_plan.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(pace_plan.created_at)
      expect(formatted_plan[:updated_at]).to eq(pace_plan.updated_at)
      expect(formatted_plan[:published_at]).to eq(pace_plan.published_at)
      expect(formatted_plan[:root_account_id]).to eq(pace_plan.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:module_item_type]).to eq('Assignment')
      expect(first_module_item[:published]).to eq(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:module_item_type]).to eq('Assignment')
      expect(first_module_item[:published]).to eq(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:module_item_type]).to eq('Assignment')
      expect(second_module_item[:published]).to eq(true)
    end
  end
end
