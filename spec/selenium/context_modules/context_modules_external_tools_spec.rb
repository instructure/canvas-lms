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

require_relative "../helpers/context_modules_common"
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"

describe "module-level external tool launches" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

  before(:once) do
    Account.site_admin.enable_feature!(:create_external_apps_side_tray_overrides)
  end

  before do
    course_with_teacher_logged_in
    @first_module = ContextModule.create!(context: @course)
    @t3 = @course.context_external_tools.create!(
      context_id: 1,
      context_type: "Course",
      url: "https://example.com/",
      shared_secret: "fake",
      consumer_key: "fake",
      name: "Module Index Menu (Modal)",
      description: "Yet another LTI test tool",
      settings:
      {
        "platform" => "canvas.instructure.com",
        "placements" => [
          { "placement" => "module_group_menu", "message_type" => "LtiResourceLinkRequest" },
          { "placement" => "module_menu_modal", "message_type" => "LtiResourceLinkRequest" },
          { "placement" => "module_menu", "message_type" => "LtiResourceLinkRequest" }
        ],
        "module_group_menu" => {
          "placement" => "module_group_menu",
          "message_type" => "LtiResourceLinkRequest"
        },
        "module_menu_modal" => {
          "placement" => "module_menu_modal",
          "message_type" => "LtiResourceLinkRequest"
        },
        "module_menu" => {
          "placement" => "module_menu",
          "message_type" => "LtiResourceLinkRequest"
        }
      },
      workflow_state: "anonymous"
    )
  end

  context "launching LTI tools via module menu placements" do
    it "displays all external apps in the side tray" do
      get "/courses/#{@course.id}"
      gear = f("#context_module_#{@first_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@first_module.id} .header li a.module_external_apps")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace("External Apps...")
      link.click
      wait_for_ajaximations
      expect(tool_dialog_header).to include_text("External Apps...")
      expect(f('button[data-tool-launch-type="module_menu"]')).not_to be_nil
      expect(f('button[data-tool-launch-type="module_group_menu"]')).not_to be_nil
      expect(f('button[data-tool-launch-type="module_menu_modal"]')).not_to be_nil
    end

    it "navigates to a new page when the first external app is selected" do
      get "/courses/#{@course.id}"
      gear = f("#context_module_#{@first_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@first_module.id} .header li a.module_external_apps")
      link.click
      original_url = driver.current_url
      wait_for_dom_ready
      f('button[data-tool-launch-type="module_menu"]').click
      wait_for_ajaximations
      expect(driver.current_url).not_to eq(original_url)
      expect(driver.current_url).to include("/courses/#{@course.id}/external_tools")
    end

    it "opens a side tray when the second external app is selected" do
      get "/courses/#{@course.id}"
      gear = f("#context_module_#{@first_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@first_module.id} .header li a.module_external_apps")
      link.click
      wait_for_dom_ready
      f('button[data-tool-launch-type="module_group_menu"]').click
      wait_for_ajaximations
      expect(f('div[role="dialog"][aria-label="Module Index Menu (Modal)"]')).to be_displayed
    end

    it "opens a modal when the third external app is selected" do
      get "/courses/#{@course.id}"
      gear = f("#context_module_#{@first_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@first_module.id} .header li a.module_external_apps")
      link.click
      wait_for_dom_ready
      f('button[data-tool-launch-type="module_menu_modal"]').click
      wait_for_ajaximations
      expect(f('span[role="dialog"][aria-label="Module Index Menu (Modal)"]')).to be_displayed
    end
  end
end
