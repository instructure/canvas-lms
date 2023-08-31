# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"

describe "selective_release module set up" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

  context "using tray to update settings" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
    end

    before do
      user_session(@teacher)
    end

    it "accesses the modules tray for a module and closes" do
      go_to_modules
      manage_module_button(@module).click

      # maybe should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      click_settings_tray_close_button

      expect(settings_tray_exists?).to be_falsey
    end

    it "accesses the modules tray for a module and cancels" do
      go_to_modules
      manage_module_button(@module).click

      # maybe should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      click_settings_tray_cancel_button

      expect(settings_tray_exists?).to be_falsey
    end

    it "accesses the modules tray and click between settings and assign to" do
      go_to_modules
      manage_module_button(@module).click

      # should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      expect(assign_to_panel).to be_displayed

      click_settings_tab
      expect(settings_panel).to be_displayed

      click_assign_to_tab
      expect(assign_to_tab).to be_displayed
    end
  end
end
