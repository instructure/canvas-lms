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

describe "new login Parent Registration page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  describe "when self-registration is enabled as “observer”" do
    before do
      # this page is also accessible when self-registration is set to “all”
      # but behavior is identical, so we only test the “observer" case here
      Account.default.canvas_authentication_provider.update!(self_registration: "observer")
      # disable terms to avoid interaction Selenium click issues with checkbox label (has inline links)
      Account.default.root_account.create_terms_of_service!(passive: true)
    end

    it "shows the Parent registration form with required fields" do
      get "/login/canvas/register/parent"
      expect(f("h1").text).to include("Create a Parent Account")
      expect(f('[data-testid="email-input"]')).to be_displayed
      expect(f('[data-testid="password-input"]')).to be_displayed
      expect(f('[data-testid="confirm-password-input"]')).to be_displayed
      expect(f('[data-testid="name-input"]')).to be_displayed
      expect(f('[data-testid="pairing-code-input"]')).to be_displayed
      expect(f('[data-testid="pairing-code-link"]')).to be_displayed
      expect(f('[data-testid="submit-button"]')).to be_displayed
      expect(f('[data-testid="back-button"]')).to be_displayed
    end

    it "creates a parent account and shows a confirmation screen" do
      get "/login/canvas/register/parent"
      # generate a valid pairing code from a real user
      student = user_with_pseudonym(active_user: true)
      pairing_code = student.generate_observer_pairing_code.code
      f('[data-testid="email-input"]').send_keys("parent_test@example.com")
      f('[data-testid="password-input"]').send_keys("Password123!")
      f('[data-testid="confirm-password-input"]').send_keys("Password123!")
      f('[data-testid="name-input"]').send_keys("Parent Testerson")
      f('[data-testid="pairing-code-input"]').send_keys(pairing_code)
      f('[data-testid="submit-button"]').click
      wait_for_ajaximations
      wait_for_selector('[data-testid="dashboard-options-button"]')
      expect(f('[data-testid="dashboard-options-button"]')).to be_displayed
      # verify user was created in the DB
      user = User.find_by(name: "Parent Testerson")
      expect(user).not_to be_nil
      expect(user.initial_enrollment_type).to eq("observer")
      expect(user.pseudonym.unique_id).to eq("parent_test@example.com")
    end

    describe "back navigation behavior" do
      it "returns to login page from Parent registration form" do
        get "/login/canvas/register/parent"
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Welcome to Canvas")
      end

      it "goes back to login if user navigated from login → parent registration" do
        get "/login/canvas"
        f('[data-testid="create-parent-account-link"]').click
        expect(f("h1").text).to include("Create a Parent Account")
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Welcome to Canvas")
      end
    end
  end

  describe "when self-registration is enabled as “all”" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
      Account.default.root_account.create_terms_of_service!(passive: true)
    end

    describe "back navigation behavior" do
      it "returns to login page from Parent registration form" do
        get "/login/canvas/register/parent"
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Welcome to Canvas")
      end

      it "goes back to registration landing page if user navigated from login → registration landing page → parent registration" do
        get "/login/canvas"
        f('[data-testid="create-account-link"]').click
        expect(f("h1").text).to include("Create Your Account")
        f('[data-testid="parent-card-link"]').click
        expect(f("h1").text).to include("Create a Parent Account")
        f('[data-testid="back-button"]').click
        wait_for_selector("h1")
        expect(f("h1").text).to include("Create Your Account")
      end
    end
  end

  describe "access control" do
    it "redirects away from /login/canvas/register/parent when self-registration is disabled" do
      get "/login/canvas/register/parent"
      expect(f("h1").text).to include("Welcome to Canvas")
    end
  end
end
