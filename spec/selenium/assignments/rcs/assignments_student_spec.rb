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
require_relative '../../helpers/assignments_common'
require_relative '../../helpers/google_drive_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include GoogleDriveCommon
  include AssignmentsCommon

  context "as a student" do

    before(:each) do
      course_with_student_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(:title => 'default assignment', :name => 'default assignment', :due_at => @due_date)
    end

    context "overridden lock_at" do
      before :each do
        setup_sections_and_overrides_all_future
        @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should allow submission when within override locks" do
        @assignment.update(:submission_types => 'online_text_entry')
        # Change unlock dates to be valid for submission
        @override.unlock_at = Time.now.utc - 1.days   # available now
        @override.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations
        assignment_form = f('#submit_online_text_entry_form')
        wait_for_tiny(assignment_form)
        wait_for_ajaximations
        body_text = 'something to submit'
        expect do
          type_in_tiny('#submission_body', body_text)
          wait_for_ajaximations
          submit_form(assignment_form)
          wait_for_ajaximations
        end.to change {
          @assignment.submissions.find_by!(user: @student).body
        }.from(nil).to("<p>#{body_text}</p>")
      end
    end
  end
end
