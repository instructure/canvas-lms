# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "page_objects/wiki_index_page"
require_relative "../../helpers/selective_release_common"

describe "wiki pages show page assign to" do
  include_context "in-process server selenium tests"

  include ContextModulesCommon
  include ItemsAssignToTray
  include CourseWikiIndexPage
  include SelectiveReleaseCommon

  before :once do
    differentiated_modules_on

    course_with_teacher(active_all: true)
    @page = @course.wiki_pages.create!(title: "wikiwiki")
    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  it "shows button" do
    visit_course_wiki_index_page(@course.id)
    manage_wiki_page_item_button(@page.title).click
    expect(wiki_page_assign_to_menu).to be_displayed
  end

  it "does not show button for students" do
    user_session(@student)
    visit_course_wiki_index_page(@course.id)
    expect(element_exists?(manage_wiki_page_item_button_selector(@page.title))).to be_falsey
  end

  it "brings up the assign to tray when selecting the assign to option" do
    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("wikiwiki")
    expect(icon_type_exists?("Document")).to be true
  end

  it "assigns student and saves page" do
    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_available_date(1, "12/27/2022", exclude_due_date: true)
    update_available_time(1, "8:00 AM", exclude_due_date: true)
    update_until_date(1, "1/7/2023", exclude_due_date: true)
    update_until_time(1, "9:00 PM", exclude_due_date: true)
    click_save_button

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
    expect(@page.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "shows existing enrollments when accessing assign to tray" do
    @page.assignment_overrides.create!(set_type: "ADHOC")
    @page.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "saves and shows override updates when tray reaccessed" do
    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    update_available_date(0, "12/27/2022", exclude_due_date: true)
    update_available_time(0, "8:00 AM", exclude_due_date: true)
    update_until_date(0, "1/7/2023", exclude_due_date: true)
    update_until_time(0, "9:00 PM", exclude_due_date: true)

    click_save_button
    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(assign_to_available_from_date(0, exclude_due_date: true).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0, exclude_due_date: true).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0, exclude_due_date: true).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0, exclude_due_date: true).attribute("value")).to eq("9:00 PM")
  end

  it "focus close button on open" do
    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    check_element_has_focus close_button
  end

  it "focus button on close" do
    skip("flakey test, runs in local LF-1387")
    visit_course_wiki_index_page(@course.id)

    manage_wiki_page_item_button(@page.title).click
    wiki_page_assign_to_menu.click
    wait_for_ajaximations
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_cancel_button
    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    check_element_has_focus manage_wiki_page_item_button(@page.title)
  end

  it "does not show assign to button for group pages" do
    group = @course.groups.create!(name: "Group 1")
    page = group.wiki_pages.create!(title: "group-page")
    visit_group_wiki_index_page(group.id)
    manage_wiki_page_item_button(page.title).click
    expect(wiki_page_item_settings_menu).to include_text("Edit")
    expect(wiki_page_item_settings_menu).not_to include_text("Assign To")
  end

  it "does not show the button when the user does not have the manage_wiki_update permission" do
    visit_course_wiki_index_page(@course.id)
    manage_wiki_page_item_button(@page.title).click
    expect(fj(wiki_page_assign_to_menu_selector)).to be_truthy
    expect(f("body")).to contain_jqcss(wiki_page_assign_to_menu_selector)

    RoleOverride.create!(context: @course.account, permission: "manage_wiki_update", role: teacher_role, enabled: false)
    visit_course_wiki_index_page(@course.id)
    manage_wiki_page_item_button(@page.title).click
    expect(f("body")).not_to contain_jqcss(wiki_page_assign_to_menu_selector)
  end
end
