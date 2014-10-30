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

describe "/quizzes/quizzes/history" do
  before do
    course_with_student
    view_context
    assigns[:user] = @user
  end

  context 'beta quiz navigation' do
    before do
      assigns[:quiz] = @course.quizzes.create!
      assigns[:submission] = assigns[:quiz].generate_submission(@user)
      assigns[:current_submission] = assigns[:submission]
      assigns[:version_instances] = assigns[:submission].submitted_attempts
    end

    it 'displays when configured' do
      @student.preferences[:enable_speedgrader_grade_by_question] = true
      @student.save!
      render "quizzes/quizzes/history"
      expect(response.body).to match /quiz-nav/
    end

    it "doesn't display when not enabled" do
      @student.preferences[:enable_speedgrader_grade_by_question] = nil
      @student.save!
      render "quizzes/quizzes/history"
      expect(response.body).not_to match /quiz-nav/
    end
  end

  context 'question group warning' do
    before do
      @student.preferences[:enable_speedgrader_grade_by_question] = true
      @student.save!
    end

    it 'displays when quiz has question groups' do
      @quiz = @course.quizzes.create!
      @quiz.quiz_groups.create!
      assigns[:quiz] = @quiz
      assigns[:submission] = assigns[:quiz].generate_submission(@user)
      assigns[:current_submission] = assigns[:submission]
      assigns[:version_instances] = assigns[:submission].submitted_attempts

      render "quizzes/quizzes/history"
      expect(response.body).to match /grade-by-question-warning/
    end

    it 'does not display when quiz has only questions' do
      assigns[:quiz] = @course.quizzes.create!
      assigns[:submission] = assigns[:quiz].generate_submission(@user)
      assigns[:current_submission] = assigns[:submission]
      assigns[:version_instances] = assigns[:submission].submitted_attempts

      render "quizzes/quizzes/history"
      expect(response.body).not_to match /grade-by-question-warning/
    end
  end
end
