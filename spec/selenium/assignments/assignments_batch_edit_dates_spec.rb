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

require_relative '../common'
require_relative '../helpers/assignments_common'
require_relative 'page_objects/assignments_index_page.rb'

describe "assignment batch edit" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon
  include AssignmentsIndexPage

  context "with assignments in course" do
    before(:each) do
      # Course
      @course1 = Course.create!(:name => "First Course1")
      # Teacher
      @teacher1 = User.create!
      @teacher1 = User.create!(:name => "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, :enrollment_state => 'active')
      # Student1 and Student2 and Student3
      @student1 = User.create!(:name => "First Student")
      @student1.accept_terms
      @student1.register!
      @course1.enroll_student(@student1, :enrollment_state => 'active')
      @student2 = User.create!(:name => "Second Student")
      @student2.accept_terms
      @student2.register!
      @course1.enroll_student(@student2, :enrollment_state => 'active')
      @student3 = User.create!(:name => "Third Student")
      @student3.accept_terms
      @student3.register!
      @course1.enroll_student(@student3, :enrollment_state => 'active')
      # Two Assignments, one with overrides and one with no due date
      @assignment1 = @course1.assignments.create!(
        :title => 'First Overrides Assignment',
        :points_possible => 10,
        :submission_types => "online_url,online_upload,online_text_entry",
        :due_at => Time.zone.now + 1.day,
        :lock_at => Time.zone.now + 3.days,
        :unlock_at => Time.zone.now - 3.days
      )
      @assignment2 = @course1.assignments.create!(
        :title => 'Second Assignment',
        :points_possible => 10,
        :submission_types => "online_text_entry"
      )
      # add some overrides for Assignment1
      @override1 = create_adhoc_override_for_assignment(@assignment1, 
      [@student1], 
      {due_at: Time.zone.now - 1.day, lock_at: Time.zone.now + 4.days, unlock_at: Time.zone.now - 4.days})
      @override2 = create_adhoc_override_for_assignment(@assignment1, 
      [@student2], 
      {due_at: Time.zone.now - 10.days, lock_at: Time.zone.now + 10.days, unlock_at: Time.zone.now - 10.days})
      @override2 = create_adhoc_override_for_assignment(@assignment1, 
      [@student3], 
      {due_at: Time.zone.now + 10.days, lock_at: Time.zone.now + 20.days, unlock_at: Time.zone.now})
    end

    context "with feature on" do
      before(:each) do
        Account.site_admin.enable_feature! :assignment_bulk_edit
        user_session(@teacher1)
        visit_assignments_index_page(@course1.id)
        goto_bulk_edit_view
      end

      it 'displays all assignments and overrides in batch view', custom_timeout: 60 do
        bulk_edit_text = bulk_edit_root.text
        # includes both assignments
        expect(bulk_edit_text).to include('First Overrides Assignment')
        expect(bulk_edit_text).to include('Second Assignment')
        # should have 5 rows including overrides and assignment titles
        expect(bulk_edit_tr_rows.count).to eq 5
      end

      it 'allows editing and saving dates', custom_timeout: 60 do
        date_inputs = assignment_dates_inputs(@assignment2.title)
        # add a due date to Second Assignment
        replace_content(date_inputs[0], format_date_for_view(Time.zone.now, :medium))
        # add unlock_at date
        replace_content(date_inputs[1], format_date_for_view(Time.zone.now - 5.days, :medium))
        # add unlock_at date
        replace_content(date_inputs[2], format_date_for_view(Time.zone.now + 5.days, :medium))
        # save
        save_bulk_edited_dates
        visit_assignments_index_page(@course1.id)
        # the assignment should now have due and available dates
        expect(assignment_row(@assignment2.id).text).to include 'Available until'
        expect(assignment_row(@assignment2.id).text).to include 'Due'
      end
    end
  end
end
