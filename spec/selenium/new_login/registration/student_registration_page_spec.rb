# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../common"

describe "new login Student Registration page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  describe "when self-registration is enabled as “all”" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
      # disable terms to avoid interaction Selenium click issues with checkbox label (has inline links)
      Account.default.root_account.create_terms_of_service!(passive: true)
      get "/login/canvas/register/student"
    end

    it "shows the Student registration form with required fields" do
      expect(f("h1").text).to include("Create a Student Account")
      expect(f('[data-testid="name-input"]')).to be_displayed
      expect(f('[data-testid="username-input"]')).to be_displayed
      expect(f('[data-testid="password-input"]')).to be_displayed
      expect(f('[data-testid="confirm-password-input"]')).to be_displayed
      expect(f('[data-testid="join-code-input"]')).to be_displayed
      expect(f('[data-testid="submit-button"]')).to be_displayed
      expect(f('[data-testid="back-button"]')).to be_displayed
    end

    it "creates a student account and shows a confirmation screen" do
      # set up a course with self-enrollment enabled and get the join code
      Account.default.allow_self_enrollment!
      course_factory(active_all: true)
      @course.update!(self_enrollment: true)
      join_code = @course.self_enrollment_code
      f('[data-testid="name-input"]').send_keys("Student Testerson")
      f('[data-testid="username-input"]').send_keys("student_test_user")
      f('[data-testid="password-input"]').send_keys("StudentPass123!")
      f('[data-testid="confirm-password-input"]').send_keys("StudentPass123!")
      f('[data-testid="join-code-input"]').send_keys(join_code)
      f('[data-testid="submit-button"]').click
      wait_for_ajaximations
      wait_for_selector('[data-testid="ToDoSidebar"]')
      expect(f('[data-testid="ToDoSidebar"]')).to be_displayed
      # verify user was created in the DB
      user = User.find_by(name: "Student Testerson")
      expect(user).not_to be_nil
      expect(user.initial_enrollment_type).to eq("student")
      expect(user.pseudonym.unique_id).to eq("student_test_user")
    end

    describe "back navigation behavior" do
      it "returns to login page from Student registration form" do
        get "/login/canvas/register/student"
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Welcome to Canvas")
      end

      it "goes back to registration landing page if user navigated from login → registration landing page → student registration" do
        get "/login/canvas"
        f('[data-testid="create-account-link"]').click
        expect(f("h1").text).to include("Create Your Account")
        f('[data-testid="student-card-link"]').click
        expect(f("h1").text).to include("Create a Student Account")
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Create Your Account")
      end
    end
  end

  describe "access control" do
    it "redirects away from /login/canvas/register/student when self-registration is disabled" do
      get "/login/canvas/register/student"
      expect(f("h1").text).to include("Welcome to Canvas")
    end
  end
end
