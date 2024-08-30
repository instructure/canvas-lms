# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "page_objects/teacher_assignment_page_v2"
require_relative "../common"
require_relative "../rcs/pages/rce_next_page"

describe "as a teacher" do
  specs_require_sharding
  include RCENextPage
  include_context "in-process server selenium tests"

  context "on assignments 2 page" do
    before(:once) do
      Account.default.enable_feature!(:assignment_enhancements_teacher_view)
      @course = course_factory(name: "course", active_course: true)
      @student = student_in_course(name: "Student", course: @course, enrollment_state: :active).user
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    end

    context "assignment details" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
      end

      before do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows assignment title" do
        expect(TeacherViewPageV2.assignment_title(@assignment.title)).to_not be_nil
      end
    end
  end
end
