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

require_relative "../helpers/wiki_and_tiny_common"
require_relative "../test_setup/common_helper_methods/custom_selenium_actions"
require_relative "pages/rce_next_page"

describe "RCE Next autosave feature", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include CustomSeleniumActions
  include RCENextPage

  def wait_for_rce
    wait_for_tiny(f(".tox-edit-area"))
  end

  def autosave_key(user_id = @teacher.id, url = driver.current_url, textarea_id = "discussion-topic-message10")
    "rceautosave:#{user_id}#{url}:#{textarea_id}"
  end

  def edit_announcement(text = "hello")
    insert_tiny_text text
  end

  context "WYSIWYG generic as a teacher" do
    before do
      Setting.set("rce_auto_save_max_age_ms", 1.hour.to_i * 1_000)
      course_with_teacher_logged_in
      stub_rcs_config
      @teacher.update! uuid: "kDEDLQJhhoVaIGHbunzuUnt6yiZwja4am90LMfCr"
    end

    def make_autosave_entry(content, time = Time.zone.now.to_i * 1_000)
      "{\"autosaveTimestamp\": \"#{time}\", \"content\": \"#{content}\"}"
    end

    def create_announcement
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      wait_for_rce
    end

    def create_and_edit_announcement
      create_announcement
      edit_announcement
    end

    it "autosaves encrypted content" do
      skip "LF-716 (9/5/2023)"
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)
      expect(JSON.parse(saved_content)["content"]).to match("JvwYPc4X9emMRM+w6MEuRvGQiS7d9Vwtuu4=")
      driver.local_storage.clear
    end

    it "autosaves encrypted content entered in htmlview" do
      skip "LF-716 (9/5/2023)"
      create_and_edit_announcement
      switch_to_html_view
      switch_to_raw_html_editor
      f("textarea#discussion-topic-message10").send_keys("html text")
      f("#discussion-title").send_keys("New Discussion Title")
      driver.navigate.refresh
      accept_alert
      wait_for_rce
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)
      expect(JSON.parse(saved_content)["content"]).to match("JvwYPc4X9emMRM+w6MEuRvGQiS7d9Vwtuu6HVbEatwZRIIPBEZFQNeZcVQ==")
      driver.local_storage.clear
    end

    it "prompts to restore autosaved content" do
      skip "LF-716 (9/5/2023)"
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)

      driver.navigate.refresh
      accept_alert
      wait_for_rce

      expect(fj('h2:contains("Found auto-saved content")')).to be_present
      fj('button:contains("Yes")').click
      wait_for_animations

      in_frame tiny_rce_ifr_id do
        expect(f("body").text).to eql("hello")
      end
      driver.local_storage.clear
    end

    it "is scoped to the user" do
      skip "LF-716 (9/5/2023)"
      # Start with the first teacher creating an announcement and verify the data autosaved
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)

      # As another teacher, verify the previous teacher's autosave is not presented
      @teacher2 = User.create!
      @course.enroll_teacher(@teacher2)
      user_session(@teacher2)
      create_announcement
      wait_for_rce
      expect(f("body")).not_to contain_css('[data-testid="RCE_RestoreAutoSaveModal"]')

      # As the original teacher, verify the autosave is present and working
      user_session(@teacher)
      create_announcement
      expect(fj('h2:contains("Found auto-saved content")')).to be_present
      fj('button:contains("Yes")').click
      wait_for_animations

      in_frame tiny_rce_ifr_id do
        expect(f("body").text).to eql("hello")
      end
      driver.local_storage.clear
    end

    # localStorage in chrome is limitedto 5120k, and that seems to include the key
    it "handles quota exceeded", :ignore_js_errors do
      # remove ignore_js_errors in LS-1163
      get "/"
      driver.local_storage.clear
      driver.local_storage["xyzzy"] = ("x" * 5_119 * 1_024) + ("x" * 1_000)
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      expect(saved_content).to be_nil # though it didn't throw an exception
      driver.local_storage.clear
    end

    # get '/' is emitting
    # "Warning: [themeable] A theme registry has already been initialized. Ensure that you are importing only one copy of '@instructure/ui-themeable'."
    # It's a warning but logged as an error. I don't believe it is, and I can't find it. Ignore it.
    it "makes room if quota is exceeded due to other rce auto save data", :ignore_js_errors do
      skip "LF-716 (9/5/2023)"
      get "/"
      driver.local_storage.clear
      driver.local_storage[autosave_key(@teacher.id, "http://some/url", "id")] =
        make_autosave_entry(("x" * 4_119 * 1_024) + ("x" * 921))
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      saved_content = JSON.parse(saved_content)
      expect(saved_content["content"]).to eql("JvwYPc4X9emMRM+w6MEuRvGQiS7d9Vwtuu4=")
      driver.local_storage.clear
    end

    it "cleans up expired autosaved entries", :ignore_js_errors do
      get "/"
      driver.local_storage.clear
      Timecop.freeze(2.hours.ago) do
        driver.local_storage[autosave_key(@teacher.id, "http://some/url", "id")] = make_autosave_entry("JvwYPc4X9emMRM+w6MEuRvGQiS7d9Vwtuu4=")
      end

      create_announcement
      saved_content = driver.local_storage[autosave_key(@teacher.id, "http://some/url", "id")]
      expect(saved_content).to be_nil
      driver.local_storage.clear
    end

    it "cleans up this page's expired autosaved entries before prompting to restore" do
      skip("Hopefully addressed in LA-355")
      # I con't know why, but this fails flakey-spec-catcher. And when it doesn't
      # some other spec in here will. I give up. skipping.
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)

      Setting.set("rce_auto_save_max_age_ms", 1)

      driver.navigate.refresh
      accept_alert # onbeforeunload "OK to onload?" alert
      wait_for_rce

      expect(f("body")).not_to contain_css('[data-testid="RCE_RestoreAutoSaveModal"]')
      driver.local_storage.clear
    end

    it "removes placholder images from autosaved content" do
      skip "LF-716 (9/5/2023)"
      create_and_edit_announcement

      # simulate a placeholder image
      switch_to_html_view
      switch_to_raw_html_editor
      f("textarea#discussion-topic-message10").send_keys(
        "<div data-placeholder-for='someimage.jpg' style='width: 200px; height: 50px;'>svg spinner here</div>"
      )
      switch_to_editor_view

      f("#discussion-title").click
      driver.navigate.refresh
      accept_alert
      wait_for_rce

      # say "yes" to restore
      expect(fj('h2:contains("Found auto-saved content")')).to be_present
      fj('button:contains("Yes")').click
      wait_for_animations

      in_frame tiny_rce_ifr_id do
        expect(f("body")).not_to contain_css("img")
        expect(f("body").text).to eql("hello")
      end
      driver.local_storage.clear # blur tinymce to force autosave
    end
  end

  context "WYSIWYG generic as an admin" do
    before do
      Setting.set("rce_auto_save_max_age_ms", 1.hour.to_i * 1_000)
      account_with_admin_logged_in
      stub_rcs_config
    end

    def account_with_admin_logged_in
      @account = Account.default
      account_admin_user
      user_session(@admin)
    end

    it "does not prompt to restore autosaved content if the RCE is hidden", :ignore_js_errors do
      get "/accounts/#{@account.id}/settings#tab-announcements"
      fj('button:contains("New Announcement")').click
      wait_for_rce
      edit_announcement

      get "/accounts/#{@account.id}/settings"
      wait_for_animations
      expect(f("#content")).not_to contain_jqcss('h2:contains("Found auto-saved content")')
      driver.local_storage.clear
    end
  end
end
