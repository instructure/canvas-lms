# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
require_relative "../../helpers/items_assign_to_tray"

shared_examples_for "module item assign to tray" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include ItemsAssignToTray

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

  it "saves and shows date overrides for Everyone" do
    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(item_tray_exists?).to be true

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    click_save_button
    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "saves and shows override updates when tray reaccessed" do
    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(item_tray_exists?).to be true

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    click_save_button
    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(item_tray_exists?).to be true

    expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
    expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
    expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
  end

  it "adds to an assignment override and saves" do
    @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
    @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)
    select_module_item_assignee(1, @student2.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(@module_item1.assignment.assignment_overrides.first.assignment_override_students.count).to eq(2)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "creates a new assignment override and saves" do
    @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
    @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)
    click_add_assign_to_card
    select_module_item_assignee(2, @student2.name)
    update_due_date(2, "12/31/2022")
    update_due_time(2, "5:00 PM")
    update_available_date(2, "12/27/2022")
    update_available_time(2, "8:00 AM")
    update_until_date(2, "1/7/2023")
    update_until_time(2, "9:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(@module_item1.assignment.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "creates an override for a section and saves" do
    section1 = @course.course_sections.create!(name: "section1")
    @course.course_sections.create!

    @course.enroll_user(@student1, "StudentEnrollment", section: section1, enrollment_state: "active")

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)
    click_add_assign_to_card
    select_module_item_assignee(1, section1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(@module_item1.assignment.assignment_overrides.count).to eq(1)
    expect(@module_item1.assignment.assignment_overrides.last.set_type).to eq("CourseSection")
  end

  it "adds all data and cancels" do
    @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
    @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)
    select_module_item_assignee(1, @student2.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_cancel_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(@module_item1.assignment.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end

  it "assigns student for a NQ quiz and saves" do
    new_quiz_assignment = @mod_course.assignments.create!(title: "new quizzes assignment")
    new_quiz_assignment.quiz_lti!
    new_quiz_assignment.save!
    @module.add_item(type: "assignment", id: new_quiz_assignment.id)
    latest_module_item = ContentTag.last

    get @mod_url
    scroll_page_to_bottom
    manage_module_item_button(latest_module_item).click
    click_manage_module_item_assign_to(latest_module_item)
    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)

    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(latest_module_item.assignment.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end

  it "assigns student for a classic quiz and saves" do
    classic_quiz_assignment = @mod_course.quizzes.create!(title: "classic quizzes assignment")
    @module.add_item(type: "assignment", id: classic_quiz_assignment.id)
    latest_module_item = ContentTag.last

    get @mod_url
    scroll_page_to_bottom

    manage_module_item_button(latest_module_item).click
    click_manage_module_item_assign_to(latest_module_item)
    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)

    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy
    expect(latest_module_item.assignment.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end

  it "shows the inherited module info on a card" do
    @adhoc_override1 = @module.assignment_overrides.create!(set_type: "ADHOC")
    @adhoc_override1.assignment_override_students.create!(user: @student1)

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(inherited_from.last.text).to eq("Inherited from #{@module.name}")
  end

  it "does not show the inherited module override if there is an assignment override" do
    @adhoc_override1 = @module.assignment_overrides.create!(set_type: "ADHOC")
    @adhoc_override1.assignment_override_students.create!(user: @student1)

    get @mod_url

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(inherited_from.last.text).to eq("Inherited from #{@module.name}")

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    click_save_button

    expect(wait_for_no_such_element { module_item_edit_tray }).to be_truthy

    manage_module_item_button(@module_item1).click
    click_manage_module_item_assign_to(@module_item1)

    expect(module_item_assign_to_card.last).not_to contain_css(inherited_from_selector)
  end
end
