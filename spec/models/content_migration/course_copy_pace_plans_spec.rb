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

require_relative "course_copy_helper"

describe ContentMigration do
  before do
    stub_const("EXCLUDE_WEEKENDS_WORK_WEEK_DAYS", [])
    stub_const("NOT_EXCLUDE_WEEKENDS_WORK_WEEK_DAYS", %w[sun sat])
  end

  context "course paces" do
    include_context "course copy"

    it "copies course pace attributes" do
      course_pace = @copy_from.course_paces.new
      course_pace.workflow_state = "active"
      course_pace.end_date = 1.day.from_now.beginning_of_day
      course_pace.published_at = Time.now.utc
      course_pace.selected_days_to_skip = NOT_EXCLUDE_WEEKENDS_WORK_WEEK_DAYS
      course_pace.hard_end_dates = true
      course_pace.time_to_complete_calendar_days = 10
      course_pace.save!

      run_course_copy
      expect(@copy_to.course_paces.count).to eq 1

      course_pace_to = @copy_to.course_paces.take

      expect(course_pace_to.workflow_state).to eq "active"
      expect(course_pace_to.start_date).to eq course_pace.start_date
      expect(course_pace_to.end_date).to eq course_pace.end_date
      expect(course_pace_to.published_at.to_i).to eq course_pace.published_at.to_i
      expect(course_pace_to.selected_days_to_skip).to eq NOT_EXCLUDE_WEEKENDS_WORK_WEEK_DAYS
      expect(course_pace_to.hard_end_dates).to be true
      expect(course_pace_to.time_to_complete_calendar_days).to eq 10
    end

    context "module items" do
      before :once do
        @a1 = @copy_from.assignments.create! name: "a1"
        @a2 = @copy_from.assignments.create! name: "a2"
        @mod1 = @copy_from.context_modules.create! name: "module1"
        @tag1 = @mod1.add_item(type: "assignment", id: @a1.id)
        @mod2 = @copy_from.context_modules.create! name: "module2"
        @tag2 = @mod2.add_item(type: "assignment", id: @a2.id)

        @course_pace = @copy_from.course_paces.create!
        @course_pace.course_pace_module_items.create! duration: 1, module_item_id: @tag1.id
        @course_pace.course_pace_module_items.create! duration: 2, module_item_id: @tag2.id
      end

      it "copies course pace module item durations" do
        run_course_copy

        tag1_to = @copy_to.context_module_tags.find_by(migration_id: mig_id(@tag1))
        tag2_to = @copy_to.context_module_tags.find_by(migration_id: mig_id(@tag2))
        course_pace_to = @copy_to.course_paces.find_by(workflow_state: "unpublished")

        expect(course_pace_to.course_pace_module_items.find_by(module_item_id: tag1_to.id).duration).to eq 1
        expect(course_pace_to.course_pace_module_items.find_by(module_item_id: tag2_to.id).duration).to eq 2
      end

      it "copies a subset of module items in selective migrations" do
        @cm.copy_options = {
          all_course_paces: true,
          context_modules: { mig_id(@mod1) => true }
        }
        run_course_copy

        course_pace_to = @copy_to.course_paces.find_by(workflow_state: "unpublished")
        expect(course_pace_to.course_pace_module_items.count).to eq 1
      end
    end
  end
end
