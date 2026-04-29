# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../../helpers/grading_schemes_common"

describe "grading standards" do
  include_context "in-process server selenium tests"
  include GradingSchemesCommon

  it "allows creating grading standards", priority: "1" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/grading_standards"
    should_add_a_grading_scheme
  end

  it "allows editing a grading standard", priority: "1" do
    course_with_teacher_logged_in
    should_edit_a_grading_scheme(@course, "/courses/#{@course.id}/grading_standards")
  end

  it "allows deleting grading standards", priority: "1" do
    course_with_teacher_logged_in
    should_delete_a_grading_scheme(@course, "/courses/#{@course.id}/grading_standards")
  end

  it "displays correct info when multiple standards are added without refreshing page", priority: "1" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/grading_standards"
    should_add_a_grading_scheme(name: "First Grading Standard")
    first_grading_standard = @new_grading_standard
    should_add_a_grading_scheme(name: "Second Grading Standard")
    second_grading_standard = @new_grading_standard
    expect(fj("#grading_standard_#{first_grading_standard.id} .standard_title .title")).to include_text("First Grading Standard")
    expect(fj("#grading_standard_#{second_grading_standard.id} .standard_title .title")).to include_text("Second Grading Standard")
  end

  it "extends ranges to fractional values at the boundary with the next range", priority: "1" do
    student = user_factory(active_all: true)
    course_with_teacher_logged_in(active_all: true)
    @course.enroll_student(student).accept!
    @course.update_attribute :grading_standard_id, 0
    @course.assignment_groups.create!
    @assignment = @course.assignments.create!(title: "new assignment", points_possible: 1000, assignment_group: @course.assignment_groups.first, grading_type: "points")
    @assignment.grade_student(student, grade: 899, grader: @teacher)
    get "/courses/#{@course.id}/grades/#{student.id}"
    grading_scheme = driver.execute_script "return ENV.course_active_grading_scheme"
    expect(grading_scheme["data"][2]["name"]).to eq "B+"
    expect(f("#right-side .final_grade .grade").text).to eq "89.9%"
    expect(f("#final_letter_grade_text").text).to eq "B+"
  end

  it "allows editing the standard again without reloading the page", priority: "1" do
    user_session(account_admin_user)
    @standard = simple_grading_standard(Account.default)
    get("/accounts/#{Account.default.id}/grading_standards")
    f('#react_grading_tabs a[href="#grading-standards-tab"]').click
    std = f("#grading_standard_#{@standard.id}")
    std.find_element(:css, ".edit_grading_standard_button").click
    std.find_element(:css, "button.save_button").click
    wait_for_ajax_requests
    std = f("#grading_standard_#{@standard.id}")
    std.find_element(:css, ".edit_grading_standard_button").click
    std.find_element(:css, "button.save_button")
    wait_for_ajax_requests
    expect(@standard.reload.data.length).to eq 4
  end

  context "course settings" do
    before do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/settings"
      checkbox = f(".grading_standard_checkbox")
      scroll_into_view(checkbox)
      checkbox.click
      f(".edit_letter_grades_link").click
    end

    it "set default grading scheme", priority: "2" do
      expect(f("#edit_letter_grades_form")).to be_displayed
    end

    it "manage default grading scheme", priority: "2" do
      element = ff(".displaying a").select { |a| a.text == "manage grading schemes" }
      element[0].click
      expect(f(".icon-add")).to be_displayed
    end

    it "edit current grading scheme", priority: "2" do
      element = ff(".displaying a").select { |a| a.text == "" }
      element[0].click
      expect(f(".ui-dialog-titlebar").text).to eq("View/Edit Grading Scheme\nClose")
    end
  end
end
