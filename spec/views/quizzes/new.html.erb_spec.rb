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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/quizzes/new" do
  def course_quiz(active=false)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.save!
    @quiz
  end

  def quiz_question
    @quiz.quiz_questions.create
  end

  it "should render" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create!
    render "quizzes/new"
    response.should_not be_nil
  end

  context "with course and quiz" do
    before :each do
      course_with_teacher_logged_in(:active_all => true)
      @quiz = course_quiz
      assigns[:quiz] = @quiz
      view_context
    end
    it "should not display 'NOTE:' message when questions within limit" do
      QuizzesController::QUIZ_QUESTIONS_DETAIL_LIMIT.times { quiz_question }
      render 'quizzes/new'
      response.should_not contain('NOTE: Question details not available when more than')
    end

    it "should explain why 'Show Question Details' is disabled" do
      (QuizzesController::QUIZ_QUESTIONS_DETAIL_LIMIT+1).times { quiz_question }
      render 'quizzes/new'
      response.should contain('NOTE: Question details not available when more than')
    end
  end

end

