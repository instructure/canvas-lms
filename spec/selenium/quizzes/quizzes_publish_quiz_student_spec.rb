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
require_relative '../helpers/quizzes_common'

describe 'when a quiz is published' do
  include_context "in-process server selenium tests"

  context 'as a student' do
    include QuizzesCommon

    before(:each) do
      course_with_student_logged_in
      create_quiz_with_due_date(
        course: @course,
        due_at: default_time_for_due_date(Time.zone.now.advance(days: 2))
      )
    end

    context 'when on the course home page' do
      before(:each) { get "/courses/#{@course.id}" }

      it 'To Do List includes published, untaken quizzes that are due soon for students', priority: "1", test_id: 140613 do
        wait_for_ajaximations
        expect(f('#planner-todosidebar-item-list')).to include_text 'Test Quiz'
      end
    end
  end
end
