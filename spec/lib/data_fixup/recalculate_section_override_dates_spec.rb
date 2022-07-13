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

describe DataFixup::RecalculateSectionOverrideDates do
  before do
    Account.site_admin.disable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
    course_with_student(active_all: true)
    @section2 = @course.course_sections.create!(name: "Second Section")
    @course.enroll_student(@student, allow_multiple_enrollments: true, enrollment_state: "active", section: @section2)
    @everyone_due_date = 10.days.from_now.iso8601.to_datetime
    @assignment = @course.assignments.create!(due_at: @everyone_due_date)
    @section2_due_date = 10.days.from_now(@everyone_due_date)
    create_section_override_for_assignment(@assignment, course_section: @section2, due_at: @section2_due_date)
  end

  context "when the student has a nonactive enrollment in an assigned section" do
    before do
      @course.enrollments.find_by(user: @student, course_section: @section2).conclude
    end

    it "recomputes cached due date, prioritizing the 'everyone' date over the section override date" do
      Account.site_admin.enable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
      expect { DataFixup::RecalculateSectionOverrideDates.run }.to change {
        @assignment.submissions.find_by(user: @student).cached_due_date
      }.from(@section2_due_date).to(@everyone_due_date)
    end

    it "recomputes cached due date, prioritizing other override dates over the section override date" do
      default_section_due_date = 5.days.ago(@section2_due_date)
      create_section_override_for_assignment(
        @assignment,
        course_section: @course.default_section,
        due_at: default_section_due_date
      )
      Account.site_admin.enable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
      expect { DataFixup::RecalculateSectionOverrideDates.run }.to change {
        @assignment.submissions.find_by(user: @student).cached_due_date
      }.from(@section2_due_date).to(default_section_due_date)
    end

    it "does not change the due date if the section date is the only assigned date" do
      @assignment.update!(only_visible_to_overrides: true)
      Account.site_admin.enable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
      expect { DataFixup::RecalculateSectionOverrideDates.run }.not_to change {
        @assignment.submissions.find_by(user: @student).cached_due_date
      }.from(@section2_due_date)
    end

    it "after running, returns the correct due date for overridden assignment objects" do
      Account.site_admin.enable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
      DataFixup::RecalculateSectionOverrideDates.run
      expect(@assignment.overridden_for(@student).due_at).to eq @everyone_due_date
    end
  end

  context "when the student has a nonactive enrollment in an not-assigned section" do
    before do
      @course.enrollments.find_by(user: @student, course_section: @course.default_section).conclude
    end

    it "does not recompute cached due date" do
      Account.site_admin.enable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
      expect { DataFixup::RecalculateSectionOverrideDates.run }.not_to change {
        @assignment.submissions.find_by(user: @student).cached_due_date
      }.from(@section2_due_date)
    end
  end
end
