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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  context "differentiated assignments" do
    before :once do
      gradebook_data_setup
      @da_assignment = assignment_model({
                                          course: @course,
                                          name: "DA assignment",
                                          points_possible: @assignment_1_points,
                                          submission_types: "online_text_entry",
                                          assignment_group: @group,
                                          only_visible_to_overrides: true
                                        })
      @override = create_section_override_for_assignment(@da_assignment, course_section: @other_section)
    end

    before do
      user_session(@teacher)
    end

    it "grays out cells" do
      Gradebook.visit(@course)
      # student 3, assignment 4
      selector = "#gradebook_grid .container_1 .slick-row:nth-child(3) .b4"
      cell = f(selector)
      expect(cell.find_element(:css, ".gradebook-cell")).to have_class("grayed-out")
      cell.click
      expect(cell).not_to contain_css(".grade")
      # student 2, assignment 4 (not grayed out)
      cell = f("#gradebook_grid .container_1 .slick-row:nth-child(2) .b4")
      expect(cell.find_element(:css, ".gradebook-cell")).not_to have_class("grayed-out")
    end

    it "grays out cells after removing an override which removes visibility" do
      selector = "#gradebook_grid .container_1 .slick-row:nth-child(1) .b4"
      @da_assignment.grade_student(@student_1, grade: 42, grader: @teacher)
      @override.destroy
      Gradebook.visit(@course)
      cell = f(selector)
      expect(cell.find_element(:css, ".gradebook-cell")).to have_class("grayed-out")
    end

    it "grays out cells properly for items that are part of assigned modules" do
      assignment = assignment_model({
                                      course: @course,
                                      name: "In a module",
                                      points_possible: @assignment_1_points,
                                      submission_types: "online_text_entry",
                                      assignment_group: @group,
                                    })
      module1 = @course.context_modules.create!(name: "Module")
      override = module1.assignment_overrides.create!
      override.assignment_override_students.create!(user: @student_1)
      module1.add_item(id: assignment.id, type: "assignment")
      Gradebook.visit(@course)
      student1_cell = f("#gradebook_grid .container_1 .slick-row:nth-child(1) .b5 .gradebook-cell")
      student2_cell = f("#gradebook_grid .container_1 .slick-row:nth-child(2) .b5 .gradebook-cell")
      student3_cell = f("#gradebook_grid .container_1 .slick-row:nth-child(3) .b5 .gradebook-cell")
      expect(student1_cell).not_to have_class("grayed-out")
      expect(student2_cell).to have_class("grayed-out")
      expect(student3_cell).to have_class("grayed-out")
    end
  end
end

describe "Gradebook" do
  it_behaves_like "Gradebook", true
  it_behaves_like "Gradebook", false
end
