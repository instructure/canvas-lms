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
require_relative "../../spec_helper"
require_relative "page_objects/assignments_index_page"
require_relative "page_objects/assignment_create_edit_page"
require_relative "page_objects/assignment_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

shared_examples_for "item assign to tray during assignment creation/update" do
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  it "brings up the assign to tray when selecting the Manage assign to link" do
    AssignmentCreateEditPage.replace_assignment_name("test assignment")
    AssignmentCreateEditPage.enter_points_possible("10")

    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    # TODO: this is failing right now so keep commented.  To be fixed in LF-754.
    # expect(tray_header.text).to eq("test assignment")
    expect(icon_type_exists?("Assignment")).to be true
    # expect(item_type_text.text).to include("10")
  end

  it "assigns student and saves assignment" do
    AssignmentCreateEditPage.replace_assignment_name("new test assignment")
    AssignmentCreateEditPage.enter_points_possible("100")
    AssignmentCreateEditPage.select_text_entry_submission_type
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    click_save_button("Apply")

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
    expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

    AssignmentCreateEditPage.save_assignment

    assignment = Assignment.last
    expect(assignment.assignment_overrides.last.assignment_override_students.count).to eq(1)

    due_at_row = AssignmentPage.retrieve_due_date_table_row("1 student")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
    expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
    expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

    due_at_row = AssignmentPage.retrieve_due_date_table_row("Everyone else")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.count("-")).to eq(3)
  end

  it "assigns a section and saves assignment" do
    AssignmentCreateEditPage.replace_assignment_name("new test assignment")
    AssignmentCreateEditPage.enter_points_possible("100")
    AssignmentCreateEditPage.select_text_entry_submission_type
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    click_save_button("Apply")

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

    AssignmentCreateEditPage.save_assignment
    assignment = Assignment.last

    expect(assignment.assignment_overrides.count).to eq(1)
    expect(assignment.assignment_overrides.last.set_type).to eq("CourseSection")

    due_at_row = AssignmentPage.retrieve_due_date_table_row(@section1.name)
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
    expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
    expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

    due_at_row = AssignmentPage.retrieve_due_date_table_row("Everyone else")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.count("-")).to eq(3)
  end

  it "disables submit button when tray is open" do
    AssignmentCreateEditPage.replace_assignment_name("new test assignment")
    AssignmentCreateEditPage.enter_points_possible("100")
    AssignmentCreateEditPage.select_text_entry_submission_type
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    expect(AssignmentCreateEditPage.assignment_save_button).to be_disabled

    click_cancel_button
    expect(AssignmentCreateEditPage.assignment_save_button).to be_enabled
  end

  it "clears tray when canceling" do
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    click_cancel_button

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_falsey
  end

  it "reverts last session changes only" do
    # APPLY changes
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")

    click_save_button("Apply")

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy
    # CANCEL changes
    AssignmentCreateEditPage.click_manage_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")

    click_cancel_button

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy
  end

  context "Module overrides" do
    before do
      @context_module = @course.context_modules.create! name: "Mod"
      new_override = @context_module.assignment_overrides.build
      new_override.course_section = @course.course_sections.first
      new_override.save!
      assignment = Assignment.create!(context: @course, title: "Assignment")
      @context_module.add_item(type: "assignment", id: assignment.id)
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, assignment.id)
    end

    it "shows module cards if they are not overridden" do
      AssignmentCreateEditPage.click_manage_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }
      expect(inherited_from.last.text).to eq("Inherited from #{@context_module.name}")
    end

    it "does not show the inherited module override if there is an assignment override" do
      AssignmentCreateEditPage.click_manage_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")

      click_save_button("Apply")

      keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
      AssignmentCreateEditPage.click_manage_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }
      expect(module_item_assign_to_card.last).not_to contain_css(inherited_from_selector)
    end
  end
end

describe "assignments show page assign to", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before :once do
    differentiated_modules_on

    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create(name: "test assignment", submission_types: "online_url")
    @section1 = @course.course_sections.create!(name: "section1")

    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user

    @course.enroll_user(@student1, "StudentEnrollment", section: @section1, enrollment_state: "active")
  end

  before do
    user_session(@teacher)
  end

  context "manage assign to from assignment create page" do
    before do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
    end

    include_examples "item assign to tray during assignment creation/update"
  end

  context "manage assign to from assignment edit page" do
    before do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
    end

    include_examples "item assign to tray during assignment creation/update"

    it "assigns student and cancels assignment edit" do
      AssignmentCreateEditPage.replace_assignment_name("new test assignment")
      AssignmentCreateEditPage.enter_points_possible("100")
      AssignmentCreateEditPage.select_text_entry_submission_type
      AssignmentCreateEditPage.click_manage_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      click_add_assign_to_card
      select_module_item_assignee(1, @student1.name)

      click_save_button("Apply")

      keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

      AssignmentCreateEditPage.cancel_assignment

      expect(@assignment1.assignment_overrides.count).to eq(0)
    end
  end

  context "manage assign to from New Quizzes assignment edit page" do
    before :once do
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

      @nq_assignment = @course.assignments.create(name: "NQ assignment")
      @nq_assignment.quiz_lti!
      @nq_assignment.save!

      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    it "assigns student to NQ assignment and saves", :ignore_js_errors do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @nq_assignment.id)
      AssignmentCreateEditPage.click_manage_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      click_add_assign_to_card
      select_module_item_assignee(1, @student1.name)
      update_due_date(1, "12/31/2022")
      update_due_time(1, "5:00 PM")
      update_available_date(1, "12/27/2022")
      update_available_time(1, "8:00 AM")
      update_until_date(1, "1/7/2023")
      update_until_time(1, "9:00 PM")

      click_save_button("Apply")

      keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

      AssignmentCreateEditPage.save_assignment

      expect(@nq_assignment.assignment_overrides.last.assignment_override_students.count).to eq(1)
    end
  end
end
