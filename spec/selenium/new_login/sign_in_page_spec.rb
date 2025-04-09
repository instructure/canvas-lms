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

describe "new login Sign In page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  describe "/login/canvas" do
    before do
      get "/login/canvas"
    end

    it "shows errors when submitted with no inputs" do
      f('[data-testid="login-button"]').click
      username_error = fxpath("//*[text()='Please enter your email.']")
      password_error = fxpath("//*[text()='Please enter your password.']")
      expect(username_error).to be_displayed
      expect(password_error).to be_displayed
    end

    it "shows password error when only email is filled in" do
      f('[data-testid="username-input"]').send_keys("test@example.com")
      f('[data-testid="login-button"]').click
      password_error = fxpath("//*[text()='Please enter your password.']")
      expect(password_error).to be_displayed
      expect(driver.switch_to.active_element.attribute("id")).to eq("password")
    end

    it "shows alert on invalid email/password" do
      f('[data-testid="username-input"]').send_keys("invalid@example.com")
      f('[data-testid="password-input"]').send_keys("wrongpassword123Ω")
      f('[data-testid="login-button"]').click
      alert = fxpath("//*[contains(text(), 'Please verify your email or password and try again.')]")
      expect(alert).to be_displayed
    end

    it "logs in with correct credentials and redirects" do
      user_with_pseudonym(
        active_user: true,
        username: "test1@example.com",
        password: "correctpassword123"
      )
      f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
      f('[data-testid="password-input"]').send_keys("correctpassword123")
      f('[data-testid="login-button"]').click
      wait_for(method: :login_redirect) do
        driver.current_url.include?("?login_success=1") &&
          element_exists?("#dashboard h1.screenreader-only")
      end
      expect(f("#dashboard h1.screenreader-only").text).to eq("Dashboard")
    end

    it "logs in with Remember Me checked" do
      user_with_pseudonym(
        active_user: true,
        username: "test2@example.com",
        password: "correctpassword123"
      )
      f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
      f('[data-testid="password-input"]').send_keys("correctpassword123")
      f('[data-testid="remember-me-checkbox"] + label').click
      f('[data-testid="login-button"]').click
      wait_for(method: :login_redirect) do
        driver.current_url.include?("?login_success=1")
      end
      expect(f("#dashboard h1.screenreader-only").text).to eq("Dashboard")
    end

    it "rejects login without CSRF token" do
      driver.manage.delete_cookie("_csrf_token")
      f('[data-testid="username-input"]').send_keys("test@example.com")
      f('[data-testid="password-input"]').send_keys("correctpassword123")
      f('[data-testid="login-button"]').click
      alert = fxpath("//*[contains(text(), 'Please verify your email or password and try again.')]")
      expect(alert).to be_displayed
    end
  end

  describe "/login/ldap" do
    context "when no LDAP authentication provider is configured" do
      it "returns 404" do
        get "/login/ldap"
        expect(ff("h1").map(&:text)).to include(
          "Whoops... Looks like nothing is here!",
          "Page Not Found"
        )
      end
    end

    context "when an LDAP authentication provider is configured" do
      before do
        Account.default.authentication_providers.create!(
          auth_type: "ldap",
          auth_host: "127.0.0.1",
          auth_filter: "filter1",
          auth_username: "username1",
          auth_password: "password1",
          position: 1,
          jit_provisioning: false
        )
        get "/login/ldap"
      end

      it "renders the LDAP sign-in page and posts to /login/ldap" do
        expect(f("h1").text).to include("Welcome to Canvas")
        expect(f('[data-testid="username-input"]')).to be_displayed
        expect(f('[data-testid="password-input"]')).to be_displayed
        form = f("form")
        expect(form.attribute("action")).to include("/login/ldap")
      end
    end
  end

  describe "front-end mount gating" do
    it "renders the React login app when #new_login_safe_to_mount is present" do
      get "/login/canvas"
      expect(element_exists?("#new_login_safe_to_mount")).to be true
      expect(f('[data-testid="username-input"]')).to be_displayed
    end

    it "does not render the React login app when #new_login_safe_to_mount is missing (e.g. 404)" do
      get "/login/bad"
      expect(ff("h1").map(&:text)).to include(
        "Whoops... Looks like nothing is here!",
        "Page Not Found"
      )
      expect(element_exists?("#new_login_safe_to_mount")).to be false
      expect(element_exists?('[data-testid="username-input"]')).to be false
    end
  end
end
