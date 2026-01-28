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

shared_examples_for "module unlock dates" do
  it "displays the will unlock label when unlock date is in the future" do
    @module1.unlock_at = 1.week.from_now
    @module1.save!

    go_to_modules
    wait_for_ajaximations

    will_unlock_at_label = module_header_will_unlock_label(@module1.id)
    expect(will_unlock_at_label).to be_present
    expect(will_unlock_at_label.text).to include("Will unlock")

    module_header_expand_toggles.first.click
    wait_for_ajaximations

    # Still exists after expanding
    expect(will_unlock_at_label).to be_present
    expect(will_unlock_at_label.text).to include("Will unlock")
  end

  it "does not display the will unlock label when unlock date is in the past" do
    @module1.unlock_at = 1.week.ago
    @module1.save!

    go_to_modules
    wait_for_ajaximations
    expect(element_exists?(module_header_will_unlock_selector(@module1.id))).to be_falsey
  end
end

shared_examples_for "module collapse and expand" do |context|
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

  it "start with all modules collapsed" do
    get @mod_url

    expect(module_header_expand_toggles.length).to eq(3)
    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "collapses and expands the module" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
  end

  it "expand and collapse module status retained after refresh" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "expands all modules when clicking the expand all button" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")
  end

  it "collapses all modules when clicking the collapse all button" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    collapse_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "expand all is retained after refresh" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")
  end

  it "collapse all is retained after refresh" do
    get @mod_url

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    collapse_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end
end

shared_examples_for "course_module2 add module tray" do |context|
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray

  new_module_name = "First Week 1"

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "adds module with add module tray after add module button is clicked" do
    get @mod_url
    wait_for_ajaximations
    add_module_button.click
    expect(input_module_name).to be_displayed
    fill_in_module_name(new_module_name)
    submit_add_module_button.click

    created_module = @course.context_modules.last
    expect(created_module.name).to eq(new_module_name)
    expect(@course.context_modules.count).to eq 1
    expect(context_module_name(new_module_name)[0]).to be_displayed
  end

  it "adds module with add module tray after module image is clicked" do
    get @mod_url
    expect(empty_state_module_creation_button).to be_displayed
    empty_state_module_creation_button.click
    fill_in_module_name(new_module_name)
    submit_add_module_button.click

    new_module = @course.context_modules.last
    expect(new_module.name).to eq(new_module_name)
    expect(@course.context_modules.count).to eq 1
    expect(context_module_name(new_module_name)[0]).to be_displayed
  end

  it "adds module with a prerequisite module in same transaction" do
    first_module = @course.context_modules.create!(name: "Week 0: Preparation")
    get @mod_url
    wait_for_ajaximations
    add_module_button.click

    expect(input_module_name).to be_displayed
    fill_in_module_name(new_module_name)
    expect(add_prerequisite_button).to be_displayed
    add_prerequisite_button.click
    wait_for_ajaximations
    expect(prerequisites_dropdown_value(0)).to eq(first_module.name)
    submit_add_module_button.click

    created_module = @course.context_modules.last
    expect(created_module.name).to eq(new_module_name)
    expect(@course.context_modules.count).to eq 2
    expect(context_module_prerequisites(created_module.id).text).to eq("Prerequisite: #{first_module.name}")
    expect(context_module_name(new_module_name)[0]).to be_displayed
  end

  it "adds module with lock until date on add module tray" do
    future_date = format_date_for_view(Time.zone.today + 7.days)
    get @mod_url
    wait_for_ajaximations
    add_module_button.click

    click_lock_until_checkbox
    update_lock_until_date(future_date)
    update_lock_until_time("12:00 AM")
    fill_in_module_name(new_module_name)
    click_save_module_tray_change

    created_module = @course.context_modules.last
    expect(created_module.name).to eq(new_module_name)
    expect(element_exists?(module_header_will_unlock_selector(created_module.id))).to be true
    expect(module_header_will_unlock_label(created_module.id).text).to include "Will unlock"
  end
end

