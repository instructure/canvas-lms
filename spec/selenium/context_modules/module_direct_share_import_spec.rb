# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative "page_objects/modules_index_page"
require_relative "../shared_components/copy_to_tray_page"
require_relative "../shared_components/send_to_dialog_page"

describe "modules" do
  include_context "in-process server selenium tests"
  include ModulesIndexPage
  include CopyToTrayPage
  include SendToDialogPage

  before(:once) do
    course_with_teacher(course_name: "Other Course Eh", name: "Sharee", active_all: true)
    @other_course = @course
    @other_teacher = @teacher
    course_with_teacher(active_all: true)
    @other_course.enroll_teacher(@teacher).accept!
    @assignment1 = @course.assignments.create!(title: "Assignment First", points_possible: 10)
    @module1 = @course.context_modules.create!(name: "Test Module1")
    @item1 = @module1.add_item(id: @assignment1.id, type: "assignment")
  end

  before do
    user_session(@teacher)
  end

  it "shares a module", :ignore_js_errors do
    visit_modules_index_page(@course.id)
    manage_module_button(@module1).click
    module_index_menu_tool_link("Send To...").click
    replace_content(user_search, "Sharee")
    wait_for_sharee_dropdown
    click_option(user_search_selector, "Sharee")
    send_button.click
    wait_for_ajax_requests
    expect(@other_teacher.received_content_shares.last.name).to eq @module1.name
  end

  it "copies a module" do
    visit_modules_index_page(@course.id)
    manage_module_button(@module1).click
    module_index_menu_tool_link("Copy To...").click
    course_search_dropdown.click
    course_search_dropdown.send_keys("course")
    wait_for_search_dropdown
    click_option(course_dropdown_item_selector, @other_course.name)
    course_search_dropdown.send_keys(:tab)
    copy_button.click
    wait_for_ajax_requests
    expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq(["context_modules"])
  end

  it "shares a module item", :ignore_js_errors do
    visit_modules_index_page(@course.id)
    manage_module_item_button(@item1).click
    module_index_menu_tool_link("Send To...").click
    replace_content(user_search, "Sharee")
    wait_for_sharee_dropdown
    click_option(user_search_selector, "Sharee")
    send_button.click
    wait_for_ajax_requests
    expect(@other_teacher.received_content_shares.last.name).to eq @assignment1.name
  end

  it "copies a module item" do
    visit_modules_index_page(@course.id)
    manage_module_item_button(@item1).click
    module_index_menu_tool_link("Copy To...").click
    course_search_dropdown.click
    course_search_dropdown.send_keys("course")
    wait_for_search_dropdown
    click_option(course_dropdown_item_selector, @other_course.name)
    course_search_dropdown.send_keys(:tab)
    copy_button.click
    wait_for_ajax_requests
    expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq(["assignments"])
  end

  it "shares a newly created module item", :ignore_js_errors do
    wiki_page = @course.wiki_pages.create!(title: "New Page Title", body: "Here is the body")
    @module1.add_item({ id: wiki_page.id, type: "wiki_page" })
    visit_modules_index_page(@course.id)

    manage_module_item_button(ContentTag.last).click
    module_index_menu_tool_link("Send To...").click
    replace_content(user_search, "Sharee")
    wait_for_sharee_dropdown
    click_option(user_search_selector, "Sharee")
    send_button.click
    wait_for_ajax_requests
    expect(@other_teacher.received_content_shares.last.name).to eq "New Page Title"
  end

  it "copies a newly created module item" do
    quiz = @course.quizzes.create!(title: "New Quiz")
    @module1.add_item({ id: quiz.id, type: "quiz" })
    visit_modules_index_page(@course.id)

    manage_module_item_button(ContentTag.last).click
    module_index_menu_tool_link("Copy To...").click
    course_search_dropdown.click
    course_search_dropdown.send_keys("course")
    wait_for_search_dropdown
    click_option(course_dropdown_item_selector, @other_course.name)
    course_search_dropdown.send_keys(:tab)
    copy_button.click
    wait_for_ajax_requests
    expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq(["quizzes"])
  end
end
