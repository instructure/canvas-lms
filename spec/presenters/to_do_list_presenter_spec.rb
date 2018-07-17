#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe 'ToDoListPresenter' do
  context 'moderated assignments' do
    let(:course) { Course.create! }
    let(:student) { course_with_student(course: course, active_all: true).user }
    let(:grader) { course_with_teacher(course: course, active_all: true).user }
    let(:final_grader) { course_with_teacher(course: course, active_all: true).user }

    before :each do
      assignment = Assignment.create!(
        context: course,
        title: 'report',
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 2,
        final_grader: final_grader
      )
      assignment.submit_homework(student, body: 'biscuits')
      assignment.grade_student(student, grade: '1', grader: grader, provisional: true)
    end

    it 'returns moderated assignments that user is the final grader for' do
      presenter = ToDoListPresenter.new(nil, final_grader, nil)
      expect(presenter.needs_moderation.first.title).to eq 'report'
    end

    it 'does not return moderated assignments that user is not the final grader for' do
      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_moderation).to be_empty
    end
  end
end
