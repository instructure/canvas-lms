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
require_relative '../helpers/submissions_common'
require_relative '../helpers/assignments_common'

describe 'assignments' do
  include_context 'in-process server selenium tests'
  include FilesCommon
  include AssignmentsCommon
  include SubmissionsCommon

  before do
    course_with_teacher_logged_in
  end

  context 'quick add' do

    def fill_out_quick_add_modal(type)
      get "/courses/#{@course.id}/assignments"
      f('.add_assignment').click

      @assignment_name = 'pink panther'
      @assignment_date = '2015-07-31'
      @assignment_points = '3'

      click_option(f('[name="submission_types"]'),type)

      f('div.form-dialog-content.create_assignment_dialog > div.form-horizontal > div:nth-of-type(2) > div.controls > input').send_keys(@assignment_name)
      f('.datetime_field').send_keys(@assignment_date)
      f('input[name="points_possible"]').send_keys(@assignment_points)
    end

    it 'should open quick add modal ', priority:"1", test_id: 238872 do
      get "/courses/#{@course.id}/assignments"

      f('.add_assignment').click

      expect(f('.ui-dialog-title')).to include_text('Add Assignment to Assignments')
      expect(f('.create_assignment_dialog')).to be
    end

    context 'more options button' do
      it 'should work for assignments and transfer values', priority:"1", test_id: 56009 do
        fill_out_quick_add_modal('Assignment')
        f('.more_options').click

        expect(f('#edit_assignment_header')).to be
        expect(f('#assignment_name').attribute(:value)).to include(@assignment_name)
        expect(f('#assignment_points_possible').attribute(:value)).to include(@assignment_points)
        expect(f('input.date_field.datePickerDateField.DueDateInput.datetime_field_enabled.hasDatepicker').attribute(:value)).to include('Jul 31')
      end

      it 'should work for discussions and transfer values', priority:"1", test_id: 58760 do
        fill_out_quick_add_modal('Discussion')
        f('.more_options').click

        expect(f('.discussion-edit-header')).to be
        expect(f('#discussion-title').attribute(:value)).to include(@assignment_name)
        expect(f('#discussion_topic_assignment_points_possible').attribute(:value)).to include(@assignment_points)
        expect(f('input.date_field.datePickerDateField.DueDateInput.datetime_field_enabled.hasDatepicker').attribute(:value)).to include('Jul 31')
      end

      it 'should work for quizzes and transfer values', priority:"1", test_id: 238873 do
        fill_out_quick_add_modal('Quiz')
        f('.more_options').click

        expect(f('#quiz_edit_wrapper')).to be
        expect(f('#quiz_title').attribute(:value)).to include(@assignment_name)
        expect(f('input.date_field.datePickerDateField.DueDateInput.datetime_field_enabled.hasDatepicker').attribute(:value)).to include('Jul 31')
      end
    end
  end

  context 'quick edit' do
    before do
      @title = 'zoidberg'
    end

    it 'should work with an assignment', priority:"1", test_id: 112794 do
      assignment = @course.assignments.create!(title: 'test assignment', name:@title, workflow_state: "published")
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit

      expect(f("#assign_#{assignment.id}_assignment_name").attribute(:value)).to include(@title)
    end

    it 'should work with a quiz', priority:"1", test_id: 269809 do
      assignment = @course.assignments.create(title: @title, submission_types: "online_quiz", workflow_state: "published")
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit

      expect(f("#assign_#{assignment.id}_assignment_name").attribute(:value)).to include(@title)
    end

    it 'should work with a graded discussion', priority:"1", test_id: 269810 do
      assignment = @course.assignments.create!(name:  @title, submission_types: 'discussion_topic')
      get "/courses/#{@course.id}/assignments"
      click_cog_to_edit
      expect(f("#assign_#{assignment.id}_assignment_name").attribute(:value)).to include(@title)
    end
  end
end
