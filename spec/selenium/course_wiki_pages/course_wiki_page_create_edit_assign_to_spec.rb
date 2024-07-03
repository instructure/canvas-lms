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
require_relative "page_objects/wiki_page"
require_relative "../conditional_release/page_objects/conditional_release_objects"
require_relative "../../helpers/selective_release_common"

describe "wiki pages edit page assign to" do
  include_context "in-process server selenium tests"

  include ContextModulesCommon
  include ItemsAssignToTray
  include CourseWikiPage
  include SelectiveReleaseCommon

  before :once do
    differentiated_modules_on

    course_with_teacher(active_all: true)
    @page = @course.wiki_pages.create!(title: "new_page")
    @section1 = @course.course_sections.create!(name: "section1")
    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  it "shows Manage Assign To option" do
    visit_wiki_edit_page(@course.id, @page.title)
    wait_for_ajaximations
    expect(assign_to_link).to be_displayed
  end

  it "opens the assign to tray when clicking the Manage Assign To option" do
    visit_wiki_edit_page(@course.id, @page.title)

    assign_to_link.click
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq(@page.title)
    expect(icon_type_exists?("Document")).to be true
  end

  it "shows existing enrollments when accessing the assign to tray" do
    @page.assignment_overrides.create!(set_type: "ADHOC")
    @page.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    visit_wiki_edit_page(@course.id, @page.title)

    assign_to_link.click
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "shows pending changes pill after applying changes" do
    visit_wiki_edit_page(@course.id, @page.title)
    assign_to_link.click

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    click_save_button("Apply")
    expect(pending_changes_pill_exists?).to be_truthy
  end

  it "saves new overrides" do
    expect(@page.assignment_overrides.count).to eq(0)

    visit_wiki_edit_page(@course.id, @page.title)
    assign_to_link.click
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    click_save_button("Apply")
    save_wiki_page

    expect(@page.assignment_overrides.count).to eq(1)
  end

  it "shows 'everyone' card when course overrides exist" do
    @context_module = @course.context_modules.create! name: "Mod"
    module_override = @context_module.assignment_overrides.build
    module_override.course_section = @course.course_sections.first
    module_override.save!
    @context_module.add_item(type: "wiki_page", id: @page.id)

    @page.assignment_overrides.create!(set: @course)
    expect(@page.all_assignment_overrides.count).to eq(2)

    visit_wiki_edit_page(@course.id, @page.title)

    assign_to_link.click
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@course.course_sections.first.name}")[0]).to be_displayed
  end

  it "does not show Manage Assign To for group pages" do
    group = @course.groups.create!(name: "Group 1")
    page = group.wiki_pages.create!(title: "group-page")
    visit_group_wiki_edit_page(group.id, page.title)
    wait_for_ajaximations
    expect(element_exists?(editing_roles_input_selector)).to be_truthy
    expect(element_exists?(assign_to_link_selector)).to be_falsey
  end

  it "updates tray when form information changes" do
    visit_wiki_edit_page(@course.id, @page.title)
    replace_wiki_page_name("new page title")

    assign_to_link.click

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("new page title")
  end

  it "does not show the mastery paths checkbox but adds assignment to mastery paths if selected in the tray" do
    @course.conditional_release = true
    @course.save!
    visit_wiki_edit_page(@course.id, @page.title)
    wait_for_ajaximations
    expect(ConditionalReleaseObjects.conditional_content_exists?).to be false
    assign_to_link.click
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    click_add_assign_to_card
    select_module_item_assignee(1, "Mastery Paths")
    click_save_button("Apply")
    save_wiki_page

    assignment = assignment_model(course: @course, points_possible: 100)
    get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
    ConditionalReleaseObjects.conditional_release_link.click
    ConditionalReleaseObjects.last_add_assignment_button.click
    expect(ConditionalReleaseObjects.assignment_selection_modal).to include_text("new_page")
  end

  it "does not show the button when the user does not have the manage_wiki_update permission even if they can edit" do
    @page.update!(editing_roles: "teachers,students")
    visit_wiki_edit_page(@course.id, @page.title)
    expect(element_exists?(assign_to_link_selector)).to be_truthy

    RoleOverride.create!(context: @course.account, permission: "manage_wiki_update", role: teacher_role, enabled: false)
    visit_wiki_edit_page(@course.id, @page.title)
    expect(element_exists?(assign_to_link_selector)).to be_falsey
  end
end
