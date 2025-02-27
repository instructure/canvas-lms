# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"

describe "course sections" do
  include_context "in-process server selenium tests"

  def add_enrollment(enrollment_state, section)
    enrollment = student_in_course(workflow_state: enrollment_state, course_section: section)
    enrollment.accept! if enrollment_state == "active" || enrollment_state == "completed"
  end

  def table_rows
    ff("#enrollment_table tr")
  end

  before do
    course_with_teacher_logged_in
    @section = @course.default_section
  end

  it "validates the display when multiple enrollments exist" do
    add_enrollment("active", @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text("2 Active Enrollments")
  end

  it "validates the display when only 1 enrollment exists" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text("1 Active Enrollment")
  end

  it "displays the correct pending enrollments count" do
    add_enrollment("pending", @section)
    add_enrollment("invited", @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 2
    expect(table_rows[0]).to include_text("2 Pending Enrollments")
  end

  it "displays the correct completed enrollments count" do
    add_enrollment("completed", @section)
    @course.complete!
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text("2 Completed Enrollments")
  end

  it "edits the section" do
    edit_name = "edited section name"
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f(".edit_section_link").click
    edit_form = f("#edit_section_form")
    replace_content(edit_form.find_element(:id, "course_section_name"), edit_name)
    submit_form(edit_form)
    wait_for_ajaximations
    expect(f("#section_name")).to include_text(edit_name)
  end

  it "parses dates" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f(".edit_section_link").click
    edit_form = f("#edit_section_form")
    replace_and_proceed(edit_form.find_element(:id, "course_section_start_at"), "1/2/15")
    replace_and_proceed(edit_form.find_element(:id, "course_section_end_at"), "04 Mar 2015")
    submit_form(edit_form)
    wait_for_ajax_requests
    @section.reload
    expect(@section.start_at).to eq(Date.new(2015, 1, 2))
    expect(@section.end_at).to eq(Date.new(2015, 3, 4))
  end

  describe "edit form validations" do
    it "validates non-empty course_section name" do
      edit_name = "  "
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f(".edit_section_link").click
      edit_form = f("#edit_section_form")
      replace_content(edit_form.find_element(:id, "course_section_name"), edit_name)
      submit_form(edit_form)
      wait_for_ajaximations

      expect(f("#course_section_name_errors")).to include_text("A section name is required")
    end

    it "validates course_section name less than 255 characters" do
      edit_name = "a" * 256
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f(".edit_section_link").click
      edit_form = f("#edit_section_form")
      replace_content(edit_form.find_element(:id, "course_section_name"), edit_name)
      submit_form(edit_form)
      wait_for_ajaximations

      expect(f("#course_section_name_errors")).to include_text("Section name is too long")
    end

    it "validates course_section start_at is before end_at" do
      start_at = "Mar 7, 2025 at 1pm"
      end_at = "Feb 19, 2025 at 12am"
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f(".edit_section_link").click
      edit_form = f("#edit_section_form")
      replace_content(edit_form.find_element(:id, "course_section_start_at"), start_at)
      replace_content(edit_form.find_element(:id, "course_section_end_at"), end_at)
      submit_form(edit_form)
      wait_for_ajaximations

      expect(f("#course_section_end_at_errors")).to include_text("End date cannot be before start date")
    end
  end

  context "account admin" do
    before do
      Account.default.role_overrides.create! role: admin_role, permission: "manage_sis", enabled: true
      @subaccount = Account.default.sub_accounts.create! name: "sub"
      course_factory account: @subaccount
      @section = @course.course_sections.create! name: "sec"
    end

    it "lets a root account admin modify the sis ID" do
      account_admin_user account: Account.default
      user_session @admin
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f(".edit_section_link").click
      edit_form = f("#edit_section_form")
      expect(edit_form).to contain_css("input#course_section_sis_source_id")
    end

    it "does not let a subaccount admin modify the sis ID" do
      account_admin_user account: @subaccount
      user_session @admin
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f(".edit_section_link").click
      edit_form = f("#edit_section_form")
      expect(edit_form).not_to contain_css("input#course_section_sis_source_id")
    end
  end

  context "cross-list sections" do
    it "shows error if user inputs an invalid course id" do
      get "/courses/#{@course.id}/sections/#{@section.id}"
      f(".crosslist_link").click
      cl_form = f("#crosslist_course_form")
      replace_content(cl_form.find_element(:id, "course_id"), 99_999)
      submit_form(cl_form)
      wait_for_ajaximations

      expect(f("#course_id_errors")).to include_text('Course ID "99999" not authorized for cross-listing')
    end

    it "shows error if user tries to submit without any values" do
      get "/courses/#{@course.id}/sections/#{@section.id}"
      f(".crosslist_link").click
      cl_form = f("#crosslist_course_form")
      submit_form(cl_form)
      wait_for_ajaximations

      expect(f("#course_autocomplete_id_lookup_errors")).to include_text("Not a valid course name")
    end
  end

  context "student tray" do
    before do
      @account = Account.default
    end

    it "course section page should display student name in tray", priority: "1" do
      add_enrollment("active", @section)
      get("/courses/#{@course.id}/sections/#{@section.id}")
      f("a[data-student_id='#{@student.id}']").click
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
    end
  end
end
