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

describe "wiki pages edit page assign to" do
  include_context "in-process server selenium tests"

  include ContextModulesCommon
  include ItemsAssignToTray
  include CourseWikiPage

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
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    click_save_button("Apply")
    save_wiki_page

    expect(@page.assignment_overrides.count).to eq(1)
  end
end
