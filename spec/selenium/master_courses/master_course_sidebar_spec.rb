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

require_relative '../common'
require_relative '../../apis/api_spec_helper'


shared_context "blueprint sidebar context" do
  let(:sync_button) {'.bcs__migration-sync__button button'}
  let(:unsynced_changes_link) {'#mcUnsyncedChangesBtn'}
  let(:blueprint_open_sidebar_button){f('.blueprint__root .bcs__wrapper .bcs__trigger') }
  let(:send_notification_checkbox) do
    f('.bcs__history-settings')
      .find_element(:xpath, "//span[text()[contains(., 'Send Notification')]]")
  end
  let(:add_message_checkbox) do
    f('.bcs__history-notification__add-message')
      .find_element(:xpath, "//label/span/span[text()[contains(., 'Add a Message')]]")
  end
  let(:notification_message_text_box) do
    f('.bcs__history-notification__add-message')
      .find_element(:xpath, "//label/span/span/span/textarea")
  end
  let(:character_count) { f('.bcs__history-notification__add-message').find_element(:xpath, "span") }

  def open_blueprint_sidebar
    get "/courses/#{@master.id}"
    blueprint_open_sidebar_button.click
  end
end


describe "master courses sidebar" do
  include_context "in-process server selenium tests"

  # copied from spec/apis/v1/master_templates_api_spec.rb
  def run_master_migration
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @master_teacher)
    run_jobs
    @migration.reload
  end

  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course

    # setup some stuff
    @file = attachment_model(context: @master, display_name: 'Some File')
    @assignment = @master.assignments.create! title: 'Blah', points_possible: 10
    run_master_migration

    # now push some incremental changes
    Timecop.freeze(2.seconds.from_now) do
      @page = @master.wiki.wiki_pages.create! title: 'Unicorn'
      page_tag = @template.content_tag_for(@page)
      page_tag.restrictions = @template.default_restrictions
      page_tag.save!
      @quiz = @master.quizzes.create! title: 'TestQuiz'
      @file = attachment_model(context: @master, display_name: 'Some File')
      @file.update(display_name: 'I Can Rename Files Too')
      @assignment.destroy
    end
  end

  describe "as a master course teacher" do
    before :each do
      user_session(@master_teacher)
    end

    it "should show sidebar trigger tab" do
     get "/courses/#{@master.id}"
     expect(f('.blueprint__root .bcs__wrapper .bcs__trigger')).to be_displayed
    end

    it "should show sidebar when trigger is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).to be_displayed
    end

    it "should not show the Associations button" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).not_to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Sync History modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('button#mcSyncHistoryBtn').click
      expect(f('div[aria-label="Sync History"]')).to be_displayed
      expect(f('#application')).to have_attribute('aria-hidden', 'true')
    end

    it "should show Unsynced Changes modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      wait_for_ajaximations
      f('button#mcUnsyncedChangesBtn').click
      wait_for_ajaximations
      expect(f('div[aria-label="Unsynced Changes"]')).to be_displayed
      expect(f('#application')).to have_attribute('aria-hidden', 'true')
    end

    it "should not show the tutorial sidebar button" do
      get "/courses/#{@master.id}"
      expect(f('body')).not_to contain_css('.TutorialToggleHolder button')
    end

  end

  describe "as a master course admin" do
    include_context "blueprint sidebar context"
    before :once do
      account_admin_user(active_all: true)
    end

    before :each do
      user_session(@admin)
    end

    it "should show the Associations button" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      expect(f('.bcs__content')).to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Associations modal when button is clicked" do
      get "/courses/#{@master.id}"
      f('.blueprint__root .bcs__wrapper .bcs__trigger').click
      f('button#mcSidebarAsscBtn').click
      expect(f('div[aria-label="Associations"]')).to be_displayed
    end

    it "limits notification message to 140 characters", priority: "2", test_id: 3186725 do
      msg = '1234567890123456789012345678901234567890123456789012345678901234567890'
      open_blueprint_sidebar
      send_notification_checkbox.click
      add_message_checkbox.click
      notification_message_text_box.send_keys(msg+msg+"A")
      expect(character_count).to include_text('(140/140)')
      expect(notification_message_text_box).not_to have_value('A')
    end

    it "removes sync button after sync", priority: "2", test_id: 3186726 do
      open_blueprint_sidebar
      send_notification_checkbox.click
      add_message_checkbox.click
      notification_message_text_box.send_keys("sync that!")
      f(sync_button).click
      run_jobs
      open_blueprint_sidebar
      begin
        f(sync_button) # button found ? go to the rescue statement : fail immediately
        error_text = "Sync button should not be in Blueprint sidebar when nothing is to be synced"
        expect(error_text).to eq(nil)
      rescue
        expect(f('.bcs__content')).not_to contain_css(unsynced_changes_link)
        expect(f('.bcs__content')).not_to include_text("Include Course Settings")
        expect(f('.bcs__content')).not_to include_text("Send Notification")
      end
    end
  end
end
