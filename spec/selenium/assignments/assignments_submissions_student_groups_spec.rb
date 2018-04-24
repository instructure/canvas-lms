#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative '../helpers/files_common'
require_relative '../helpers/assignments_common'

describe 'submissions' do
  include_context 'in-process server selenium tests'
  include FilesCommon
  include AssignmentsCommon

  context 'create assignment as a teacher' do
    before do
      course_with_student_logged_in
    end

    context 'file upload' do
      it 'Submitting Group Assignments - Warning', priority: "2", test_id: 56753 do
        create_assignment_for_group('online_upload')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        expect(f('.group_submission_alert')).to include_text('Keep in mind, this submission will count for')
      end

      it 'Submitting Group Assignments - File Upload', priority: "1", test_id: 238164 do
        create_assignment_for_group('online_upload')
        add_file(fixture_file_upload('files/example.pdf', 'application/pdf'),
                 @student, 'example.pdf')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations

        f('.toggle_uploaded_files_link').click
        wait_for_ajaximations

        # clicking the add file button and selecting the fake pdf I uploaded
        fj('.plus').click
        fj('.pdf > span.text.name').click

        f('button[type="submit"]').click
        wait_for_ajaximations

        expect(f('#sidebar_content .header')).to include_text 'Submitted!'
      end

      it 'Submitting Group Assignments - No File Warning', priority: "1", test_id: 238165 do
        create_assignment_for_group('online_upload')
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations

        f('button[type="submit"]').click
        expect(f('.ic-flash-error')).to include_text('You must attach at least one file to this assignment')
      end
    end
  end
end
