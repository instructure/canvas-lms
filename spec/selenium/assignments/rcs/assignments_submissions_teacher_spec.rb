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
require_relative '../../helpers/files_common'
require_relative '../../helpers/submissions_common'

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include SubmissionsCommon

  context "student view" do

    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it "should allow a student view student to view/submit assignments", priority: "1", test_id: 237034 do
      skip_if_chrome('Student view breaks test in Chrome')
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_text_entry",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f('.assignment .title')).to include_text @assignment.title
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)

      type_in_tiny('#submission_body', 'my assignment submission')
      expect_new_page_load { submit_form(assignment_form) }

      expect(@course.student_view_student.submissions.count).to eq 1
      expect(f('#sidebar_content .details')).to include_text "Submitted!"
    end
  end
end
