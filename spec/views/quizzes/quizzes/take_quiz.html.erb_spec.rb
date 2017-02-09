#
# Copyright (C) 2011 Instructure, Inc.
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

describe '/quizzes/quizzes/take_quiz' do
  it 'should render' do
    course_with_student
    view_context
    assigns[:quiz] = quiz = @course.quizzes.create!(description: 'Hello')
    assigns[:submission] = sub = quiz.generate_submission(@user)
    assigns[:quiz_presenter] = Quizzes::TakeQuizPresenter.new(
      quiz,
      sub,
      params
    )
    render 'quizzes/quizzes/take_quiz'
    doc = Nokogiri::HTML(response.body)
    expect(doc.css('#quiz-instructions').first.content.strip).to eq 'Hello'
    expect(response).not_to be_nil
  end

  it 'should render preview alert for unpublished quiz' do
    course_with_student
    view_context
    assigns[:quiz] = quiz = @course.quizzes.create!
    assigns[:submission] = sub = quiz.generate_submission(@user)
    sub.update_attribute(:workflow_state, 'preview')
    assigns[:quiz_presenter] = Quizzes::TakeQuizPresenter.new(
      quiz,
      sub,
      params
    )
    render 'quizzes/quizzes/take_quiz'

    expect(response).to include 'preview of the draft version'
  end

  it 'should render preview alert for published quiz' do
    course_with_student
    view_context
    quiz = @course.quizzes.create!
    quiz.publish!
    assigns[:quiz] = quiz
    assigns[:submission] = sub = quiz.generate_submission(@user)
    sub.update_attribute(:workflow_state, 'preview')
    assigns[:quiz_presenter] = Quizzes::TakeQuizPresenter.new(
      quiz,
      sub,
      params
    )
    render 'quizzes/quizzes/take_quiz'

    expect(response).to include 'preview of the published version'
  end
end
