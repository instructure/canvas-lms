# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'
require_relative '../setup/gradebook_setup'
require_relative '../pages/gradebook_page'
require_relative '../pages/gradebook_cells_page'

describe "Gradebook - concluded courses and enrollments" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }
  let(:conclude_student_1) { @student_1.enrollments.where(course_id: @course).first.conclude }
  let(:deactivate_student_1) { @student_1.enrollments.where(course_id: @course).first.deactivate }

  context "active course" do
    it "does not show concluded enrollments by default", priority: "1", test_id: 210020 do
      conclude_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      Gradebook.visit(@course)

      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows concluded enrollments when checked in column header", priority: "1", test_id: 3253331 do
      conclude_student_1
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option('Concluded enrollments')

      expect(ff('.student-name')).to have_size @course.all_students.count
    end

    it "hides concluded enrollments when unchecked in column header", priority: "1", test_id: 3253332 do
      conclude_student_1
      display_concluded_enrollments
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option('Concluded enrollments')

      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "does not show inactive enrollments by default", priority: "1", test_id: 1102065 do
      deactivate_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      Gradebook.visit(@course)

      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows inactive enrollments when checked in column header", priority: "1", test_id: 3253329 do
      deactivate_student_1
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option('Inactive enrollments')

      expect(ff('.student-name')).to have_size @course.all_students.count
    end

    it "hides inactive enrollments when unchecked in column header", priority: "1", test_id: 3253330 do
      deactivate_student_1
      display_inactive_enrollments
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option('Inactive enrollments')

      expect(ff('.student-name')).to have_size @course.students.count
    end
  end

  context "concluded course" do
    it "does not allow editing grades", priority: "1", test_id: 210027 do
      @course.complete!
      Gradebook.visit(@course)

      expect(Gradebook::Cells.get_grade(@student_1, @first_assignment)).to eq '10'
      cell = Gradebook::Cells.grading_cell(@student_1, @first_assignment)
      expect(cell).to contain_css(Gradebook::Cells.ungradable_selector)
    end
  end
end
