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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../views_helper')

describe '/quizzes/quizzes/_take_quiz_right_side' do
  it 'should display quiz due date' do
    course_with_student
    view_context
    due_at = 5.days.from_now
    lock_at = 10.days.from_now
    quiz = assign(:quiz, @course.quizzes.create!(due_at: due_at, lock_at: lock_at))
    submission = assign(:submission, quiz.generate_submission(@user))
    assign(:quiz_presenter, Quizzes::TakeQuizPresenter.new(quiz, submission, params))
    render partial: 'quizzes/quizzes/take_quiz_right_side'

    expect(response).to match(/Attempt due:\s+#{Regexp.quote(datetime_string(due_at))}/)
  end
end
