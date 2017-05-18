#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'
require_relative '../page_objects/srgb_page'

describe "Screenreader Gradebook" do
  include_context 'in-process server selenium tests'
  include_context 'reusable_course'
  include GradebookCommon

  let(:srgb_page) { SRGB }

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_2
    student_submission
    assignment_1.grade_student(student, grade: 10, grader: teacher)
  end

  before(:each) do
    course_setup
    user_session(teacher)
    srgb_page.visit(test_course.id)
    srgb_page.select_student(student)
  end

  it 'toggles ungraded as 0 with correct grades', priority: "2", test_id: 615672 do
    srgb_page.select_assignment(assignment_1)
    srgb_page.ungraded_as_zero.click
    expect(srgb_page.final_grade).to include_text('50%')

    srgb_page.ungraded_as_zero.click
    expect(srgb_page.final_grade).to include_text('100%')
  end

  it 'hides student names', priority: "2", test_id: 615673 do
    srgb_page.hide_student_names.click
    expect(srgb_page.secondary_id_label).to include_text('hidden')
  end

  it 'shows conluded enrollments', priority: "2", test_id: 615674 do
    srgb_page.concluded_enrollments.click
    wait_for_ajaximations
    expect(srgb_page.student_dropdown).to include_text('Concluded Student')
  end

  it 'shows notes in student info', priority: "2", test_id: 615675 do
    srgb_page.show_notes_option.click
    expect(srgb_page.notes_field).to be_present
  end
end
