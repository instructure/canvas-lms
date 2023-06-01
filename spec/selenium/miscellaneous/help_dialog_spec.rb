# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "help dialog" do
  include_context "in-process server selenium tests"

  context "no user logged in" do
    it "works with no logged in user" do
      Setting.set("show_feedback_link", "true")
      get("/login")
      f("#footer .help_dialog_trigger").click
      wait_for_ajaximations
      expect(f("#help-dialog-options")).to be_displayed
    end

    it "no longer shows a browser warning for IE" do
      Setting.set("show_feedback_link", "true")
      get("/login")
      driver.execute_script("window.INST = window.INST || {}")
      driver.execute_script("window.INST.browser = {ie: true, version: 8}")
      f("#footer .help_dialog_trigger").click
      wait_for_ajaximations
      expect_no_flash_message :error
    end
  end

  context "help as a student" do
    before do
      course_with_student_logged_in(active_all: true)
    end

    it "shows the Help dialog when help is clicked and feedback is enabled" do
      Setting.set("show_feedback_link", "true")
      get "/dashboard"
      expect(f("body")).not_to contain_css("#help_tray")
      expect(f("#content")).not_to contain_css(".help_dialog_trigger")

      support_url = "http://example.com/support"
      Account.default.update_attribute(:settings, { support_url: })

      get "/dashboard"
      expect(ff("#global_nav_help_link").length).to eq(1)
      expect(f("body")).not_to contain_css("#help_tray")
      f("#global_nav_help_link").click

      wait_for_ajaximations

      expect(f("#help_tray")).to be_displayed
      expect(f("#help_tray a[href='#teacher_feedback']")).to be_displayed
    end

    it "shows the support url link in global nav correctly" do
      # if @domain_root_account or Account.default have settings[:support_url] set there should be a link to that site
      support_url = "http://example.com/support"
      Account.default.update_attribute(:settings, { support_url: })
      get "/dashboard"
      link = f("a[href='#{support_url}']")
      expect(link["id"]).to eq "global_nav_help_link"
    end

    it "allows sending the teacher a message" do
      Setting.set("show_feedback_link", "true")
      course_with_ta(course: @course)
      get "/courses/#{@course.id}"
      expect(f("body")).not_to contain_css("#help_tray")
      trigger = f("#global_nav_help_link")
      expect(trigger).to be_displayed
      trigger.click
      wait_for_ajaximations
      expect(f("#help_tray")).to be_displayed
      teacher_feedback_link = f("#help_tray a[href='#teacher_feedback']")
      expect(teacher_feedback_link).to be_displayed
      sleep 0.3 # have to wait for instUI tray animations
      teacher_feedback_link.click
      feedback_form = f("form[action='/api/v1/conversations']")
      wait_for_ajaximations
      expect(feedback_form.find_element(:css, '[name="recipients[]"]')["value"]).to eq "course_#{@course.id}_admins"
      feedback_form.find_element(:css, '[name="body"]').send_keys("test message")
      submit_form(feedback_form)
      wait_for_ajaximations
      expect(f("body")).not_to contain_css("form[action='/api/v1/conversations']")
      cm = ConversationMessage.last
      expect(cm.recipients).to match_array @course.instructors
      expect(cm.recipients.count).to eq 2
      expect(cm.body).to match(/test message/)
    end

    # TODO: reimplement per CNVS-29608, but make sure we're testing at the right level
    it "should allow submitting a ticket"
  end

  context "help dialog as a teacher" do
    before do
      course_with_teacher_logged_in(active_all: true)
    end

    it "does not show the Message teacher button if not a student" do
      Setting.set("show_feedback_link", "true")
      get "/dashboard"
      f("#global_nav_help_link").click
      wait_for_ajaximations
      expect(f("#help_tray")).to be_displayed
      expect(f("#help_tray")).not_to contain_css("a[href='#teacher_feedback']")
    end

    it "shows the Help item in the SpeedGrader settings menu when feedback is enabled" do
      @course.enroll_student(User.create).accept!
      @assignment = @course.assignments.create

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css(".help_dialog_trigger")

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      settings_menu = f("#speed_grader_settings_mount_point")
      settings_menu.click

      trigger = f("ul[role=menu] span[name=help][role=menuitem]")

      trigger.location_once_scrolled_into_view
      expect(trigger).to be_displayed
    end
  end

  context "customization link" do
    before do
      user_logged_in(active_all: true)
    end

    it "shows the link to root account admins" do
      Account.default.account_users.create!(user: @user)
      get "/"
      wait_for_ajaximations
      f("#global_nav_help_link").click
      wait_for_ajaximations
      expect(f("#help_tray")).to include_text("Customize this menu")
    end

    it "does not show the link to sub account admins" do
      sub = Account.default.sub_accounts.create!
      sub.account_users.create!(user: @user)
      get "/"
      wait_for_ajaximations
      f("#global_nav_help_link").click
      wait_for_ajaximations
      expect(f("#help_tray")).to_not include_text("Customize this menu")
    end
  end

  context "featured and new links" do
    before do
      user_logged_in(active_all: true)
      Account.site_admin.enable_feature! :featured_help_links
      Account.default.account_users.create!(user: @user)
    end

    it "has the default link at the top of the tray" do
      get "/accounts/#{Account.default.id}/settings"
      f(".HelpMenuOptions__Container button").click
      fj('[role="menuitemradio"] span:contains("Add Custom Link")').click
      replace_content fj('#custom_help_link_settings input[name$="[text]"]:visible'), "FEATURED LINK"
      replace_content fj('#custom_help_link_settings textarea[name$="[subtext]"]:visible'), "FEATURED subtext"
      replace_content fj('#custom_help_link_settings input[name$="[url]"]:visible'), "https://featuredurl.example.com"
      fj('#custom_help_link_settings fieldset .ic-Label:contains("Featured"):visible').click
      f('#custom_help_link_settings button[type="submit"]').click
      form = f("#account_settings")
      expect_new_page_load { form.submit }
      f("#global_nav_help_link").click
      wait_for_ajaximations
      expect(fxpath("//span[img[@data-testid = 'cheerful-panda-svg']]//span[contains(text(),'FEATURED LINK')]")).to include_text("FEATURED LINK")
    end

    it "has a New Link in the tray" do
      get "/accounts/#{Account.default.id}/settings"
      f(".HelpMenuOptions__Container button").click
      fj('[role="menuitemradio"] span:contains("Add Custom Link")').click
      replace_content fj('#custom_help_link_settings input[name$="[text]"]:visible'), "NEW LINK"
      replace_content fj('#custom_help_link_settings textarea[name$="[subtext]"]:visible'), "NEW subtext"
      replace_content fj('#custom_help_link_settings input[name$="[url]"]:visible'), "https://newurl.example.com"
      fj('#custom_help_link_settings fieldset .ic-Label:contains("New"):visible').click
      f('#custom_help_link_settings button[type="submit"]').click
      form = f("#account_settings")
      expect_new_page_load { form.submit }
      f("#global_nav_help_link").click
      wait_for_ajaximations
      expect(fj('div#help_tray li:contains("NEW LINK")')).to include_text("NEW subtext")
    end
  end

  context "welcome tour" do
    before do
      course_with_student_logged_in(active_all: true)
      Account.default.enable_feature!("product_tours")
    end

    it "opens up the welcome tour on page load and shows the welcome tour link and opens the tour when clicked" do
      course_with_ta(course: @course)
      get "/"
      driver.local_storage.clear
      wait_for_ajaximations

      get "/courses/#{@course.id}"
      wait_for_ajaximations
      wait_for(method: nil, timeout: 1) { f("#___reactour").displayed? }
      # Welcome tour is already opened
      expect(f("#___reactour")).to include_text(
        "Here's some quick tips to get you started in Canvas!"
      )

      # Close the currently-open tutorial overlay
      close = f("#___reactour .tour-close-button button")
      close.click
      wait_for_ajaximations

      expect(f("#___reactour")).to include_text(
        "You can access the Welcome Tour here any time as well as other new resources."
      )
      close = f("#___reactour .tour-close-button button")
      close.click
    end

    it "shows the welcome tour for Account Admins" do
      Account.default.account_users.create!(user: @user)
      get "/"
      driver.local_storage.clear
      wait_for_ajaximations

      # Reload so the local storage clearing take effect
      get "/"
      wait_for_ajaximations
      wait_for(method: nil, timeout: 1) { f("#___reactour").displayed? }
      # Welcome tour is already opened
      expect(f("#___reactour")).to include_text(
        "We know it's a priority to transition your institution for online learning during this time."
      )

      # Close the currently-open tutorial overlay
      close = f("#___reactour .tour-close-button button")
      close.click
      wait_for_ajaximations

      expect(f("#___reactour")).to include_text(
        "You can access the Welcome Tour here any time as well as other new resources."
      )
      close = f("#___reactour .tour-close-button button")
      close.click
    end
  end
end
