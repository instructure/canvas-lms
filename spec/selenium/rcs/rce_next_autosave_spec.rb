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

describe 'RCE Next autosave feature' do
  include_context 'in-process server selenium tests'
  include CustomSeleniumActions
  include RCENextPage

  context 'WYSIWYG generic as a teacher' do
    before(:each) do
      Setting.set('rce_auto_save_max_age_ms', 1.hour.to_i * 1_000)
      course_with_teacher_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      Account.default.enable_feature!(:rce_auto_save)
      stub_rcs_config
    end

    def wait_for_rce
      wait_for_tiny(f('.tox-edit-area'))
    end

    def make_autosave_entry(content, time = Time.zone.now.to_i * 1_000)
      "{\"autosaveTimestamp\": \"#{time}\", \"content\": \"#{content}\"}"
    end

    def autosave_key(url = driver.current_url, textarea_id = 'discussion-topic-message8')
      "rceautosave:#{url}:#{textarea_id}"
    end

    def create_announcement
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      wait_for_rce
    end

    def edit_announcement(text = 'hello')
      insert_tiny_text text
    end

    def create_and_edit_announcement
      create_announcement
      edit_announcement
    end

    it 'should autosave' do
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)
      expect(JSON.parse(saved_content)['content']).to match(%r{<p>hello<\/p>}m)
      driver.local_storage.clear
    end

    it 'should autosave htmlview entered content' do
      create_and_edit_announcement

      switch_to_html_view
      f('textarea#discussion-topic-message8').send_keys('html text')
      driver.navigate.refresh
      accept_alert
      wait_for_rce
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)
      expect(JSON.parse(saved_content)['content']).to match(%r{<p>hello<\/p>.*html text}m)
      driver.local_storage.clear
    end

    it 'should prompt to restore autosaved conent' do
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
        expect(f('body').text).to eql('hello')
      end
      driver.local_storage.clear
    end

    # localStorage in chrome is limitedto 5120k, and that seems to include the key
    it 'should handle quota exceeded', ignore_js_errors: true do
      # remove ignore_js_errors in LS-1163
      get '/'
      driver.local_storage.clear
      driver.local_storage['xyzzy'] = 'x' * 5_119 * 1_024 + 'x' * 1_000
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      expect(saved_content).to be_nil # though it didn't throw an exception
      driver.local_storage.clear
    end

    # get '/' is emitting
    # "Warning: [themeable] A theme registry has already been initialized. Ensure that you are importing only one copy of '@instructure/ui-themeable'."
    # It's a warning but logged as an error. I don't believe it is, and I can't find it. Ignore it.
    it 'should make room if quota is exceeded due to other rce auto save data', ignore_js_errors: true do
      get '/'
      driver.local_storage.clear
      driver.local_storage[autosave_key('http://some/url', 'id')] =
        make_autosave_entry('x' * 5_119 * 1_024 + 'x' * 921)
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      saved_content = JSON.parse(saved_content)
      expect(saved_content['content']).to eql("<p>hello</p>\n<p>&nbsp;</p>")
      driver.local_storage.clear
    end

    it 'should clean up expired autosaved entries', ignore_js_errors: true do
      Setting.set('rce_auto_save_max_age_ms', 1)
      get '/'
      driver.local_storage.clear
      driver.local_storage[autosave_key('http://some/url', 'id')] = make_autosave_entry('anything')
      # assuming it takes > 1ms to load so ^that entry expires
      create_announcement
      saved_content = driver.local_storage[autosave_key('http://some/url', 'id')]
      expect(saved_content).to be_nil
      driver.local_storage.clear
    end

    it "should clean up this page's expired autosaved entries before prompting to restore" do
      skip('Hopefully addressed in LA-355')
      # I con't know why, but this fails flakey-spec-catcher. And when it doesn't
      # some other spec in here will. I give up. skipping.
      create_and_edit_announcement
      saved_content = driver.local_storage[autosave_key]
      assert(saved_content)

      Setting.set('rce_auto_save_max_age_ms', 1)

      driver.navigate.refresh
      accept_alert # onbeforeunload "OK to onload?" alert
      wait_for_rce

      expect(f('body')).not_to contain_css('[data-testid="RCE_RestoreAutoSaveModal"]')
      driver.local_storage.clear
    end

    it 'should remove placholder images from autosaved content' do
      create_and_edit_announcement

      # simulate a placeholder image
      switch_to_html_view
      f('textarea#discussion-topic-message8').send_keys(
        "<img data-placeholder-for='someimage.jpg' style='width: 200px; height: 50px; border: solid 1px #8B969E;'/>"
      )
      switch_to_editor_view

      f('#discussion-title').click
      driver.navigate.refresh
      accept_alert
      wait_for_rce

      # say "yes" to restore
      expect(fj('h2:contains("Found auto-saved content")')).to be_present
      fj('button:contains("Yes")').click
      wait_for_animations

      in_frame tiny_rce_ifr_id do
        expect(f('body')).not_to contain_css('img')
        expect(f('body').text).to eql('hello')
      end
      driver.local_storage.clear # blur tinymce to force autosave
    end
  end
end
