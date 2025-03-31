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

describe "new login Registration Landing page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  describe "when self-registration is disabled" do
    it "does not show the create account link" do
      get "/login/canvas"
      expect(element_exists?('[data-testid="self-registration-prompt"]')).to be(false)
      expect(element_exists?('[data-testid="create-parent-account-link"]')).to be(false)
      expect(element_exists?('[data-testid="create-account-link"]')).to be(false)
    end
  end

  describe "when self-registration is set to 'all'" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
    end

    it "shows the registration landing page with Teacher, Student, and Parent options" do
      get "/login/canvas"
      expect(element_exists?('[data-testid="self-registration-prompt"]')).to be(true)
      expect(element_exists?('[data-testid="create-account-link"]')).to be(true)
      expect(element_exists?('[data-testid="create-parent-account-link"]')).to be(false)
      f('[data-testid="create-account-link"]').click
      expect(f("h1").text).to include("Create Your Account")
      registration_options = ff("button, a").map(&:text)
      expect(registration_options).to include("Teacher", "Student", "Parent")
    end
  end

  describe "when self-registration is set to 'parent'" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "observer")
    end

    it "shows a link to create a Parent account and navigates directly to the Parent registration form" do
      get "/login/canvas"
      expect(element_exists?('[data-testid="create-account-link"]')).to be(false)
      expect(element_exists?('[data-testid="create-parent-account-link"]')).to be(true)
      f('[data-testid="create-parent-account-link"]').click
      expect(f("h1").text).to include("Create a Parent Account")
    end
  end

  describe "registration landing page at /login/canvas/register" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
      get "/login/canvas/register"
    end

    it "navigates to the Teacher registration form" do
      expect(f("h1").text).to include("Create Your Account")
      f('[data-testid="teacher-card-link"]').click
      expect(f("h1").text).to include("Create a Teacher Account")
    end

    it "navigates to the Student registration form" do
      expect(f("h1").text).to include("Create Your Account")
      f('[data-testid="student-card-link"]').click
      expect(f("h1").text).to include("Create a Student Account")
    end

    it "navigates to the Parent registration form" do
      expect(f("h1").text).to include("Create Your Account")
      f('[data-testid="parent-card-link"]').click
      expect(f("h1").text).to include("Create a Parent Account")
    end
  end

  describe "registration routes access control" do
    it "redirects away from /login/canvas/register when self-registration is disabled" do
      get "/login/canvas/register"
      expect(f("h1").text).to include("Welcome to Canvas")
    end
  end

  describe "legacy registration routes" do
    before do
      Account.default.canvas_authentication_provider.update!(self_registration: "all")
    end

    it "redirects /register to /login/canvas/register" do
      get "/register"
      expect(f("h1").text).to include("Create Your Account")
    end

    it "redirects /register_from_website to /login/canvas/register" do
      get "/register_from_website"
      expect(f("h1").text).to include("Create Your Account")
    end
  end
end
