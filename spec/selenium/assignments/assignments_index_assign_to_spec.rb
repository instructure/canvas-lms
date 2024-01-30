# frozen_string_literal: true

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
require_relative "../common"
require_relative "../../spec_helper"
require_relative "page_objects/assignments_index_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

shared_examples_for "selective_release assign to tray" do |context|
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before do
    case context
    when :assignment_index
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/assignments"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "brings up the assign to tray when selecting the assign to option" do
    get @mod_url
    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    expect(item_tray_exists?).to be_truthy
    expect(tray_header.text).to eq("test assignment")
    expect(icon_type_exists?("Assignment")).to be true
    expect(item_type_text.text).to include("25 pts")
  end

  it "assigns student and saves assignment" do
    get @mod_url

    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey
    expect(@assignment1.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "shows existing enrollments when accessing assign to tray" do
    @assignment1.assignment_overrides.create!(set_type: "ADHOC")
    @assignment1.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get @mod_url

    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "saves and shows override updates when tray reaccessed" do
    get @mod_url

    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    expect(item_tray_exists?).to be true

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    click_save_button
    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey

    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    expect(item_tray_exists?).to be true

    expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
    expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
    expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
  end

  it "assigns student for a NQ quiz and saves" do
    new_quiz_assignment = @course.assignments.create!(title: "new quizzes assignment")
    new_quiz_assignment.quiz_lti!
    new_quiz_assignment.save!

    get @mod_url

    click_manage_assignment_button(new_quiz_assignment.id)
    click_assign_to_menu_link(new_quiz_assignment.id)

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)

    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey
    expect(new_quiz_assignment.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end

  it "adds all data and cancels" do
    @assignment1.assignment_overrides.create!(set_type: "ADHOC")
    @assignment1.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get @mod_url

    click_manage_assignment_button(@assignment1.id)
    click_assign_to_menu_link(@assignment1.id)

    select_module_item_assignee(1, @student2.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_cancel_button

    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey
    expect(@assignment1.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end
end

describe "assignments index menu tool placement" do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before :once do
    differentiated_modules_on
    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create(name: "test assignment", points_possible: 25)

    @course.enable_feature! :quizzes_next
    @course.context_external_tools.create!(
      name: "Quizzes.Next",
      consumer_key: "test_key",
      shared_secret: "test_secret",
      tool_id: "Quizzes 2",
      url: "http://example.com/launch"
    )
    @course.root_account.settings[:provision] = { "lti" => "lti url" }
    @course.root_account.save!

    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  context "assign to tray on assignments index" do
    before do
      user_session(@teacher)
    end

    include_examples "selective_release assign to tray", :assignment_index
  end

  context "assign to tray on course homepage with default assignments index" do
    before do
      user_session(@teacher)
      @course.update!(default_view: "assignments")
    end

    include_examples "selective_release assign to tray", :course_homepage
  end
end
