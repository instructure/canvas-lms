# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../helpers/assignments_common"
require_relative "page_objects/assignments_index_page"

describe "assignment batch edit" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon
  include AssignmentsIndexPage

  context "with assignments in course" do
    before(:once) do
      # reference date
      @date = Time.zone.now.change(usec: 0)
      # Course
      @course1 = Course.create!(name: "First Course1")
      # Teacher
      @teacher1 = User.create!
      @teacher1 = User.create!(name: "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, enrollment_state: "active")
      # Student1 and Student2 and Student3
      @student1 = User.create!(name: "First Student")
      @student1.accept_terms
      @student1.register!
      @course1.enroll_student(@student1, enrollment_state: "active")
      @student2 = User.create!(name: "Second Student")
      @student2.accept_terms
      @student2.register!
      @course1.enroll_student(@student2, enrollment_state: "active")
      @student3 = User.create!(name: "Third Student")
      @student3.accept_terms
      @student3.register!
      @course1.enroll_student(@student3, enrollment_state: "active")
      # Two Assignments, one with overrides and one with no due date
      @assignment1 = @course1.assignments.create!(
        title: "First Overrides Assignment",
        points_possible: 10,
        submission_types: "online_url,online_upload,online_text_entry",
        due_at: @date + 1.day,
        lock_at: @date + 3.days,
        unlock_at: @date - 3.days
      )
      @assignment2 = @course1.assignments.create!(
        title: "Second Assignment",
        points_possible: 10,
        submission_types: "online_text_entry"
      )
      # add some overrides for Assignment1
      @override1 = create_adhoc_override_for_assignment(@assignment1,
                                                        [@student1],
                                                        { title: "override1",
                                                          due_at: @date - 1.day,
                                                          lock_at: @date + 4.days,
                                                          unlock_at: @date - 4.days })
      @override2 = create_adhoc_override_for_assignment(@assignment1,
                                                        [@student2],
                                                        { title: "override2",
                                                          due_at: @date - 10.days,
                                                          lock_at: @date + 10.days,
                                                          unlock_at: @date - 10.days })
      @override2 = create_adhoc_override_for_assignment(@assignment1,
                                                        [@student3],
                                                        { title: "override3",
                                                          due_at: @date + 10.days,
                                                          lock_at: @date + 20.days,
                                                          unlock_at: @date })
    end

    context "bulk edit feature" do
      before do
        user_session(@teacher1)
        visit_assignments_index_page(@course1.id)
        goto_bulk_edit_view
      end

      it "displays all assignments and overrides in batch view", custom_timeout: 60 do
        bulk_edit_text = bulk_edit_root.text
        # includes both assignments
        expect(bulk_edit_text).to include("First Overrides Assignment")
        expect(bulk_edit_text).to include("Second Assignment")
        # should have 5 rows including overrides and assignment titles
        expect(bulk_edit_tr_rows.count).to eq 5
      end

      it "allows editing and saving dates", custom_timeout: 30 do
        skip "DEMO-76 (10/14/2020)"

        date_inputs = assignment_dates_inputs(@assignment2.title)
        # add a due date to Second Assignment
        replace_content(date_inputs[0], format_date_for_view(@date, :medium))
        # add unlock_at date
        replace_content(date_inputs[1], format_date_for_view(@date - 5.days, :medium))
        # add lock_at date
        replace_content(date_inputs[2], format_date_for_view(@date + 5.days, :medium))
        # save
        save_bulk_edited_dates
        # the assignment should now have due and available dates
        keep_trying_until do
          expect(@assignment2.reload.due_at).not_to be_nil
          expect(@assignment2.lock_at).not_to be_nil
          expect(@assignment2.unlock_at).not_to be_nil
        end
      end

      it "allows selecting and shifting dates", custom_timeout: 30 do
        skip "DEMO-76 (10/14/2020)"

        select_assignment_checkbox(@assignment1.title).send_keys(:space)
        open_batch_edit_dialog
        # shift by 2 days
        batch_edit_dialog_days_up_button.click
        batch_edit_dialog_ok_button.click
        date_inputs = assignment_dates_inputs(@assignment1.title)
        save_bulk_edited_dates
        expect(date_inputs[0].attribute("value")).to eq (@date + 3.days).strftime("%a %-b %-d, %Y")
        # unlock_at was today-3.days
        expect(date_inputs[1].attribute("value")).to eq (@date - 1.day).strftime("%a %-b %-d, %Y")
        # lock_at date was today+3days
        expect(date_inputs[2].attribute("value")).to eq (@date + 5.days).strftime("%a %-b %-d, %Y")
        date_inputs = assignment_dates_inputs(@override1.title)
        # Override1 due date was today-1.day
        expect(date_inputs[0].attribute("value")).to eq (@date + 1.day).strftime("%a %-b %-d, %Y")
        # Override1 unlock_at date was today-4.days
        expect(date_inputs[1].attribute("value")).to eq (@date - 2.days).strftime("%a %-b %-d, %Y")
        # Override1 lock_at date was today+4days
        expect(date_inputs[2].attribute("value")).to eq (@date + 6.days).strftime("%a %-b %-d, %Y")
      end

      it "allows clearing dates", custom_timeout: 30 do
        skip "DEMO-76 (10/14/2020)"

        select_assignment_checkbox(@assignment1.title).send_keys(:space)
        open_batch_edit_dialog
        dialog_remove_date_radio_btn.send_keys(:space)
        batch_edit_dialog_ok_button.click
        date_inputs = assignment_dates_inputs(@assignment1.title)
        save_bulk_edited_dates
        # due date is cleared
        expect(date_inputs[0].attribute("value")).to eq ""
      end
    end
  end

  context "in a paced course" do
    before do
      course_with_teacher_logged_in
      @course.enable_course_paces = true
      @course.save!

      @course.assignments.create!(
        title: "Overrides Assignment",
        points_possible: 10,
        submission_types: "online_url,online_upload,online_text_entry"
      )
    end

    it "does not include Edit Assignment Dates in the page menu" do
      visit_assignments_index_page(@course.id)
      course_assignments_settings_button.click
      expect(f("body")).not_to contain_jqcss(bulk_edit_dates_menu_jqselector)
      expect(assignment_groups_weight).to be_displayed
    end

    it "does include Edit Assignment Dates in page menu when feature off" do
      @course.account.disable_feature!(:course_paces)
      visit_assignments_index_page(@course.id)
      course_assignments_settings_button.click
      expect(f("body")).to contain_jqcss(bulk_edit_dates_menu_jqselector)
      expect(assignment_groups_weight).to be_displayed
    end
  end
end
