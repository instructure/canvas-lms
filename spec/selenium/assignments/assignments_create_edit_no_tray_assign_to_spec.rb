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
require_relative "../helpers/groups_common"

shared_examples_for "item assign to on page during assignment creation/update" do
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  it "assigns student and saves assignment" do
    AssignmentCreateEditPage.replace_assignment_name("new test assignment")
    AssignmentCreateEditPage.enter_points_possible("100")
    AssignmentCreateEditPage.select_text_entry_submission_type
    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    AssignmentCreateEditPage.save_assignment

    assignment = Assignment.last
    expect(assignment.assignment_overrides.last.assignment_override_students.count).to eq(1)

    due_at_row = AssignmentPage.retrieve_due_date_table_row("1 Student")
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

    click_add_assign_to_card
    select_module_item_assignee(1, @section1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    AssignmentCreateEditPage.save_assignment
    assignment = Assignment.last

    expect(assignment.assignment_overrides.count).to eq(1)
    expect(assignment.assignment_overrides.last.set_type).to eq("CourseSection")

    due_at_row = AssignmentPage.retrieve_due_date_table_row("1 Section")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
    expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
    expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

    due_at_row = AssignmentPage.retrieve_due_date_table_row("Everyone else")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.count("-")).to eq(3)
  end

  it "does not recover a deleted card when adding an assignee" do
    # Bug fix of LX-1619
    click_add_assign_to_card
    click_delete_assign_to_card(0)
    select_module_item_assignee(0, @section1.name)

    expect(selected_assignee_options.count).to be(1)
  end

  it "focuses on trashcan of new card when new card added" do
    click_add_assign_to_card
    check_element_has_focus(assign_to_card_delete_button[1])
  end

  context "differentiaiton tags" do
    before :once do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: true }
        a.save!
      end

      @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
      @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
      @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)
    end

    it "assigns a differentiation tag and saves assignment" do
      AssignmentCreateEditPage.replace_assignment_name("new test assignment")
      AssignmentCreateEditPage.enter_points_possible("100")
      AssignmentCreateEditPage.select_text_entry_submission_type

      click_add_assign_to_card
      select_module_item_assignee(1, @diff_tag1.name)
      update_due_date(1, "12/31/2022")
      update_due_time(1, "5:00 PM")
      update_available_date(1, "12/27/2022")
      update_available_time(1, "8:00 AM")
      update_until_date(1, "1/7/2023")
      update_until_time(1, "9:00 PM")

      AssignmentCreateEditPage.save_assignment

      assignment = Assignment.last
      expect(assignment.assignment_overrides.last.set_type).to eq("Group")

      due_at_row = AssignmentPage.retrieve_due_date_table_row("1 Group")
      expect(due_at_row).not_to be_nil
      expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
      expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
      expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

      due_at_row = AssignmentPage.retrieve_due_date_table_row("Everyone else")
      expect(due_at_row).not_to be_nil
      expect(due_at_row.text.count("-")).to eq(3)
    end

    context "existing differentiation tag overrides" do
      before do
        @assignment = Assignment.create!(context: @course, title: "Test Assignment", only_visible_to_overrides: true)
        @assignment.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag1.id, title: @diff_tag1.name)
        @assignment.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag2.id, title: @diff_tag2.name)
      end

      it "renders all the override assignees" do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)

        # 2 differentiation tags
        expect(selected_assignee_options.count).to eq 2
      end
    end
  end

  context "Module overrides" do
    before do
      @context_module = @course.context_modules.create! name: "Mod"
      new_override = @context_module.assignment_overrides.build
      new_override.course_section = @course.course_sections.first
      new_override.save!
      @assignment = Assignment.create!(context: @course, title: "Assignment")
      @context_module.add_item(type: "assignment", id: @assignment.id)
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)
    end

    it "shows module cards if they are not overridden" do
      expect(AssignmentCreateEditPage.assignment_inherited_from.last.text).to eq("Inherited from #{@context_module.name}")
      expect(element_exists?(assign_to_in_tray_selector("Remove Everyone else"))).to be_falsey

      AssignmentCreateEditPage.save_assignment

      assignment = Assignment.last
      assignment.reload
      expect(assignment.only_visible_to_overrides).to be_falsey
    end

    it "does not show module override if an unassigned override exists" do
      @assignment.assignment_overrides.create!(set: @course, unassign_item: false)
      @assignment.assignment_overrides.create!(set: @course.course_sections.first, unassign_item: true)
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)

      expect(module_item_assign_to_card.last).not_to contain_css(AssignmentCreateEditPage.assignment_inherited_from_selector)
    end

    it "shows everyone card if there are course overrides" do
      @assignment.assignment_overrides.create!(set: @course, due_at: 1.day.from_now)
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)

      expect(AssignmentCreateEditPage.assignment_inherited_from.last.text).to eq("Inherited from #{@context_module.name}")
      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    end

    it "does not show the inherited module override if there is an assignment override" do
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")

      expect(module_item_assign_to_card.last).not_to contain_css(AssignmentCreateEditPage.assignment_inherited_from_selector)
    end
  end
