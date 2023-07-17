# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/enhanced_srgb_page"

describe "Screenreader Gradebook" do
  include_context "in-process server selenium tests"
  include_context "reusable_gradebook_course"
  include GradebookCommon

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_2
    student_submission
    assignment_1.grade_student(student, grade: 10, grader: teacher)
  end

  before do
    course_setup
    user_session(teacher)
    EnhancedSRGB.visit(test_course.id)
    EnhancedSRGB.select_student(student)
  end

  it "toggles ungraded as 0 with correct grades" do
    EnhancedSRGB.select_assignment(assignment_1)
    EnhancedSRGB.ungraded_as_zero.click
    expect(EnhancedSRGB.final_grade).to include_text("50%")

    EnhancedSRGB.ungraded_as_zero.click
    expect(EnhancedSRGB.final_grade).to include_text("100%")
  end

  it "hides student names" do
    EnhancedSRGB.hide_student_names.click
    expect(EnhancedSRGB.secondary_id_label).to include_text("hidden")
  end

  it "shows conluded enrollments" do
    skip "unskip w/ EVAL-3356 BUG student's last name is not shown last, first"
    EnhancedSRGB.concluded_enrollments.click
    wait_for_ajaximations

    expect(EnhancedSRGB.student_dropdown).to include_text("Student, Concluded")
  end

  it "shows notes in student info" do
    EnhancedSRGB.show_notes_option.click
    expect(EnhancedSRGB.notes_field).to be_present
  end
end
