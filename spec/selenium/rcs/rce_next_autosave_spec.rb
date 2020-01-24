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

require_relative '../helpers/wiki_and_tiny_common'
require_relative '../test_setup/common_helper_methods/custom_selenium_actions'
require_relative 'pages/rce_next_page'

describe "RCE Next autosave feature" do
  include_context "in-process server selenium tests"
  include CustomSeleniumActions
  include RCENextPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      Account.default.enable_feature!(:rce_auto_save)
      stub_rcs_config
    end

    def tiny_rce_ifr_id
      f('.tox-editor-container iframe')['id']
    end

    def wait_for_rce
      wait_for_tiny(f('.tox-edit-area'))
    end

    def make_autosave_entry(content, time = Time.zone.now.to_i * 1000)
      "{\"autosaveTimestamp\": \"#{time}\", \"content\": \"#{content}\"}"
    end

    def autosave_key(url = driver.current_url, textarea_id = "discussion-topic-message8")
      "rceautosave:#{url}:#{textarea_id}"
    end

    def create_announcement
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      wait_for_rce
    end

    def edit_announcement(text = "hello")
      in_frame tiny_rce_ifr_id do
        tinyrce_element = f("body")
        tinyrce_element.click
        tinyrce_element.send_keys("#{text}\n") # newline guarantees a tinymce change event
      end
    end

    def create_and_edit_announcement
      create_announcement
      edit_announcement
    end

    it "should autosave" do
      skip("all but one test fails with Selenium::WebDriver::Error::NoSuchAlertError, see LA-355")
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)
      driver.local_storage.clear
    end

    it "should prompt to restore autosaved conent" do
      skip("all but one test fails with Selenium::WebDriver::Error::NoSuchAlertError, see LA-355")
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
        expect(f("body").text).to eql('hello')
      end
      driver.local_storage.clear
    end

    # localStorage in chrome is limitedto 5120k, and that seems to include the key
    it "should handle quota exceeded" do
      skip("all but one test fails with Selenium::WebDriver::Error::NoSuchAlertError, see LA-355")
      get '/'
      driver.local_storage.clear
      driver.local_storage['xyzzy'] = 'x'*5119*1024 + 'x'*1000
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      expect(saved_content).to be_nil # though it didn't throw an exception
      driver.local_storage.clear
    end

    it "should make room if quota is exceeded due to other rce auto save data" do
      # did not skip this one, because it exercises the most of the tests here
      get '/'
      driver.local_storage.clear
      driver.local_storage[autosave_key('http://some/url', 'id')] = make_autosave_entry('x'*5119*1024 + 'x'*921)
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      saved_content = JSON.parse(saved_content)
      expect(saved_content["content"]).to eql("<p>hello</p>\n<p>&nbsp;</p>")
      driver.local_storage.clear
    end

    it "should clean up expired autosaved entries" do
      skip("all but one test fails with Selenium::WebDriver::Error::NoSuchAlertError, see LA-355")
      Setting.set('rce_auto_save_max_age_ms', 10)
      get '/'
      driver.local_storage[autosave_key('http://some/url', 'id')] = make_autosave_entry("anything")
      # assuming it takes > 10ms to load so ^that entry expires
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key('http://some/url', 'id')]
      expect(saved_content).to be_nil
      driver.local_storage.clear
    end

    it "should clean up expired autosaved entries before prompting to restore" do
      skip("all but one test fails with Selenium::WebDriver::Error::NoSuchAlertError, see LA-355")
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)

      Setting.set('rce_auto_save_max_age_ms', 10)

      driver.navigate.refresh
      accept_alert
      wait_for_rce

      expect(f('body')).not_to contain_css('[data-testid="RCE_RestoreAutoSaveModal"]')
      driver.local_storage.clear
    end
  end
end