end

describe "override assignees" do
  include_context "in-process server selenium tests"
  include ItemsAssignToTray
  include ContextModulesCommon
  include GroupsCommon

  context "basic assignee overrides" do
    before :once do
      course_with_teacher(active_all: true)
      @assignment = Assignment.create!(context: @course, title: "Test Assignment", only_visible_to_overrides: true)
      @assignment.assignment_overrides.create!(set_type: "ADHOC")
      @students = create_users_in_course @course, 20
      @students.each do |student|
        user = User.find(student)
        @assignment.assignment_overrides.first.assignment_override_students.create!(user:)
      end
    end

    before do
      user_session(@teacher)
      @page_size = 5
      stub_const("Api::MAX_PER_PAGE", @page_size)
    end

    it "renders all the override assignees" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)

      # 20 students
      expect(selected_assignee_options.count).to eq @students.length
    end
  end

  context "group assignments", :ignore_js_errors do
    before :once do
      course_with_teacher(active_all: true)
      group_test_setup(3, 3, 1, true)
      @normal_assignment = Assignment.create!(context: @course, title: "Normal Assignment")
      @group_assignment = Assignment.create!(context: @course, title: "Group Assignment", group_category_id: @group_category[0].id)
      override = @group_assignment.assignment_overrides.build
      override.set = @testgroup[0]
      override.save!
    end

    before do
      user_session(@teacher)
    end

    it "creates group assignment overrides" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @normal_assignment.id)
      AssignmentCreateEditPage.click_group_category_assignment_check
      AssignmentCreateEditPage.select_assignment_group_category(-4)

      click_add_assign_to_card
      select_module_item_assignee(1, @testgroup[0].name)
      update_due_date(1, "12/31/2024")

      AssignmentCreateEditPage.save_assignment
      expect(@normal_assignment.assignment_overrides.active.count).to eq(1)
      expect(@normal_assignment.assignment_overrides.active.last.set_type).to eq("Group")
      expect(@normal_assignment.assignment_overrides.active.last.title).to eq(@testgroup[0].name)
    end

    it "shows error if the group set is changed and overrides exist" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @group_assignment.id)
      expect(@group_assignment.assignment_overrides.active.count).to eq(1)
      expect(@group_assignment.assignment_overrides.active.last.title).to eq(@testgroup[0].name)

      AssignmentCreateEditPage.select_assignment_group_category(-3)
      expect(AssignmentCreateEditPage.group_error).to be_displayed

      click_delete_assign_to_item("Remove #{@testgroup[0].name}", 0)

      AssignmentCreateEditPage.select_assignment_group_category(-3)
      expect(AssignmentCreateEditPage.group_error).not_to be_displayed

      click_add_assign_to_card
      select_module_item_assignee(1, @testgroup[1].name)
      update_due_date(1, "12/31/2024")
      AssignmentCreateEditPage.save_assignment

      expect(@group_assignment.assignment_overrides.active.count).to eq(1)
      expect(@group_assignment.assignment_overrides.active.last.title).to eq(@testgroup[1].name)
    end

    it "shows error if attempt to remove group assignment and groups are assigned" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @group_assignment.id)
      wait_for_ajaximations

      expect(AssignmentCreateEditPage.group_category_checkbox).to be_checked
      AssignmentCreateEditPage.click_group_category_assignment_check
      expect(AssignmentCreateEditPage.group_category_checkbox).to be_checked
      expect(AssignmentCreateEditPage.group_category_error).to be_displayed

      click_delete_assign_to_item("Remove #{@testgroup[0].name}", 0)

      AssignmentCreateEditPage.click_group_category_assignment_check
      expect(AssignmentCreateEditPage.group_category_checkbox).not_to be_checked
      expect(AssignmentCreateEditPage.group_category_error).not_to be_displayed
    end
  end

  context "assignments show page assign to", :ignore_js_errors do
    before :once do
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

      include_examples "item assign to on page during assignment creation/update"
    end

    context "manage assign to from assignment edit page" do
      before do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
      end

      include_examples "item assign to on page during assignment creation/update"

      it "assigns student and cancels assignment edit" do
        AssignmentCreateEditPage.replace_assignment_name("new test assignment")
        AssignmentCreateEditPage.enter_points_possible("100")
        AssignmentCreateEditPage.select_text_entry_submission_type

        click_add_assign_to_card
        select_module_item_assignee(1, @student1.name)

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

        click_add_assign_to_card
        select_module_item_assignee(1, @student1.name)
        update_due_date(1, "12/31/2022")
        update_due_time(1, "5:00 PM")
        update_available_date(1, "12/27/2022")
        update_available_time(1, "8:00 AM")
        update_until_date(1, "1/7/2023")
        update_until_time(1, "9:00 PM")

        AssignmentCreateEditPage.save_assignment

        expect(@nq_assignment.assignment_overrides.last.assignment_override_students.count).to eq(1)
      end
    end

    context "post to sis" do
      before do
        @course.account.set_feature_flag! "post_grades", "on"
        @course.account.set_feature_flag! :new_sis_integrations, "on"
        @course.account.settings[:sis_syncing] = { value: true, locked: false }
        @course.account.settings[:sis_require_assignment_due_date] = { value: true }
        @course.account.save!

        @assignment_ = @course.assignments.create(name: "assignment")
      end

      it "blocks saving empty due dates when enabled", :ignore_js_errors do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment_.id)

        AssignmentCreateEditPage.click_post_to_sis_checkbox

        wait_for_ajaximations

        AssignmentCreateEditPage.save_assignment
        expect(driver.current_url).to include("edit")

        expect_instui_flash_message("Please set a due date or change your selection for the “Sync to SIS” option.")

        check_element_has_focus(assign_to_due_date(0))
        expect(assign_to_date_and_time[0].text).to include("Please add a due date")

        update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
        update_due_time(0, "11:59 PM")

        expect(is_checked(AssignmentCreateEditPage.post_to_sis_checkbox_selector)).to be_truthy
        AssignmentCreateEditPage.save_assignment
        expect(driver.current_url).not_to include("edit")
      end

      it "does not block empty due dates when disabled" do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment_.id)

        AssignmentCreateEditPage.save_assignment
        expect(driver.current_url).not_to include("edit")
        expect(@assignment_.post_to_sis).to be_falsey

        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment_.id)
        expect(is_checked(AssignmentCreateEditPage.post_to_sis_checkbox_selector)).to be_falsey
      end

      it "validates due date when user checks/unchecks the option", :ignore_js_errors do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment_.id)

        expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

        AssignmentCreateEditPage.click_post_to_sis_checkbox

        AssignmentCreateEditPage.save_assignment
        expect(driver.current_url).to include("edit")

        check_element_has_focus(assign_to_due_date(0))
        expect(assign_to_date_and_time[0].text).to include("Please add a due date")

        update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
        update_due_time(0, "11:59 PM")

        AssignmentCreateEditPage.save_assignment
        expect(driver.current_url).not_to include("edit")
      end
    end
  end
end
