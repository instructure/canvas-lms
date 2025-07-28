# frozen_string_literal: true

# Copyright (C) 2014 - present Instructure, Inc.
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

require "rspec"
require_relative "../common"
require_relative "pages/past_global_announcements_page"

describe "PastGlobalAnnouncements Select" do
  let(:course) { course_model.tap(&:offer!) }
  let(:student) { student_in_course(course:, name: "student", display_name: "mister student", active_all: true).user }

  include_context "in-process server selenium tests"

  context "when instui nav feature flag on" do
    before do
      @account = Account.default
      @account.enable_feature!(:instui_nav)
      user_session(student)
      get "/account_notifications"
      wait_for_ajaximations
    end

    it "select should be visible on low resolution" do
      driver.manage.window.resize_to(700, 1200)
      expect(PastGlobalAnnouncements.view_select).to be_displayed
    end

    it "select should not be visible on higher resolution" do
      driver.manage.window.resize_to(1500, 1200)
      expect { PastGlobalAnnouncements.view_select }.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
    end

    it "tabs should not be visible on low resolution" do
      driver.manage.window.resize_to(700, 1200)
      wait_for_ajaximations
      expect { PastGlobalAnnouncements.tabs }.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
    end

    it "tabs should be visible on higher resolution" do
      driver.manage.window.resize_to(1500, 1200)
      expect(PastGlobalAnnouncements.tabs).to be_displayed
    end

    it "Active Announcements should be displayed after selecting Current option in select" do
      driver.manage.window.resize_to(700, 1200)
      PastGlobalAnnouncements.view_select.click
      wait_for_ajaximations
      PastGlobalAnnouncements.current_select_option.click
      wait_for_ajaximations
      expect(driver.page_source).to include("Active Announcements")
    end

    it "Past Announcements should be displayed after selecting Recent in select" do
      driver.manage.window.resize_to(700, 1200)
      PastGlobalAnnouncements.view_select.click
      wait_for_ajaximations
      PastGlobalAnnouncements.past_select_option.click
      wait_for_ajaximations
      expect(driver.page_source).to include("Announcements from the past four months")
    end
  end
end
