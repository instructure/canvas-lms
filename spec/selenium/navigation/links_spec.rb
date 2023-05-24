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

describe "links", priority: "2" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
  end

  describe "course links" do
    before do
      get "/courses/#{@course.id}"
    end

    def find_link(link_css)
      link_section = f("#section-tabs")
      link_section.find_element(:css, link_css)
    end

    it "navigates user to home page after home link is clicked" do
      expect_new_page_load { fln("Home").click }
      expect(f("#course_home_content")).to be_displayed
    end

    it "navigates user to announcements page after announcements link is clicked" do
      link = find_link(".announcements")
      validate_breadcrumb_link(link, "Announcements")
    end

    it "navigates user to assignments page after assignments link is clicked" do
      link = find_link(".assignments")
      validate_breadcrumb_link(link, "Assignments")
    end

    it "navigates user to discussions page after discussions link is clicked" do
      link = find_link(".discussions")
      validate_breadcrumb_link(link, "Discussions")
    end

    it "navigates user to gradebook page after grades link is clicked" do
      link = find_link(".grades")
      validate_breadcrumb_link(link, "Grades")
    end

    it "navigates user to users page after people link is clicked" do
      link = find_link(".people")
      validate_breadcrumb_link(link, "People")
    end

    it "navigates user to wiki page after pages link is clicked" do
      link = find_link(".pages")
      validate_breadcrumb_link(link, "Pages")
    end

    it "navigates user to files page after files link is clicked" do
      link = find_link(".files")
      validate_breadcrumb_link(link, "Files")
    end

    it "navigates user to syllabus page after syllabus link is clicked" do
      link = find_link(".syllabus")
      validate_breadcrumb_link(link, "Syllabus")
    end

    it "navigates user to outcomes page after outcomes link is clicked" do
      link = find_link(".outcomes")
      validate_breadcrumb_link(link, "Outcomes")
    end

    it "navigates user to quizzes page after quizzes link is clicked" do
      link = find_link(".quizzes")
      validate_breadcrumb_link(link, "Quizzes")
    end

    it "navigates user to modules page after modules link is clicked" do
      link = find_link(".modules")
      validate_breadcrumb_link(link, "Modules")
    end

    it "navigates user to settings page after settings link is clicked" do
      link = find_link(".settings")
      validate_breadcrumb_link(link, "Settings")
    end
  end

  describe "account links" do
    before :once do
      @account = Account.default
      account_admin_user(account: @account, user: @user)
    end

    before do
      user_session(@user)
    end

    it "shows new pill on new tabs for user until the feature is visited" do
      get "/accounts/#{@account.id}"
      account_calendars_link = f("#section-tabs a.account_calendars")
      expect(account_calendars_link).to include_text "New"
      expect(f("#section-tabs a.courses")).not_to include_text "New"
      expect(f("#section-tabs a.permissions")).not_to include_text "New"
      expect(@user.reload.get_preference(:visited_tabs)).to be_nil

      account_calendars_link.click
      account_calendars_link = f("#section-tabs a.account_calendars")
      expect(account_calendars_link).not_to include_text "New"
      expect(@user.reload.get_preference(:visited_tabs)).to eq ["account_calendars"]
    end
  end

  describe "dashboard links" do
    before do
      get "/"
    end

    context "right side links" do
      context "when react_inbox feature flag is off" do
        it "navigates user to conversations page after inbox link is clicked" do
          Account.default.set_feature_flag! :react_inbox, "off"
          expect_new_page_load { fj("#global_nav_conversations_link").click }
          expect(f("i.icon-email")).to be_displayed
        end
      end

      it "navigates user to user settings page after settings link is clicked" do
        expect_new_page_load do
          f("#global_nav_profile_link").click
          fj('[aria-label="Profile tray"] a:contains("Settings")').click
        end
        expect(f("a.edit_settings_link")).to be_displayed
      end
    end

    context "global nav links" do
      it "navigates user to main page after canvas logo link is clicked" do
        expect_new_page_load { f("#header .ic-app-header__logomark").click }
        expect(driver.current_url).to eq dashboard_url
      end

      it "navigates user to the calendar page after calender link is clicked" do
        expect_new_page_load { fln("Calendar").click }
        expect(f(".calendar_header")).to be_displayed
      end

      it "navigates to main content from skip_to_link" do
        driver.action.send_keys(:tab).perform
        expect(check_element_has_focus(f("a#skip_navigation_link"))).to be(true)
        driver.action.send_keys(:enter).perform
        expect(driver.switch_to.active_element.attribute("id")).to eq("content")
      end
    end
  end
end
