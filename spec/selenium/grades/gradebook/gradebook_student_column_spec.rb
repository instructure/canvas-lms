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

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Student column header options" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
    init_course_with_students(3)
  end

  before { user_session(@teacher) }

  context "student name sort by" do
    before do
      Gradebook.visit(@course)
      @students = @course.students.sort_by { |x| x[:id] }
    end

    it "sorts student column in A-Z order", priority: "1" do
      Gradebook.click_student_menu_sort_by("A-Z")
      expect(Gradebook.fetch_student_names[0]).to eq(@students[0].name)
    end
  end

  context "Display as" do
    before do
      Gradebook.visit(@course)
      @students = @course.students.sort_by { |x| x[:id] }
    end

    it "displays student names as First Last", priority: "1" do
      Gradebook.click_student_menu_display_as("First,Last")
      expect(Gradebook.fetch_student_names[0]).to eq(@students[0].name)
    end

    it "displays student names as Last,First", priority: "2" do
      Gradebook.click_student_menu_display_as("Last,First")

      student_name = @students[0].last_name + ", " + @students[0].first_name
      expect(Gradebook.fetch_student_names[0]).to eq(student_name)
    end

    it "first,last display name persists", priority: "2" do
      Gradebook.click_student_menu_display_as("Last,First")
      Gradebook.visit(@course)

      student_name = @students[0].last_name + ", " + @students[0].first_name
      expect(Gradebook.fetch_student_names[0]).to eq(student_name)
    end
  end

  context "Secondary Info" do
    before do
      Gradebook.visit(@course)
    end

    it "hides Secondary info for display as none", priority: "1" do
      Gradebook.click_student_menu_secondary_info("None")

      expect(Gradebook.student_column_cell_select(0, 0)).not_to contain_css("secondary-info")
    end

    it "persists Secondary info selection", priority: "2" do
      Gradebook.click_student_menu_secondary_info("None")
      Gradebook.visit(@course)

      expect(Gradebook.student_column_cell_select(0, 0)).not_to contain_css("secondary-info")
    end
  end
end

describe "Student column header options" do
  it_behaves_like "Student column header options", true
  it_behaves_like "Student column header options", false
end