shared_examples_for "course_module2 module tray lock until" do |context|
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "adds lock until date on edit module tray" do
    future_date = format_date_for_view(Time.zone.today + 7.days)
    get @mod_url

    module_action_menu(@module1.id).click
    module_item_action_menu_link("Edit").click
    click_lock_until_checkbox

    update_lock_until_date(future_date)
    update_lock_until_time("12:00 AM")
    click_save_module_tray_change
    ignore_relock

    will_unlock_at_label = module_header_will_unlock_label(@module1.id)
    expect(element_exists?(module_header_will_unlock_selector(@module1.id))).to be true
    expect(will_unlock_at_label.text).to include "Will unlock"
  end

  it "updates lock until date on edit module tray" do
    @module2.unlock_at = 1.week.from_now
    @module2.save!
    get @mod_url

    # the UI always shows "Jan 4 at 7:05am" format (never includes year, even across year boundaries)
    # we use strftime directly because format_time_for_view would add the year when dates cross
    # into a different year (e.g., running this test in Dec 2025 with dates in Jan 2026)
    current_due = @module2.unlock_at.strftime("%b %-d at %l:%M%P").squeeze(" ").strip # rubocop:disable Specs/NoStrftime
    expect(module_header_will_unlock_label(@module2.id).text).to include "Will unlock #{current_due}"

    module_action_menu(@module2.id).click
    module_item_action_menu_link("Edit").click

    update_lock_until_date(format_date_for_view(Time.zone.today + 2.days))
    update_lock_until_time("12:00 AM")
    click_save_module_tray_change
    ignore_relock

    future_datetime = Time.zone.parse((Time.zone.today + 2.days).to_s + " 00:00:00")
    future_due = future_datetime.strftime("%b %-d at %l:%M%P").squeeze(" ").strip # rubocop:disable Specs/NoStrftime
    expect(module_header_will_unlock_label(@module2.id).text).to include "Will unlock #{future_due}"
  end
end

shared_examples_for "course_module2 module tray prerequisites" do |context|
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "adds more than one prerequisite to a module", :ignore_js_errors do
    get @mod_url
    module_action_menu(@module3.id).click
    module_item_action_menu_link("Edit").click

    click_add_prerequisites_button
    select_prerequisites_dropdown_option(0, @module2.name)
    expect(prerequisites_dropdown_value(0)).to eq(@module2.name)

    click_add_prerequisites_button
    select_prerequisites_dropdown_option(1, @module1.name)
    expect(prerequisites_dropdown_value(1)).to eq(@module1.name)

    click_save_module_tray_change
    ignore_relock
    expect(context_module_prerequisites(@module3.id).text).to eq("Prerequisites: #{@module2.name}, #{@module1.name}")
  end
end

shared_examples_for "course_module2 module tray requirements" do |context|
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end

    get @mod_url
  end

  it "adds two requirements for complete all requirements with sequential order", :ignore_js_errors do
    module_action_menu(@module2.id).click
    module_item_action_menu_link("Edit").click
    click_add_requirement_button
    expect(sequential_order_checkbox).to be_displayed

    sequential_order_checkbox.click
    select_requirement_item_option(0, @assignment3.title)
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@assignment3.title)

    click_add_requirement_button
    select_requirement_item_option(1, @quiz.title)
    expect(element_value_for_attr(requirement_item[1], "title")).to eq(@quiz.title)

    click_save_module_tray_change
    ignore_relock
    expect(settings_tray_exists?).to be_falsey
    expect(context_module_completion_requirement(@module2.id).text).to include("Complete All Items")

    module_action_menu(@module2.id).click
    module_item_action_menu_link("Edit").click
    expect(element_exists?(sequential_order_checkbox_selector, true)).to be true
  end

  it "adds a requirement and validates complete one requirement pill", :ignore_js_errors do
    module_action_menu(@module3.id).click
    module_item_action_menu_link("Edit").click
    click_add_requirement_button

    select_complete_one_radio
    select_requirement_item_option(0, @discussion.title)
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@discussion.title)
    click_save_module_tray_change
    ignore_relock
    expect(context_module_completion_requirement(@module3.id).text).to include("Complete One Item")
  end

  it "deletes a requirement that was created", :ignore_js_errors do
    module_action_menu(@module5.id).click
    module_item_action_menu_link("Edit").click
    expect(module_requirement_card.length).to eq(2)
    expect(element_exists?(add_requirement_button_selector)).to be false

    remove_requirement_button(@required_hw.title).click
    expect(element_value_for_attr(requirement_item[0], "title")).to eq(@required_quiz.title)
    expect(module_requirement_card.length).to eq(1)
    expect(element_exists?(add_requirement_button_selector)).to be true
  end
end

shared_examples_for "course_module2 module tray assign to" do |context|
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "adds both user and section to assignee list" do
    get @mod_url
    scroll_to_the_top_of_modules_page
    module_action_menu(@module1.id).click
    module_item_action_menu_link("Assign To...").click
    custom_access_radio_click.click
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
    module_action_menu(@module1.id).click
    module_item_action_menu_link("Assign To...").click
    custom_access_radio_click.click
    assignee_selection.send_keys("user")
    click_option(assignee_selection, "user1")
    assignee_selection.send_keys("section")
    click_option(assignee_selection, "section1")
    assignee_list = assignee_selection_item.map(&:text)
    expect(assignee_list.sort).to eq(%w[section1 user1])
    submit_add_module_button.click
    expect(settings_tray_exists?).to be_falsey
    expect(view_assign_to_links[0].text).to eq "View Assign To"
  end
end
