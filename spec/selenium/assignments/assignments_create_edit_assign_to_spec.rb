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
require_relative "page_objects/assignments_index_page"
require_relative "page_objects/assignment_create_edit_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

describe "due date validations", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before(:once) do
    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create(name: "test assignment", submission_types: "online_url")
    @section1 = @course.course_sections.create!(name: "section1")
    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  context "general due date validations" do
    it "can fill out due dates and times on card" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "12/27/2022")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/7/2023")
      update_until_time(0, "9:00 PM")

      expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
      expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
      expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
      expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
      expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
      expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
    end

    it "does not display an error when user uses other English locale" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
      @user.update! locale: "en-GB"

      update_due_date(0, "15 April 2024")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).not_to include("Invalid date")
    end

    it "does not display an error when user uses other language" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
      @user.update! locale: "es"

      update_due_date(0, "15 de abr. de 2024")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).not_to include("Fecha no válida")
    end

    it "displays an error when due date is invalid" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
      update_due_date(0, "wrongdate")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).to include("Invalid date")
    end

    it "displays an error when the availability date is after the due date" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
      update_due_date(0, "12/31/2022")
      update_available_date(0, "1/1/2023")

      expect(assign_to_date_and_time[1].text).to include("Available from date cannot be after due date")
    end
  end

  context "due date validations with term, course, section dates" do
    it "displays due date errors before term start date" do
      start_at = 2.months.from_now.to_date
      @term = Account.default.enrollment_terms.create(name: "Fall", start_at:)
      @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      long_due_date = 1.month.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))
      AssignmentCreateEditPage.save_assignment
      expect(assign_to_date_and_time[0].text).to include("Due date cannot be before term start")
    end

    it "displays due date errors past term end date" do
      end_at = 1.month.from_now.to_date
      @term = Account.default.enrollment_terms.create(name: "Fall", end_at:)
      @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      long_due_date = 2.months.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).to include("Due date cannot be after term end")
    end

    it "displays availability errors before term start date" do
      start_at = 2.months.from_now.to_date
      @term = Account.default.enrollment_terms.create(name: "Fall", start_at:)
      @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      available_date = 1.month.from_now.to_date
      update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[1].text).to include("Available from date cannot be before term start")
    end

    it "displays lock date errors past term end date" do
      end_at = 1.month.from_now.to_date
      @term = Account.default.enrollment_terms.create(name: "Fall", end_at:)
      @course.update!(enrollment_term: @term, restrict_enrollments_to_course_dates: false)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      available_date = 2.months.from_now.to_date

      update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[2].text).to include("Until date cannot be after term end")
    end

    it "displays due date errors before course start date" do
      @course.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      long_due_date = 1.month.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).to include("Due date cannot be before course start")
    end

    it "displays due date errors past course end date" do
      @course.update!(conclude_at: 1.month.from_now.to_date, restrict_enrollments_to_course_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      long_due_date = 2.months.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).to include("Due date cannot be after course end")
    end

    it "displays available from date errors before course start date" do
      @course.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      available_date = 1.month.from_now.to_date
      update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[1].text).to include("Available from date cannot be before course start")
    end

    it "displays lock date errors past course end date" do
      @course.update!(conclude_at: 1.month.from_now.to_date, restrict_enrollments_to_course_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      available_date = 2.months.from_now.to_date

      update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[2].text).to include("Until date cannot be after course end")
    end

    it "displays due date errors before section start date" do
      @section1.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      select_module_item_assignee(0, @section1.name)

      long_due_date = 1.month.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).to include("Due date cannot be before section start")
    end

    it "displays due date errors past section end date" do
      @section1.update!(end_at: 1.month.from_now.to_date, restrict_enrollments_to_section_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      select_module_item_assignee(0, @section1.name)

      long_due_date = 2.months.from_now.to_date

      update_due_date(0, format_date_for_view(long_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).to include("Due date cannot be after section end")
    end

    it "displays available from errors before section start date" do
      @section1.update!(start_at: 2.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      select_module_item_assignee(0, @section1.name)

      available_date = 1.month.from_now.to_date
      update_available_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[1].text).to include("Available from date cannot be before section start")
    end

    it "displays lock date errors past section end date" do
      @section1.update!(end_at: 1.month.from_now.to_date, restrict_enrollments_to_section_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      select_module_item_assignee(0, @section1.name)

      available_date = 2.months.from_now.to_date

      update_until_date(0, format_date_for_view(available_date, "%-m/%-d/%Y"))
      expect(assign_to_date_and_time[2].text).to include("Until date cannot be after section end")
    end

    it "allows section due date that is outside of course date range" do
      @course.update!(start_at: 1.month.from_now.to_date, conclude_at: 2.months.from_now.to_date, restrict_enrollments_to_course_dates: true)
      @section1.update!(start_at: 2.months.from_now.to_date, end_at: 4.months.from_now.to_date, restrict_enrollments_to_section_dates: true)

      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)

      select_module_item_assignee(0, @section1.name)

      section_due_date = 3.months.from_now.to_date
      update_due_date(0, format_date_for_view(section_due_date, "%-m/%-d/%Y"))

      expect(assign_to_date_and_time[0].text).not_to include("Due date cannot be before course start")
    end

    it "allows ad-hoc dates that are outside of course date range" do
      @course.update!(start_at: 2.months.ago.to_date, conclude_at: 1.month.ago.to_date, restrict_enrollments_to_course_dates: true)
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course.id)
      wait_for(method: nil, timeout: 5) { f("#assignment_name").displayed? }

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
    end
  end

  context "differentiation tags" do
    before do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: true }
        a.save!
      end
      @group_category = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
      @group_category.create_groups(1)
      @differentiation_tag_group_1 = @group_category.groups.first_or_create
      @differentiation_tag_group_1.add_user(@student1)
      @assignment1.assignment_overrides.create!(set: @differentiation_tag_group_1)
      @assignment1.update!(only_visible_to_overrides: true)
    end

    it "shows convert override message when diff tags setting disabled" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
      expect(element_exists?(convert_override_alert_selector)).to be_truthy
      AssignmentCreateEditPage.assignment_save_button.click
      expect(f("body").text).to include "Invalid group selected"
    end

    it "clicking convert overrides button converts the override and refreshes the cards" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
      expect(f(assignee_selected_option_selector).text).to include(@differentiation_tag_group_1.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      expect(f(assignee_selected_option_selector).text).to include(@student1.name)
    end

    it "clicking convert overrides button converts multiple tag overrides and refreshes the cards" do
      gc = @course.group_categories.create!(name: "Diff Tag Group Set 2", non_collaborative: true)
      gc.create_groups(1)
      differentiation_tag_group_2 = gc.groups.first_or_create
      differentiation_tag_group_2.add_user(@student2)
      @assignment1.assignment_overrides.create!(set: differentiation_tag_group_2)
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment1.id)
      overrides = ff(assignee_selected_option_selector)
      expect(overrides[0].text).to include(@differentiation_tag_group_1.name)
      expect(overrides[1].text).to include(differentiation_tag_group_2.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      converted_overrides = ff(assignee_selected_option_selector)
      expect(converted_overrides[0].text).to include(@student2.name)
      expect(converted_overrides[1].text).to include(@student1.name)
    end
  end
end
