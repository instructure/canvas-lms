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
#

describe CoursePaceDueDatesCalculator do
  before :once do
    course_with_student active_all: true
    @course.update start_at: "2021-09-01", restrict_enrollments_to_course_dates: true
    @module = @course.context_modules.create!
    @assignment = @course.assignments.create!
    @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    @course_pace = @course.course_paces.create! workflow_state: "active", end_date: "2021-09-30"
    @course_pace_module_item = @course_pace.course_pace_module_items.create! module_item: @tag
    @course_pace_module_items = @course_pace.course_pace_module_items.active
    @calculator = CoursePaceDueDatesCalculator.new(@course_pace)
  end

  context "get_due_dates" do
    it "returns the next due date" do
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-01") }
      )
    end

    it "respects blackout dates" do
      @course.blackout_dates.create! event_title: "Blackout test", start_date: "2021-09-01", end_date: "2021-09-08"
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-09") }
      )
    end

    it "respects calendar event blackout dates" do
      @course.calendar_events.create! title: "Calendar Event Blackout test",
                                      start_at: "Wed, 1 Sep 2021 06:00:00.000000000 UTC +00:00",
                                      end_at: "Wed, 8 Sep 2021 06:00:00.000000000 UTC +00:00",
                                      blackout_date: true
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-09") }
      )
    end

    it "respects calendar event blackout dates and regular blackout dates" do
      @course.calendar_events.create! title: "Calendar Event Blackout test",
                                      start_at: "Wed, 1 Sep 2021 06:00:00.000000000 UTC +00:00",
                                      end_at: "Wed, 8 Sep 2021 06:00:00.000000000 UTC +00:00",
                                      blackout_date: true
      @course.blackout_dates.create! event_title: "Blackout test",
                                     start_date: "2021-09-09",
                                     end_date: "2021-09-12"
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-13") }
      )
    end

    it "respects skipping weekends" do
      @course.blackout_dates.create! event_title: "Blackout test", start_date: "2021-09-01", end_date: "2021-09-03"
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-06") }
      )
      @course_pace.update exclude_weekends: false
      expect(@calculator.get_due_dates(@course_pace_module_items)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-04") }
      )
    end

    it "calculates from a given enrollment start date" do
      enrollment = Enrollment.new(start_at: Date.parse("2021-09-09"))
      expect(@calculator.get_due_dates(@course_pace_module_items, enrollment)).to eq(
        { @course_pace_module_item.id => Date.parse("2021-09-09") }
      )
    end
  end
end
