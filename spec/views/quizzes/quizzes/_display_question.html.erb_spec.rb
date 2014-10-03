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
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "should render" do
    course_with_student
    view_context

    @quiz = @course.quizzes.create!(:title => "new quiz")
    @quiz.quiz_questions.create!(:question_data =>
      {:name => 'LTUE', :points_possible => 1, 'question_type' => 'numerical_question',
       'answers' => {'answer_0' => {'numerical_answer_type' => 'exact_answer',
                                    'answer_exact' => 42, 'answer_text' => '', 'answer_weight' => '100'}}})
    @quiz.generate_quiz_data
    @quiz.save

    @submission = @quiz.generate_submission(@student)
    @submission.submission_data = { "question_#{@quiz.quiz_data[0][:id]}" => "42.0" }
    Quizzes::SubmissionGrader.new(@submission).grade_submission

    assigns[:quiz] = @quiz
    q = @quiz.stored_questions.first
    q[:answers][0].delete(:margin) # sometimes this is missing; see #10785
    render :partial => "quizzes/quizzes/display_question", :object => q, :locals => {
        :user_answer => @submission.submission_data.find{|a| a[:question_id] == q[:id]},
        :assessment_results => true}
    response.should_not be_nil
  end
end
