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

describe "assignments" do
  include_context "in-process server selenium tests"

  context "as an admin" do
    before do
      @student = user_with_pseudonym(active_user: true)
      course_with_student(active_all: true, user: @student)
      assignment_model(course: @course, submission_types: "online_upload", title: "Assignment 1")
      site_admin_logged_in
    end

    it "does not show google docs tab for masquerading admin" do
      PluginSetting.create!(name: "google_drive", settings: {})
      masquerade_url = "/users/#{@student.id}/masquerade"
      get masquerade_url
      expect_new_page_load { f('a[href="' + masquerade_url + '"]').click }

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      f(".submit_assignment_link").click
      expect(f("#content")).not_to contain_css("#submit_google_doc_form")

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "shows the submit button if admin is enrolled as student" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css(".submit_assignment_link")

      @course.enroll_student(@admin, enrollment_state: "active")

      refresh_page
      wait_for_ajaximations
      expect(f(".submit_assignment_link")).to be_displayed
    end
  end

  context "with limited permissions" do
    before :once do
      @student = user_with_pseudonym(active_user: true)
      course_with_student(active_all: true, user: @student)
      assignment_model(course: @course, submission_types: "online_upload", title: "Assignment 1")
    end

    it "does not kersplode on the index without the `manage_courses_admin` permission" do
      account_admin_user_with_role_changes(role_changes: { manage_courses_admin: false })
      user_session(@user)

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(f("#assignment_#{@assignment.id}").text).to include(@assignment.title)
    end

    it "does not kersplode on the index without the `manage_assignments_edit` permission" do
      account_admin_user_with_role_changes(role_changes: { manage_assignments_edit: false })
      user_session(@user)

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(f("#assignment_#{@assignment.id}").text).to include(@assignment.title)
    end
  end
end
