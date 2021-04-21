# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/assignment_overrides.rb'

describe "assignment groups" do
  include AssignmentOverridesSeleniumHelper
  include_context "in-process server selenium tests"

  context "as a teacher" do

    let(:due_at) { Time.zone.now }
    let(:unlock_at) { Time.zone.now - 1.day }
    let(:lock_at) { Time.zone.now + 4.days }

    before(:each) do
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([])

      course_with_teacher_logged_in
      stub_rcs_config
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

    it "should allow setting overrides", priority: "1", test_id: 216349 do
      skip "regularly fails on line 99 below but looks fine in web page"
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
      submit_form('#edit_assignment_form')
      wait_for_ajax_requests

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
  end
end
