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

describe "/quizzes/quizzes/_display_question" do
  def render_as(user)
    view_context @course, user

    render :partial => "quizzes/quizzes/display_question", :object => @q, :locals => {
      :user_answer => @submission.submission_data.find{|a| a[:question_id] == @q[:id]},
      :assessment_results => true}
  end

  before(:once) do
    course_with_teacher(active_all: 1)
    student_in_course(active_all: 1)

    @student.update_attribute(:locale, 'es')
    @teacher.update_attribute(:locale, 'de')

    @quiz = @course.quizzes.create!(:title => "new quiz")
    @quiz.quiz_questions.create!(
      question_data: {
        name: 'LTUE',
        points_possible: 1,
        question_type: 'numerical_question',
        answers: {
          answer_0: {
            numerical_answer_type: 'exact_answer',
            answer_exact: 42,
            answer_text: '',
            answer_weight: '100'
          }
        }
      }
    )
    @quiz.generate_quiz_data
    @quiz.save

    @submission = @quiz.generate_submission(@student)
    @submission.submission_data = { "question_#{@quiz.quiz_data[0][:id]}" => "42.0" }
    Quizzes::SubmissionGrader.new(@submission).grade_submission

    @q = @quiz.stored_questions.first
    @q[:answers][0].delete(:margin) # sometimes this is missing; see #10785
  end

  before(:each) do
    assigns[:quiz] = @quiz
  end

  it "should render" do
    render_as @student

    expect(rendered).not_to be_nil
  end

  context 'when the student and teacher have different locales' do
    it "shows question names in Spanish to the student" do
      I18n.locale = @student.locale

      render_as @student

      expect(rendered).to include('Pregunta')
    end

    it "shows question names in Spanish to the teacher" do
      I18n.locale = @teacher.locale

      render_as @teacher

      expect(rendered).to include('Frage')
    end
  end
end
