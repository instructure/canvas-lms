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

require_relative "../common"

describe "new login Forgot Password page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  it "navigates to the Forgot Password page" do
    get "/login/canvas"
    f('[data-testid="forgot-password-link"]').click
    expect(f("h1").text).to include("Forgot password?")
    expect(f('[data-testid="email-input"]')).to be_displayed
  end

  it "navigates to custom forgot password URL if configured" do
    Account.default.settings[:change_password_url] = "https://example.com/forgot"
    Account.default.save!
    get "/login/canvas"
    link = f('[data-testid="forgot-password-link"]')
    expect(link.attribute("href")).to eq("https://example.com/forgot")
  end

  it "shows an error when submitting with no email" do
    get "/login/canvas/forgot-password"
    find_by_test_id("submit-button").click
    error_el = fxpath("//*[text()='Please enter a valid email.']")
    expect(error_el).to be_displayed
  end

  it "shows an error for invalid email format" do
    get "/login/canvas/forgot-password"
    find_by_test_id("email-input").send_keys("notanemail")
    find_by_test_id("submit-button").click
    error_el = fxpath("//*[text()='Please enter a valid email.']")
    expect(error_el).to be_displayed
  end

  it "shows confirmation message for valid email" do
    user_with_pseudonym(active_user: true, unique_id: "forgotme@example.com")
    get "/login/canvas/forgot-password"
    f('[data-testid="email-input"]').send_keys("forgotme@example.com")
    f('[data-testid="submit-button"]').click
    expect(f('[data-testid="confirmation-heading"]').text).to include("Check Your Email")
    expect(f('[data-testid="confirmation-message"]').text).to include("forgotme@example.com")
  end

  describe "back navigation behavior" do
    it "returns to login page from confirmation screen" do
      user_with_pseudonym(active_user: true, unique_id: "forgotme@example.com")
      get "/login/canvas/forgot-password"
      f('[data-testid="email-input"]').send_keys("forgotme@example.com")
      f('[data-testid="submit-button"]').click
      expect(f('[data-testid="confirmation-heading"]').text).to include("Check Your Email")
      f('[data-testid="confirmation-back-button"]').click
      wait_for_selector("h1")
      expect(f("h1").text).to include("Welcome to Canvas")
    end

    it "goes back to login if user navigated from login → forgot-password" do
      get "/login/canvas"
      f('[data-testid="forgot-password-link"]').click
      expect(f("h1").text).to include("Forgot password?")
      f('[data-testid="cancel-button"]').click
      expect(f("h1").text).to include("Welcome to Canvas")
    end

    it "returns to login page from Forgot Password" do
      get "/login/canvas/forgot-password"
      f('[data-testid="cancel-button"]').click
      expect(f("h1").text).to include("Welcome to Canvas")
    end
  end
end
