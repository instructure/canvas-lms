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
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"

shared_examples_for "selective_release module tray" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    end
  end

  it "accesses the modules tray" do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Assign To...").click

    expect(settings_tray_exists?).to be true
  end

  it "accesses the modules tray for a module and closes" do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click

    # maybe should use a settings option when available
    module_index_menu_tool_link("Assign To...").click

    click_settings_tray_close_button

    expect(settings_tray_exists?).to be_falsey
  end

  it "accesses the modules tray for a module and cancels" do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click

    # maybe should use a settings option when available
    module_index_menu_tool_link("Assign To...").click

    click_settings_tray_cancel_button

    expect(settings_tray_exists?).to be_falsey
  end

  it "accesses the modules tray and click between settings and assign to" do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click

    # should use a settings option when available
    module_index_menu_tool_link("Assign To...").click

    expect(assign_to_panel).to be_displayed

    click_settings_tab
    expect(settings_panel).to be_displayed

    click_assign_to_tab
    expect(assign_to_tab).to be_displayed
  end

  it "shows 'View Assign To' when a module has an assignment override" do
    @module.assignment_overrides.create!
    get @mod_url

    expect(view_assign.text).to eq "View Assign To"
  end

  it "doesn't show 'View Assign To' when a module has no assignment overrides" do
    get @mod_url

    expect(view_assign.text).to eq ""
  end

  it "accesses the modules tray for a module via the 'View Assign To' button" do
    @module.assignment_overrides.create!
    get @mod_url
    view_assign.click

    expect(settings_tray_exists?).to be true
  end
end

shared_examples_for "selective_release module tray prerequisites" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    end
  end

  it "adds more than one prerequisite to a module" do
    get @mod_url

    manage_module_button(@module3).click
    module_index_menu_tool_link("Assign To...").click
    click_settings_tab

    click_add_prerequisites_button

    select_prerequisites_dropdown_option(0, @module2.name)
    expect(prerequisites_dropdown_value(0)).to eq(@module2.name)

    click_add_prerequisites_button

    select_prerequisites_dropdown_option(1, @module.name)
    expect(prerequisites_dropdown_value(1)).to eq(@module.name)

    click_settings_tray_update_module_button

    expect(prerequisite_message(@module3).text).to eq("Prerequisites: #{@module2.name}, #{@module.name}")
  end
end

shared_examples_for "selective_release module tray assign to" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    end
  end

  it "adds both user and section to assignee list" do
    get @mod_url

    scroll_to_the_top_of_modules_page

    manage_module_button(@module).click
    module_index_menu_tool_link("Assign To...").click
    click_custom_access_radio

    assignee_selection.send_keys("user")
    click_option(assignee_selection, "user1")
    assignee_selection.send_keys("section")
    click_option(assignee_selection, "section1")

    assignee_list = assignee_selection_item.map(&:text)
    expect(assignee_list.sort).to eq(%w[section1 user1])
  end
end
