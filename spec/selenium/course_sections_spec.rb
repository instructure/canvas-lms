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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course sections" do
  include_context "in-process server selenium tests"

  def add_enrollment(enrollment_state, section)
    enrollment = student_in_course(:workflow_state => enrollment_state, :course_section => section)
    enrollment.accept! if enrollment_state == 'active' || enrollment_state == 'completed'
  end

  def table_rows
    ff('#enrollment_table tr')
  end

  before (:each) do
    course_with_teacher_logged_in
    @section = @course.default_section
  end

  it "should validate the display when multiple enrollments exist" do
    add_enrollment('active', @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('2 Active Enrollments')
  end

  it "should validate the display when only 1 enrollment exists" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('1 Active Enrollment')
  end

  it "should display the correct pending enrollments count" do
    add_enrollment('pending', @section)
    add_enrollment('invited', @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 2
    expect(table_rows[0]).to include_text('2 Pending Enrollments')
  end

  it "should display the correct completed enrollments count" do
    add_enrollment('completed', @section)
    @course.complete!
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('2 Completed Enrollments')
  end

  it "should edit the section" do
    edit_name = 'edited section name'
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f('.edit_section_link').click
    edit_form = f('#edit_section_form')
    replace_content(edit_form.find_element(:id, 'course_section_name'), edit_name)
    submit_form(edit_form)
    wait_for_ajaximations
    expect(f('#section_name')).to include_text(edit_name)
  end

  it "should parse dates" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f('.edit_section_link').click
    edit_form = f('#edit_section_form')
    replace_content(edit_form.find_element(:id, 'course_section_start_at'), '1/2/15')
    replace_content(edit_form.find_element(:id, 'course_section_end_at'), '04 Mar 2015')
    submit_form(edit_form)
    wait_for_ajax_requests
    @section.reload
    expect(@section.start_at).to eq(Date.new(2015, 1, 2))
    expect(@section.end_at).to eq(Date.new(2015, 3, 4))
  end

  context "account admin" do
    before do
      Account.default.role_overrides.create! role: Role.get_built_in_role('AccountAdmin'), permission: 'manage_sis', enabled: true
      @subaccount = Account.default.sub_accounts.create! name: 'sub'
      course_factory account: @subaccount
      @section = @course.course_sections.create! name: 'sec'
    end

    it "lets a root account admin modify the sis ID" do
      account_admin_user account: Account.default
      user_session @admin
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f('.edit_section_link').click
      edit_form = f('#edit_section_form')
      expect(edit_form).to contain_css('input#course_section_sis_source_id')
    end

    it "does not let a subaccount admin modify the sis ID" do
      account_admin_user account: @subaccount
      user_session @admin
      get "/courses/#{@course.id}/sections/#{@section.id}"

      f('.edit_section_link').click
      edit_form = f('#edit_section_form')
      expect(edit_form).not_to contain_css('input#course_section_sis_source_id')
    end
  end

  context "student tray" do

    before(:each) do
      @account = Account.default
      @account.enable_feature!(:student_context_cards)
    end

    it "course section page should display student name in tray", priority: "1", test_id: 3022068 do
      add_enrollment("active", @section)
      get("/courses/#{@course.id}/sections/#{@section.id}")
      f("a[data-student_id='#{@student.id}']").click
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
    end
  end
end
