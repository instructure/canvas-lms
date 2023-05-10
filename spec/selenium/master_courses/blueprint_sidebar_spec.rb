# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
require_relative "../helpers/blueprint_common"

shared_context "blueprint sidebar context" do
  def sync_button
    f(".bcs__migration-sync__button button")
  end

  def unsynced_changes_link
    f(".bcs__content button#mcUnsyncedChangesBtn")
  end

  def blueprint_open_sidebar_button
    f(".blueprint__root .bcs__wrapper .bcs__trigger button")
  end

  def blueprint_mobile_open_sidebar_button
    f("#mobile-header .mobile-header-blueprint-button")
  end

  def sync_modal_send_notification_checkbox
    fj("label span:contains('Send Notification')", f(".bcs__modal-content-wrapper .bcs__history"))
  end

  def sync_modal_add_message_checkbox
    fj("label span:contains('Add a Message')", f(".bcs__modal-content-wrapper .bcs__history"))
  end

  def sync_modal_message_text_box
    f("textarea", f(".bcs__modal-content-wrapper"))
  end

  def send_notification_checkbox
    f(".bcs__body fieldset")
      .find_element(:xpath, "//span[text()[contains(., 'Send Notification')]]")
  end

  def add_message_checkbox
    f(".bcs__history-notification__add-message label")
  end

  def notification_message_text_box
    f(".bcs__history-notification__message textarea")
  end

  def character_count
    f(".bcs__history-notification__add-message span[aria-label]")
  end

  def modal_sync_button
    f("#unsynced_changes_modal_sync .bcs__migration-sync__button")
  end

  def open_blueprint_sidebar
    get "/courses/#{@master.id}"
    blueprint_open_sidebar_button.click
  end

  def bcs_content_panel
    f(".bcs__content")
  end
end

