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
require_relative "../helpers/quizzes_common"
require_relative "../../spec_helper"
require_relative "page_objects/quizzes_index_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

describe "quizzes selective_release assign to tray" do
  include_context "in-process server selenium tests"
  include QuizzesIndexPage
  include ItemsAssignToTray
  include QuizzesCommon
  include ContextModulesCommon

  before :once do
    differentiated_modules_on
    Account.site_admin.enable_feature! :newquizzes_on_quiz_page

    course_with_teacher(active_all: true)
    @quiz_assignment = @course.assignments.create
    @quiz_assignment.quiz = @course.quizzes.create(title: "test quiz")
    @classic_quiz = @course.quizzes.last

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

  before do
    user_session(@teacher)
  end

  it "brings up the assign to tray when selecting the assign to option" do
    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

    expect(item_tray_exists?).to be_truthy
    expect(tray_header.text).to eq("test quiz")
    expect(icon_type_exists?("Quiz")).to be true
  end

  it "assigns student and saves assignment" do
    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

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
    expect(@classic_quiz.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "shows existing enrollments when accessing assign to tray" do
    @classic_quiz.assignment_overrides.create!(set_type: "ADHOC")
    @classic_quiz.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "saves and shows override updates when tray reaccessed" do
    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

    expect(item_tray_exists?).to be true

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    click_save_button
    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey

    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

    expect(item_tray_exists?).to be true

    expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
    expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
    expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
  end

  it "assigns student for a NQ quiz and saves" do
    new_quiz_assignment = @course.assignments.new(title: "new quizzes assignment")
    new_quiz_assignment.quiz_lti!
    new_quiz_assignment.save!

    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(new_quiz_assignment.id)
    click_assign_to_link(new_quiz_assignment.id)

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
    @classic_quiz.assignment_overrides.create!(set_type: "ADHOC")
    @classic_quiz.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    visit_quizzes_index_page(@course.id)
    click_manage_quiz_button(@classic_quiz.id)
    click_assign_to_link(@classic_quiz.id)

    select_module_item_assignee(1, @student2.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_cancel_button

    expect(element_exists?(module_item_edit_tray_selector)).to be_falsey
    expect(@classic_quiz.assignment_overrides.first.assignment_override_students.count).to eq(1)
  end
end
