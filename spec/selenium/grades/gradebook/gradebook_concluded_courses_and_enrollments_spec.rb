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

require_relative "../../helpers/gradebook_common"
require_relative "../setup/gradebook_setup"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook - concluded courses and enrollments" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  before(:once) do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
    gradebook_data_setup
  end

  before { user_session(@teacher) }

  let(:conclude_student_1) { @student_1.enrollments.where(course_id: @course).first.conclude }
  let(:deactivate_student_1) { @student_1.enrollments.where(course_id: @course).first.deactivate }

  context "active course" do
    it "does not show concluded enrollments by default", priority: "1" do
      conclude_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      Gradebook.visit(@course)

      expect(ff(".student-name")).to have_size @course.students.count
    end

    it "shows concluded enrollments when checked in column header", priority: "1" do
      conclude_student_1
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option("Concluded enrollments")

      expect(ff(".student-name")).to have_size @course.all_students.count
    end

    it "hides concluded enrollments when unchecked in column header", priority: "1" do
      conclude_student_1
      display_concluded_enrollments
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option("Concluded enrollments")

      expect(ff(".student-name")).to have_size @course.students.count
    end

    it "does not show inactive enrollments by default", priority: "1" do
      deactivate_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      Gradebook.visit(@course)

      expect(ff(".student-name")).to have_size @course.students.count
    end

    it "shows inactive enrollments when checked in column header", priority: "1" do
      deactivate_student_1
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option("Inactive enrollments")

      expect(ff(".student-name")).to have_size @course.all_students.count
    end

    it "hides inactive enrollments when unchecked in column header", priority: "1" do
      deactivate_student_1
      display_inactive_enrollments
      Gradebook.visit(@course)

      Gradebook.click_student_header_menu_show_option("Inactive enrollments")

      expect(ff(".student-name")).to have_size @course.students.count
    end
  end

  context "concluded course" do
    it "does not allow editing grades", priority: "1" do
      @course.complete!
      Gradebook.visit(@course)

      expect(Gradebook::Cells.get_grade(@student_1, @first_assignment)).to eq "10"
      cell = Gradebook::Cells.grading_cell(@student_1, @first_assignment)
      expect(cell).to contain_css(Gradebook::Cells.ungradable_selector)
    end
  end
end

describe "Gradebook - concluded courses and enrollments" do
  it_behaves_like "Gradebook - concluded courses and enrollments", true
  it_behaves_like "Gradebook - concluded courses and enrollments", false
end
