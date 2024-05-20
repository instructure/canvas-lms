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

    expect(view_assign[0].text).to eq "View Assign To"
  end

  it "doesn't show 'View Assign To' when a module has no assignment overrides" do
    get @mod_url

    expect(view_assign[0].text).to eq ""
  end

  it "accesses the modules tray for a module via the 'View Assign To' button" do
    @module.assignment_overrides.create!
    get @mod_url
    scroll_to_the_top_of_modules_page
    view_assign[0].click

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

  it "adds more than one prerequisite to a module", :ignore_js_errors do
    get @mod_url

    scroll_to_module(@module3.name)

    manage_module_button(@module3).click
    module_index_menu_tool_link("Edit").click

    click_add_prerequisites_button

    select_prerequisites_dropdown_option(0, @module2.name)
    expect(prerequisites_dropdown_value(0)).to eq(@module2.name)

    click_add_prerequisites_button

    select_prerequisites_dropdown_option(1, @module.name)
    expect(prerequisites_dropdown_value(1)).to eq(@module.name)

    click_settings_tray_update_module_button
    ignore_relock
    refresh_page
    scroll_to_module(@module3.name)
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

  it "adds to assignee list and updates shows assign to after update" do
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

    click_settings_tray_update_module_button
    expect(element_exists?(module_settings_tray_selector)).to be_falsey
    expect(view_assign[0].text).to eq "View Assign To"
  end
end

shared_examples_for "selective release module tray requirements" do |context|
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

  it "adds two requirements for complete all requirements with sequential order", :ignore_js_errors do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click

    click_add_requirement_button
    click_sequential_order_checkbox
    select_requirement_item_option(0, @assignment2.title)
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@assignment2.title)

    click_add_requirement_button
    select_requirement_item_option(1, @assignment3.title)
    expect(element_value_for_attr(requirement_item[1], "title")).to eq(@assignment3.title)
    click_settings_tray_update_module_button
    wait_for_ajaximations
    expect(settings_tray_exists?).to be_falsey
    refresh_page
    scroll_to_the_top_of_modules_page
    validate_correct_pill_message(@module.id, "Complete All Items")
    expect(require_sequential_progress(@module.id).attribute("textContent")).to eq("true")
  end

  it "adds a requirement and validates complete one requirement pill", :ignore_js_errors do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click

    click_add_requirement_button
    click_complete_one_radio
    select_requirement_item_option(0, @assignment2.title)
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@assignment2.title)

    click_settings_tray_update_module_button
    wait_for_ajaximations
    refresh_page
    scroll_to_the_top_of_modules_page
    validate_correct_pill_message(@module.id, "Complete One Item")
  end

  it "cancels a requirement session", :ignore_js_errors do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click

    click_add_requirement_button
    click_complete_one_radio
    select_requirement_item_option(0, @assignment2.title)
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@assignment2.title)

    click_settings_tray_cancel_button
    wait_for_ajaximations
    scroll_to_the_top_of_modules_page
    expect(element_exists?(pill_message_selector(@module.id))).to be_falsey
  end
end

shared_examples_for "selective_release add module tray" do |context|
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
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "adds module with module tray after +Module is clicked" do
    get @mod_url
    click_new_module_link
    update_module_name("New Module")
    click_add_tray_add_module_button
    new_module = @course.context_modules.last
    expect(new_module.name).to eq("New Module")
    expect(element_exists?(context_module_selector(new_module.id))).to be_truthy
  end

  it "adds module with module tray after module image is clicked" do
    get @mod_url
    click_module_create_button
    update_module_name("New Module")
    click_add_tray_add_module_button
    new_module = @course.context_modules.last
    expect(new_module.name).to eq("New Module")
    expect(element_exists?(context_module_selector(new_module.id))).to be_truthy
  end
end

shared_examples_for "selective_release edit module lock until" do |context|
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
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "clicks on lock until radio on edit module tray to show date and time input fields" do
    get @mod_url

    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click
    click_lock_until_checkbox

    expect(lock_until_date).to be_displayed
    expect(lock_until_time).to be_displayed
  end

  it "updates lock until date and time on edit module tray" do
    get @mod_url
    lock_until_date = format_date_for_view(Time.zone.today + 2.days)
    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click
    click_lock_until_checkbox

    update_lock_until_date(lock_until_date)
    update_lock_until_time("12:00 AM")
    click_settings_tray_update_module_button
    ignore_relock

    expect(unlock_details(@module.id)).to include_text "Will unlock"
  end

  it "setting lock until date and time to previous on edit module tray means no lock" do
    get @mod_url

    lock_until_date = format_date_for_view(Time.zone.today - 2.days)
    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click
    click_lock_until_checkbox

    update_lock_until_date(lock_until_date)
    update_lock_until_time("12:00 AM")
    click_settings_tray_update_module_button
    ignore_relock
    expect(unlock_details(@module.id).text).to eq("")
  end

  it "shows error if lock until date and time are empty on edit module tray" do
    get @mod_url
    lock_until_date_input = ""
    scroll_to_the_top_of_modules_page
    manage_module_button(@module).click
    module_index_menu_tool_link("Edit").click
    click_lock_until_checkbox

    update_lock_until_date(lock_until_date_input)
    update_lock_until_time("")
    click_settings_tray_update_module_button
    expect(lock_until_input.text).to include("Unlock date can’t be blank")
    check_element_has_focus(lock_until_date)
  end
end

shared_examples_for "selective_release add module lock until" do |context|
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
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "clicks on lock until radio on add module tray to show date and time input fields" do
    get @mod_url

    click_new_module_link
    update_module_name("New Module")

    click_lock_until_checkbox

    expect(lock_until_date).to be_displayed
    expect(lock_until_time).to be_displayed
  end

  it "updates lock until date and time on add module tray" do
    get @mod_url

    lock_until_date = format_date_for_view(Time.zone.today + 2.days)
    click_new_module_link
    update_module_name("New Module")
    click_lock_until_checkbox

    update_lock_until_date(lock_until_date)
    update_lock_until_time("12:00 AM")

    click_add_tray_add_module_button
    new_module = @course.context_modules.last
    expect(unlock_details(new_module.id)).to include_text "Will unlock"
  end

  it "setting lock until date and time to previous on add module tray means no lock" do
    get @mod_url

    lock_until_date = format_date_for_view(Time.zone.today - 2.days)
    click_new_module_link
    update_module_name("New Module")
    click_lock_until_checkbox

    update_lock_until_date(lock_until_date)
    update_lock_until_time("12:00 AM")
    click_add_tray_add_module_button
    new_module = @course.context_modules.last
    expect(unlock_details(new_module.id).text).to eq("")
  end
end
