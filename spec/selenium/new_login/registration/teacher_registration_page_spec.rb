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

describe "new login Teacher Registration page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  describe "when self-registration is enabled as “all”" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
      # disable terms to avoid interaction Selenium click issues with checkbox label (has inline links)
      Account.default.root_account.create_terms_of_service!(passive: true)
      get "/login/canvas/register/teacher"
    end

    it "shows the Teacher registration form with required fields" do
      expect(f("h1").text).to include("Create a Teacher Account")
      expect(f('[data-testid="email-input"]')).to be_displayed
      expect(f('[data-testid="name-input"]')).to be_displayed
      expect(f('[data-testid="submit-button"]')).to be_displayed
      expect(f('[data-testid="back-button"]')).to be_displayed
    end

    it "creates a teacher account and shows a confirmation screen" do
      f('[data-testid="email-input"]').send_keys("teacher_test@example.com")
      f('[data-testid="name-input"]').send_keys("Teacher Testerson")
      f('[data-testid="submit-button"]').click
      wait_for_ajaximations
      wait_for_selector('[data-testid="dashboard-options-button"]')
      expect(f('[data-testid="dashboard-options-button"]')).to be_displayed
      # verify user was created in the DB
      user = User.find_by(name: "Teacher Testerson")
      expect(user).not_to be_nil
      expect(user.initial_enrollment_type).to eq("teacher")
      expect(user.pseudonym.unique_id).to eq("teacher_test@example.com")
    end

    describe "back navigation behavior" do
      it "returns to login page from Teacher registration form" do
        get "/login/canvas/register/teacher"
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Welcome to Canvas")
      end

      it "goes back to registration landing page if user navigated from login → registration landing page → teacher registration" do
        get "/login/canvas"
        f('[data-testid="create-account-link"]').click
        expect(f("h1").text).to include("Create Your Account")
        f('[data-testid="teacher-card-link"]').click
        expect(f("h1").text).to include("Create a Teacher Account")
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Create Your Account")
      end
    end
  end

  describe "access control" do
    it "redirects away from /login/canvas/register/teacher when self-registration is disabled" do
      get "/login/canvas/register/teacher"
      expect(f("h1").text).to include("Welcome to Canvas")
    end
  end
end
