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
require_relative '../pages/srgb_page'
require_relative '../pages/gradebook_page'

describe 'Screenreader Gradebook Student Information' do
  include_context 'in-process server selenium tests'
  include_context 'reusable_gradebook_course'
  include GradebookCommon

  let(:srgb_page) { SRGB }
  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_5
    student_submission
    assignment_1.grade_student(student, grade: 3, grader: teacher)
  end

  context 'in Student Information section' do
    before(:each) do
      course_setup
      user_session(teacher)
      srgb_page.visit(test_course.id)
    end

    it 'allows comments in Notes field', priority: "2", test_id: 615709 do
      skip_if_chrome('fails in chrome - due to replace content')
      srgb_page.select_student(student)
      srgb_page.show_notes_option.click
      replace_content(srgb_page.notes_field, 'Good job!')
      srgb_page.tab_out_of_input(srgb_page.notes_field)

      expect(srgb_page.notes_field).to have_value('Good job!')
    end

    it "displays student's grades", priority: "2", test_id: 615710 do
      srgb_page.select_student(student)
      expect(srgb_page.final_grade.text).to eq("30% (3 / 10 points)")
      expect(srgb_page.assign_subtotal_grade.text).to eq("30% (3 / 10)")
      expect_new_page_load { srgb_page.switch_to_default_gradebook_link.click }
      gradebook_page = Gradebook::MultipleGradingPeriods.new
      expect(gradebook_page.cell_graded?("30%", 4, 0)).to be true
    end

    context 'displays no points possible warning' do
      before(:each) do
        @course.apply_assignment_group_weights = true
        @course.save!
        srgb_page.visit(test_course.id)
      end

      it "with only a student selected", priority: "2", test_id: 615711 do
        srgb_page.select_student(student)

        expect(f('span.text-error > i.icon-warning')).to be_displayed
        expect(f('#student_information > div.row')).to include_text('Score does not include assignments from the group')
      end

      it "with only an assignment is selected", priority: "2", test_id: 615691 do
        srgb_page.select_assignment(assignment_5)

        expect(f('a > i.icon-warning')).to be_displayed
        expect(f('#assignment_information > div.row')).to include_text('Assignments in this group have no points')
      end
    end
  end
end
