# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
require_relative "../helpers/assignment_overrides"
require_relative "page_objects/assignment_page"

describe "assignment groups" do
  include AssignmentOverridesSeleniumHelper
  include_context "in-process server selenium tests"

  context "as a teacher" do
    let(:due_at) { Time.zone.now }
    let(:unlock_at) { 1.day.ago }
    let(:lock_at) { 4.days.from_now }

    before do
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([])

      course_with_teacher_logged_in
    end

    it "creates an assignment with default dates", priority: "1" do
      visit_new_assignment_page
      fill_assignment_title "vdd assignment"
      fill_assignment_overrides
      click_option("#assignment_submission_type", "No Submission")
      update_assignment!
      wait_for_ajaximations
      a = nil
      keep_trying_until do
        a = Assignment.find_by(title: "vdd assignment")
        expect(a).not_to be_nil
      end
      compare_assignment_times(a)
    end

    it "loads existing due data into the form", priority: "2" do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      expect(first_due_at_element.attribute(:value))
        .to match format_date_for_view(due_at)
      expect(first_unlock_at_element.attribute(:value))
        .to match format_date_for_view(unlock_at)
      expect(first_lock_at_element.attribute(:value))
        .to match format_date_for_view(lock_at)
    end

    it "edits a due date", priority: "2" do
      # skip("flaky spec, LA-749")
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      # set due_at, lock_at, unlock_at
      first_due_at_element.clear
      first_due_at_element.send_keys(format_date_for_view(due_at, :medium))
      update_assignment!

      expect(assignment.reload.due_at.to_date)
        .to eq due_at.to_date
    end

    it "clears a due date", priority: "2" do
      assign = @course.assignments.create!(title: "due tomorrow", due_at: 2.days.from_now)
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      fj(".date_field[data-date-type='due_at']:first").clear
      expect_new_page_load { submit_form("#edit_assignment_form") }

      expect(assign.reload.due_at).to be_nil
    end

    it "allows setting overrides", priority: "1" do
      allow(ConditionalRelease::Service).to receive_messages(enabled_in_context?: true, jwt_for: :jwt)

      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(name: "other section")
      default_section_due = 1.day.from_now
      other_section_due = 2.days.from_now

      assign = create_assignment!
      visit_assignment_edit_page(assign)
      wait_for_ajaximations
      select_first_override_section(default_section.name)
      select_first_override_header("Mastery Paths")
      first_due_at_element.clear
      first_due_at_element
        .send_keys(format_date_for_view(default_section_due, :medium))

      add_override
      wait_for_ajaximations
      select_last_override_section(other_section.name)
      last_due_at_element
        .send_keys(format_date_for_view(other_section_due, :medium))

      # `return_to` is not set, so no redirect happens
      wait_for_new_page_load { submit_form("#edit_assignment_form") }

      overrides = assign.reload.assignment_overrides
      expect(overrides.count).to eq 3
      default_override = overrides.detect { |o| o.set_id == default_section.id }
      expect(default_override.due_at.to_date)
        .to eq default_section_due.to_date
      noop_override = overrides.detect { |o| o.set_type == "Noop" }
      expect(noop_override.title).to eq "Mastery Paths"
      other_override = overrides.detect { |o| o.set_id == other_section.id }
      expect(other_override.due_at.to_date)
        .to eq other_section_due.to_date
    end

    it "does not show inactive students when setting overrides" do
      student_in_course(course: @course, name: "real student")
      enrollment = student_in_course(course: @course, name: "inactive student")
      enrollment.deactivate

      assign = create_assignment!
      visit_assignment_edit_page(assign)

      wait_for_ajaximations

      add_override
      wait_for_ajaximations

      driver.switch_to.default_content
      fj(".ic-tokeninput-input:last").send_keys("student")
      wait_for_ajaximations
      students = ffj(".ic-tokeninput-option:visible")
      expect(students.length).to eq 1
      expect(students.first).to include_text("real")
    end

    it "validates override dates against proper section", priority: "1" do
      date = Time.zone.now
      date2 = 10.days.ago
      due_date = 5.days.from_now
      section1 = @course.course_sections.create!(name: "Section 9", restrict_enrollments_to_section_dates: true, start_at: date)
      section2 = @course.course_sections.create!(name: "Section 31", restrict_enrollments_to_section_dates: true, end_at: date2)

      assign = create_assignment!
      visit_assignment_edit_page(assign)
      wait_for_ajaximations
      select_first_override_section(section2.name)
      add_override
      select_last_override_section(section1.name)
      first_due_at_element.clear
      first_unlock_at_element.clear
      first_lock_at_element.clear
      last_due_at_element
        .send_keys(format_date_for_view(due_date, :medium))
      f("#edit_assignment_form").click
      wait_for_new_page_load { submit_form("#edit_assignment_form") }
      overrides = assign.reload.assignment_overrides
      section_override = overrides.detect { |o| o.set_id == section1.id }
      expect(section_override.due_at.to_date)
        .to eq due_date.to_date
    end

    it "properly validates identical calendar dates when saving and editing", priority: "2" do
      shared_date = "October 12 2014 at 23:59:00"
      other_section = @course.course_sections.create!(name: "Section 31", restrict_enrollments_to_section_dates: true, end_at: shared_date)
      visit_new_assignment_page
      wait_for_ajaximations

      fill_assignment_title "validation assignment"
      add_override
      select_last_override_section(other_section.name)
      last_due_at_element.send_keys(shared_date)
      click_option("#assignment_submission_type", "No Submission")
      update_assignment!
      f(".edit_assignment_link").click
      wait_for_ajaximations

      update_assignment!
    end

    it "shows a vdd tooltip summary on the course assignments page", priority: "2" do
      assignment = create_assignment!
      get "/courses/#{@course.id}/assignments"
      expect(f(".assignment .assignment-date-due")).not_to include_text "Multiple Dates"
      add_due_date_override(assignment)

      get "/courses/#{@course.id}/assignments"
      expect(f(".assignment .assignment-date-due")).to include_text "Multiple Dates"
      driver.action.move_to(f(".assignment .assignment-date-due a")).perform
      wait_for_ajaximations

      tooltip = fj(".vdd_tooltip_content:visible")
      expect(tooltip).to include_text "New Section"
      expect(tooltip).to include_text "Everyone else"
    end

    context "in a paced course" do
      before do
        @course.enable_course_paces = true
        @course.save!
        @context_module = @course.context_modules.create! name: "M"
      end

      context "on show page" do
        it "shows the course pacing notice for a module item assignment" do
          assignment = create_assignment!
          assignment.context_module_tags.create! context_module: @context_module, context: @course, tag_type: "context_module"
          get "/courses/#{@course.id}/assignments/#{assignment.id}"
          expect(AssignmentPage.course_pacing_notice).to be_displayed
          expect(f("#content")).not_to contain_css("table.assignment_dates")
        end

        it "does not show the course pacing notice when feature flag is off" do
          @course.account.disable_feature!(:course_paces)
          assignment = create_assignment!
          assignment.context_module_tags.create! context_module: @context_module, context: @course, tag_type: "context_module"
          get "/courses/#{@course.id}/assignments/#{assignment.id}"
          expect(element_exists?(AssignmentPage.course_pacing_notice_selector)).to be_falsey
          expect(f("#content")).to contain_css("table.assignment_dates")
        end

        it "does not show the course pacing notice for a non-moduled assignment" do
          assignment = create_assignment!
          get "/courses/#{@course.id}/assignments/#{assignment.id}"
          expect(f("#content")).not_to contain_css("[data-testid='CoursePacingNotice']")
          expect(f("#content")).to contain_css("table.assignment_dates")
        end
      end

      context "on edit page" do
        it "shows the course pacing notice for a module item assignment" do
          assignment = create_assignment!
          assignment.context_module_tags.create! context_module: @context_module, context: @course, tag_type: "context_module"
          get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
          expect(AssignmentPage.course_pacing_notice).to be_displayed
          expect(f("#content")).not_to contain_css(".ContainerDueDate")
        end

        it "does not show the course pacing notice for a module item assignment when feature flag is off" do
          @course.account.disable_feature!(:course_paces)
          assignment = create_assignment!
          assignment.context_module_tags.create! context_module: @context_module, context: @course, tag_type: "context_module"
          get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
          expect(element_exists?(AssignmentPage.course_pacing_notice_selector)).to be_falsey
          expect(f("#content")).to contain_css(".ContainerDueDate")
        end

        it "does not show the course pacing notice for a non-moduled assignment" do
          assignment = create_assignment!
          get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
          expect(f("#content")).not_to contain_css("[data-testid='CoursePacingNotice']")
          expect(f("#content")).to contain_css(".ContainerDueDate")
        end
      end

      it "does not show availability or due dates on index page" do
        assignment = create_assignment!
        get "/courses/#{@course.id}/assignments"
        expect(fj(".assignment-list:contains('#{assignment.title}')")).to be_displayed
        expect(f(".assignment-list")).not_to contain_css('[data-view="date-available"]')
        expect(f(".assignment-list")).not_to contain_css('[data-view="date-due"]')
      end
    end
  end

  context "as a student" do
    let(:unlock_at) { 2.days.ago }
    let(:lock_at) { 4.days.from_now }

    before do
      course_with_student_logged_in(active_all: true)
    end

    it "shows the available date range when overrides are set", priority: "2" do
      assign = create_assignment!
      get "/courses/#{@course.id}/assignments/#{assign.id}"
      wait_for_ajaximations
      expect(f(".student-assignment-overview")).to include_text "Available"
    end

    context "in a paces course" do
      before do
        @course.enable_course_paces = true
        @course.save!
        @assignment = create_assignment!
      end

      it "shows due date on the index page" do
        get "/courses/#{@course.id}/assignments"
        expect(fj(".assignment-list:contains('#{@assignment.title}')")).to be_displayed
        expect(f(".assignment-list")).to contain_css('[data-view="date-due"]')
      end
    end
  end
end
