#
# Copyright (C) 2016 - 2017 Instructure, Inc.
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

require_relative '../../helpers/gradezilla_common'
require_relative '../setup/gradebook_setup'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - concluded courses and enrollments" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GradebookSetup

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }
  let(:conclude_student_1) { @student_1.enrollments.where(course_id: @course).first.conclude }
  let(:deactivate_student_1) { @student_1.enrollments.where(course_id: @course).first.deactivate }

  context "active course" do
    it "does not show concluded enrollments by default", priority: "1", test_id: 210020 do
      conclude_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size
      gradezilla_page.visit(@course)
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows concluded enrollments when checked in column header", priority: "1", test_id: 164223 do
      conclude_student_1
      gradezilla_page.visit(@course)

      expect_new_page_load do
        gradezilla_page.open_student_column_menu
        gradezilla_page.select_menu_item 'concluded'
      end
      expect(ff('.student-name')).to have_size @course.all_students.count
    end

    it "hides concluded enrollments when unchecked in column header", priority: "1", test_id: 3101103 do
      conclude_student_1
      display_concluded_enrollments
      gradezilla_page.visit(@course)

      expect_new_page_load do
        gradezilla_page.open_student_column_menu
        gradezilla_page.select_menu_item 'concluded'
      end
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "does not show inactive enrollments by default", priority: "1", test_id: 1102065 do
      deactivate_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size
      gradezilla_page.visit(@course)
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows inactive enrollments when checked in column header", priority: "1", test_id: 1102066 do
      deactivate_student_1
      gradezilla_page.visit(@course)

      expect_new_page_load do
        gradezilla_page.open_student_column_menu
        gradezilla_page.select_menu_item 'inactive'
      end
      expect(ff('.student-name')).to have_size @course.all_students.count
    end

    it "hides inactive enrollments when unchecked in column header", priority: "1", test_id: 3101104 do
      deactivate_student_1
      display_inactive_enrollments
      gradezilla_page.visit(@course)

      expect_new_page_load do
        gradezilla_page.open_student_column_menu
        gradezilla_page.select_menu_item 'inactive'
      end
      expect(ff('.student-name')).to have_size @course.students.count
    end
  end

  context "concluded course" do
    it "does not allow editing grades", priority: "1", test_id: 210027 do
      @course.complete!
      gradezilla_page.visit(@course)
      cell = gradezilla_page.grading_cell
      expect(cell).to include_text '10'
      cell.click
      expect(cell).not_to contain_css('.grade') # no input box for entry
    end
  end
end
