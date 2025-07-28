# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook/settings"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/srgb_page"
require_relative "../pages/student_grades_page"
require_relative "../pages/gradebook_history_page"
require_relative "../setup/gb_history_search_setup"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Final Grade Override" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookHistorySetup

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  before do
    allow(AuditLogFieldExtension).to receive(:enabled?).and_return(false)

    course_with_teacher(course_name: "Grade Override", active_course: true, active_enrollment: true, name: "Dedicated Teacher1", active_user: true)
    @course.update!(grading_standard_enabled: true)
    @students = create_users_in_course(@course, 5, return_type: :record, name_prefix: "Purple")
    @course.enable_feature!(:final_grades_override)

    # create moderated assignment with teacher4 as final grader
    @assignment = @course.assignments.create!(
      title: "override assignment",
      submission_types: "online_text_entry",
      grading_type: "points",
      points_possible: 10
    )

    @students.each do |student|
      @assignment.grade_student(student, grade: 8.9, grader: @teacher)
    end
  end

  it "displays the override column", priority: "1" do
    user_session(@teacher)
    Gradebook.visit(@course)
    Gradebook.settings_cog_select
    Gradebook::Settings.click_advanced_tab
    Gradebook::Advanced.select_grade_override_checkbox
    Gradebook::Settings.click_update_button
    expect(f(".slick-header-column[title='Override']")).to be_displayed
  end

  context "with an overridden grade" do
    before do
      @course.update!(allow_final_grade_override: true)
      @teacher.save

      user_session(@teacher)
      Gradebook.visit(@course)
      Gradebook::Cells.edit_override(@students.first, 90.0)
    end

    it "saves overridden grade in Gradebook", priority: "1" do
      Gradebook.visit(@course)
      expect(Gradebook::Cells.get_override_grade(@students.first)).to eql "A−"
    end

    it "displays overridden grade for student grades", priority: "1" do
      user_session(@students.first)
      StudentGradesPage.visit_as_student(@course)
      expect(StudentGradesPage.final_grade.text).to eql "90%"
    end
  end

  context "Gradebook History" do
    before do
      @course.update!(allow_final_grade_override: true)
      @teacher.save

      user_session(@teacher)
      Gradebook.visit(@course)
      Gradebook::Cells.edit_override(@students.first, 90.0)
      GradeBookHistory.visit(@course)
      wait_for_ajaximations
    end

    it "displays checkbox to show final grade overrides" do
      expect(GradeBookHistory.final_grade_override_checkbox).to be_displayed
    end

    it "displays final grade override grade changes" do
      expect(GradeBookHistory).to be_contains_final_grade_override_entries
    end

    it "displays final grade override grade changes only when filter is applied" do
      GradeBookHistory.search_final_grade_override_only

      expect(GradeBookHistory).to be_contains_only_final_grade_override_entries
    end
  end
end

describe "Final Grade Override" do
  it_behaves_like "Final Grade Override", true
  it_behaves_like "Final Grade Override", false
end
