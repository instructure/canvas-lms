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

require_relative '../common'
require_relative '../helpers/assignment_overrides.rb'

describe "assignment groups" do
  include AssignmentOverridesSeleniumHelper
  include_context "in-process server selenium tests"

  context "as a teacher" do

    let(:due_at) { Time.zone.now }
    let(:unlock_at) { Time.zone.now - 1.day }
    let(:lock_at) { Time.zone.now + 4.days }

    before(:each) do
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([])
      make_full_screen
      course_with_teacher_logged_in
    end

    it "should create an assignment with default dates", priority:"1", test_id: 216344 do
      visit_new_assignment_page
      fill_assignment_title 'vdd assignment'
      fill_assignment_overrides
      click_option('#assignment_submission_type', 'No Submission')
      update_assignment!
      wait_for_ajaximations
      a = Assignment.where(title: 'vdd assignment').first
      compare_assignment_times(a)
    end

    it "should load existing due data into the form", priority: "2", test_id: 216345 do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      expect(first_due_at_element.attribute(:value)).
        to match format_date_for_view(due_at)
      expect(first_unlock_at_element.attribute(:value)).
        to match format_date_for_view(unlock_at)
      expect(first_lock_at_element.attribute(:value)).
        to match format_date_for_view(lock_at)
    end

    it "should edit a due date", priority: "2", test_id: 216346 do
      assignment = create_assignment!
      visit_assignment_edit_page(assignment)

      # set due_at, lock_at, unlock_at
      first_due_at_element.clear
      first_due_at_element.send_keys(format_date_for_view(due_at, :medium))
      update_assignment!

      expect(assignment.reload.due_at.to_date).
        to eq due_at.to_date
    end

    it "should clear a due date", priority: "2", test_id: 216348 do
      assign = @course.assignments.create!(:title => "due tomorrow", :due_at => Time.zone.now + 2.days)
      get "/courses/#{@course.id}/assignments/#{assign.id}/edit"

      fj(".date_field:first[data-date-type='due_at']").clear
      expect_new_page_load { submit_form('#edit_assignment_form') }

      expect(assign.reload.due_at).to be_nil
    end

    it "should allow setting overrides", priority: "1", test_id: 216349 do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
      allow(ConditionalRelease::Service).to receive(:jwt_for).and_return(:jwt)

      default_section = @course.course_sections.first
      other_section = @course.course_sections.create!(:name => "other section")
      default_section_due = Time.zone.now + 1.days
      other_section_due = Time.zone.now + 2.days

      assign = create_assignment!
      visit_assignment_edit_page(assign)

      wait_for_ajaximations
      select_first_override_section(default_section.name)
      select_first_override_header("Mastery Paths")

      first_due_at_element.clear
      first_due_at_element.
        send_keys(format_date_for_view(default_section_due, :medium))

      add_override
      wait_for_ajaximations
      select_last_override_section(other_section.name)

      last_due_at_element.
        send_keys(format_date_for_view(other_section_due, :medium))

      # `return_to` is not set, so no redirect happens
      wait_for_new_page_load{ submit_form('#edit_assignment_form') }

      overrides = assign.reload.assignment_overrides
      expect(overrides.count).to eq 3
      default_override = overrides.detect{ |o| o.set_id == default_section.id }
      expect(default_override.due_at.to_date).
        to eq default_section_due.to_date
      noop_override = overrides.detect{ |o| o.set_type == "Noop" }
      expect(noop_override.title).to eq "Mastery Paths"
      other_override = overrides.detect{ |o| o.set_id == other_section.id }
      expect(other_override.due_at.to_date).
        to eq other_section_due.to_date
    end

    it "should not show inactive students when setting overrides" do
      student_in_course(:course => @course, :name => "real student")
      enrollment = student_in_course(:course => @course, :name => "inactive student")
      enrollment.deactivate

      assign = create_assignment!
      visit_assignment_edit_page(assign)

      wait_for_ajaximations

      add_override
      wait_for_ajaximations

      driver.switch_to.default_content
      fj('.ic-tokeninput-input:last').send_keys('student')
      wait_for_ajaximations
      students = ffj(".ic-tokeninput-option:visible")
      expect(students.length).to eq 1
      expect(students.first).to include_text("real")
    end

    it "should validate override dates against proper section", priority: "1", test_id: 216350 do
      date = Time.zone.now
      date2 = Time.zone.now - 10.days
      due_date = Time.zone.now + 5.days
      section1 = @course.course_sections.create!(:name => "Section 9", :restrict_enrollments_to_section_dates => true, :start_at => date)
      section2 = @course.course_sections.create!(:name => "Section 31", :restrict_enrollments_to_section_dates => true, :end_at => date2)

      assign = create_assignment!
      visit_assignment_edit_page(assign)
      wait_for_ajaximations
      select_first_override_section(section2.name)
      add_override
      select_last_override_section(section1.name)
      first_due_at_element.clear
      first_unlock_at_element.clear
      first_lock_at_element.clear
      last_due_at_element.
        send_keys(format_date_for_view(due_date, :medium))
      wait_for_new_page_load{ submit_form('#edit_assignment_form') }
      overrides = assign.reload.assignment_overrides
      section_override = overrides.detect{ |o| o.set_id == section1.id }
      expect(section_override.due_at.to_date)
        .to eq due_date.to_date
    end

    it "properly validates identical calendar dates when saving and editing", priority: "2", test_id: 216351 do
      shared_date = "October 12 2014 at 23:59:00"
      other_section = @course.course_sections.create!(:name => "Section 31", :restrict_enrollments_to_section_dates => true, :end_at => shared_date)
      visit_new_assignment_page
      wait_for_ajaximations

      fill_assignment_title 'validation assignment'
      add_override
      select_last_override_section(other_section.name)
      last_due_at_element.send_keys(shared_date)
      click_option('#assignment_submission_type', 'No Submission')
      update_assignment!
      f(".edit_assignment_link").click
      wait_for_ajaximations

      update_assignment!
    end

    it "should show a vdd tooltip summary on the course assignments page", priority: "2", test_id: 216352 do
      assignment = create_assignment!
      get "/courses/#{@course.id}/assignments"
      expect(f('.assignment .assignment-date-due')).not_to include_text "Multiple Dates"
      add_due_date_override(assignment)

      get "/courses/#{@course.id}/assignments"
      expect(f('.assignment .assignment-date-due')).to include_text "Multiple Dates"
      driver.mouse.move_to f(".assignment .assignment-date-due a")
      wait_for_ajaximations

      tooltip = fj('.vdd_tooltip_content:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end
  end

  context "as a student" do

    let(:unlock_at) { Time.zone.now - 2.days }
    let(:lock_at) { Time.zone.now + 4.days }

    before(:each) do
      make_full_screen
      course_with_student_logged_in(:active_all => true)
    end

    it "should show the available date range when overrides are set", priority: "2", test_id: 216353 do
      assign = create_assignment!
      get "/courses/#{@course.id}/assignments/#{assign.id}"
      wait_for_ajaximations
      expect(f('.student-assignment-overview')).to include_text 'Available'
    end
  end
end
