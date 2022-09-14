# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../helpers/gradebook_common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "pages/rce_next_page"

describe "Canvadoc" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include WikiAndTinyCommon
  include RCENextPage

  before :once do
    PluginSetting.create! name: "canvadocs",
                          settings: { "api_key" => "blahblahblahblahblah",
                                      "base_url" => "http://example.com",
                                      "annotations_supported" => "1",
                                      "account" => "Account.default" }
  end

  def turn_on_plugin_settings
    get "/plugins/canvadocs"
    # whee different UI for plugins
    if element_exists?("#accounts_select")
      f("#accounts_select option:nth-child(2)").click
      unless f(".save_button").enabled?
        f(".copy_settings_button").click
      end
      if f("#plugin_setting_disabled")[:checked]
        f("#plugin_setting_disabled").click
      end
      wait_for_ajaximations
    end
  end

  context "as an admin" do
    before do
      stub_rcs_config
      site_admin_logged_in
      allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return "id" => 1234
    end

    it "has the annotations checkbox in plugin settings", priority: "1" do
      turn_on_plugin_settings
      expect(fj("#settings_annotations_supported:visible")).to be_displayed
    end

    it "allows annotations settings to be saved", priority: "1" do
      skip "CAS-918 (8/25/2022)"

      turn_on_plugin_settings
      fj("#settings_annotations_supported").click
      f(".save_button").click
      assert_flash_notice_message("Plugin settings successfully updated.")
    end

    it "embed canvadocs in wiki page", priority: "1" do
      course_with_teacher_logged_in account: @account, active_all: true
      @course.wiki_pages.create!(title: "Page1")
      file = @course.attachments.create!(display_name: "some test file", uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/pages/Page1/edit"
      add_file_to_rce_next
      force_click("form.edit-form button.submit")
      wait_for_ajax_requests
      expect(fln("text_file.txt")).to be_displayed
    end
  end
end