describe "master courses sidebar" do
  include_context "in-process server selenium tests"
  include_context "blueprint sidebar context"
  include BlueprintCourseCommon

  before :once do
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course

    # setup some stuff
    @file = attachment_model(context: @master, display_name: "Some File")
    @assignment = @master.assignments.create! title: "Blah", points_possible: 10
    run_master_course_migration(@master)

    # now push some incremental changes
    Timecop.freeze(2.seconds.from_now) do
      @page = @master.wiki_pages.create! title: "Unicorn"
      page_tag = @template.content_tag_for(@page)
      page_tag.restrictions = @template.default_restrictions
      page_tag.save!
      @quiz = @master.quizzes.create! title: "TestQuiz"
      @file = attachment_model(context: @master, display_name: "Some File")
      @file.update(display_name: "I Can Rename Files Too")
      @assignment.destroy
    end
  end

  describe "as a master course teacher" do
    before do
      user_session(@master_teacher)
    end

    it "shows sidebar trigger tab" do
      get "/courses/#{@master.id}"
      expect(blueprint_open_sidebar_button).to be_displayed
    end

    it "show mobile trigger button and hides trigger tab" do
      resize_screen_to_mobile_width
      get "/courses/#{@master.id}"
      expect(blueprint_open_sidebar_button).to_not be_displayed
      expect(blueprint_mobile_open_sidebar_button).to be_displayed
    end

    it "shows sidebar when trigger is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).to be_displayed
    end

    it "shows sidebar when mobile trigger is clicked" do
      resize_screen_to_mobile_width
      get "/courses/#{@master.id}"
      blueprint_mobile_open_sidebar_button.click
      expect(bcs_content_panel).to be_displayed
    end

    it "does not show the Associations button" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).not_to contain_css("button#mcSidebarAsscBtn")
    end

    it "shows Sync History modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      f("button#mcSyncHistoryBtn").click
      expect(f('span[aria-label="Sync History"]')).to be_displayed
      expect(f("#application")).to have_attribute("aria-hidden", "true")
    end

    it "shows Unsynced Changes modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      wait_for_ajaximations
      f("button#mcUnsyncedChangesBtn").click
      wait_for_ajaximations
      expect(f('span[aria-label="Unsynced Changes"]')).to be_displayed
      expect(f("#application")).to have_attribute("aria-hidden", "true")
    end

    it "does not show the tutorial sidebar button" do
      get "/courses/#{@master.id}"
      expect(f("body")).not_to contain_css(".TutorialToggleHolder button")
    end
  end

  describe "as a master course admin" do
    before :once do
      account_admin_user(active_all: true)
    end

    before do
      user_session(@admin)
    end

    it "shows the Associations button" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).to contain_css("button#mcSidebarAsscBtn")
    end

    it "shows Associations modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      f("button#mcSidebarAsscBtn").click
      expect(f('span[aria-label="Associations"]')).to be_displayed
    end

    it "opens and close Associations modal from course settings page" do
      # see jira ticket ADMIN-5
      get "/courses/#{@master.id}/settings"
      blueprint_open_sidebar_button.click
      f("button#mcSidebarAsscBtn").click
      expect(f('span[aria-label="Associations"]')).to be_displayed
      f("body").find_element(:xpath, '//*[@aria-label="Associations"]//button[contains(., "Close")]').click
      expect(f("body")).not_to contain_css('[aria-label="Associations"]')
      # try again from the sections tab, just to be sure
      f("#sections_tab>a").click
      expect(f("#tab-sections")).to be_displayed
      f("button#mcSidebarAsscBtn").click
      expect(f('span[aria-label="Associations"]')).to be_displayed
      f("body").find_element(:xpath, '//*[@aria-label="Associations"]//button[contains(., "Close")]').click
      expect(f("body")).not_to contain_css('[aria-label="Associations"]')
    end

    it "limits notification message to 140 characters", priority: "2" do
      msg = "1234567890123456789012345678901234567890123456789012345678901234567890"
      open_blueprint_sidebar
      send_notification_checkbox.click
      add_message_checkbox.click
      notification_message_text_box.send_keys(msg + msg + "A")
      expect(character_count).to include_text("(140/140)")
      expect(notification_message_text_box).not_to have_value("A")
    end

    it "updates screenreader character usage message with character count" do
      skip("This needs to be skipped until ADMIN-793 is resolved")
      inmsg = "1234567890123456789012345678901234567890"
      open_blueprint_sidebar
      # if the default ever changes in MigrationOptions, make sure our spec still works
      driver.execute_script("ENV.MIGRATION_OPTIONS_SR_ALERT_TIMEOUT = 15")
      send_notification_checkbox.click
      add_message_checkbox.click
      # we don't start adding the message until 90% full
      notification_message_text_box.send_keys(inmsg + inmsg + inmsg + "abcdefg")
      alert_text = "127 of 140 maximum characters"
      # the screenreader message is displayed after a 600ms delay
      # not waiting leads to a flakey spec
      wait = Selenium::WebDriver::Wait.new(timeout: 0.7)
      wait.until { expect(fj("#flash_screenreader_holder:contains(#{alert_text})")).to be_present }
    end

    it "issues screenreader alert when message is full" do
      msg = "1234567890123456789012345678901234567890123456789012345678901234567890"
      open_blueprint_sidebar
      send_notification_checkbox.click
      add_message_checkbox.click
      notification_message_text_box.send_keys(msg + msg + "12")
      alert_text = "You have reached the limit of 140 characters in the notification message"

      expect(fj("#flash_screenreader_holder:contains(#{alert_text})")).to be_present
    end

    context "before sync" do
      it "shows sync button and options before sync", priority: "2" do
        open_blueprint_sidebar
        bcs_content = bcs_content_panel
        expect(bcs_content).to include_text("Unsynced Changes")
        expect(bcs_content).to contain_css(".bcs__row-right-content")
        expect(bcs_content).to include_text("Include Course Settings")
        expect(bcs_content).to include_text("Send Notification")
        expect(bcs_content).to contain_css(".bcs__migration-sync__button")
      end

      it "shows sync options in modal", priority: "2" do
        open_blueprint_sidebar
        unsynced_changes_link.click
        bcs_content = bcs_content_panel
        expect(bcs_content).to include_text("Unsynced Changes")
        expect(bcs_content).to contain_css(".bcs__row-right-content")
        expect(bcs_content).to include_text("Include Course Settings")
        expect(bcs_content).to include_text("Send Notification")
        expect(bcs_content).to contain_css(".bcs__migration-sync__button")
      end
    end

    context "after sync" do
      before do
        open_blueprint_sidebar
        send_notification_checkbox.click
        add_message_checkbox.click
        notification_message_text_box.send_keys("sync that!")
        sync_button.click
        run_jobs
      end

      it "removes sync button after sync", priority: "2" do
        refresh_page
        open_blueprint_sidebar
        test_var = false
        begin
          sync_button
        rescue
          test_var = true
        end
        expect(test_var).to be_truthy, "Sync button should not appear"
        expect(bcs_content_panel).not_to contain_css("button#mcUnsyncedChangesBtn")
      end

      it "removes notification options after sync", priority: "2" do
        refresh_page
        open_blueprint_sidebar
        test_var = false
        begin
          unsynced_changes_link
        rescue
          test_var = true
        end
        expect(test_var).to be_truthy, "Unsynced changes link should not appear"
        bcs_content = bcs_content_panel
        expect(bcs_content).not_to include_text("Include Course Settings")
        expect(bcs_content).not_to include_text("Send Notification")
        expect(bcs_content).not_to contain_css("bcs__row-right-content")
        expect(bcs_content).not_to include_text("Add a Message")
        expect(bcs_content).not_to contain_css(".bcs__history-notification__message")
      end
    end

    it "closes modal after sync", priority: "2" do
      open_blueprint_sidebar
      unsynced_changes_link.click
      sync_modal_send_notification_checkbox.click
      sync_modal_add_message_checkbox.click
      sync_modal_message_text_box.send_keys("sync that!")
      modal_sync_button.click
      run_jobs
      expect(f(".bcs__content")).not_to contain_css(".bcs__content button#mcUnsyncedChangesBtn")
    end
  end
end
