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

describe "/quizzes/quizzes/_question_statistic" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "should render" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create!
    question = {}
    question[:id] = 5
    question[:answers] = []
    question[:question_type] = "multiple_choice_question"
    question[:question_name] = "title of glory"
    question[:unexpected_response_values] = []
    render :partial => "quizzes/quizzes/question_statistic", :object => question, :locals => {:in_group => true, :ignore_correct_answers => true}
    expect(response).not_to be_nil
    expect(response.body).to match /title of glory/
  end

  it "should not show the submitter's name on anonymous surveys" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create! :anonymous_submissions => true,
                                             :quiz_type => 'graded_survey'
    question = {
      :essay_responses => [
        {:text => "Bacon is delicious", :user_id => @student.id}
      ],
      :question_name => "Question",
      :id => 1,
      :unexpected_response_values => [],
    }

    render :partial => 'quizzes/quizzes/question_statistic', :object => question
    expect(response).not_to be_nil
    expect(response.body).not_to include @student.name
  end

  it "renders a link to download all quiz submissions for file upload questions" do
    course_with_student
    view_context
    question = {question_type: 'file_upload_question',
                unexpected_response_values: []}
    quiz = @course.quizzes.create
    quiz.stubs(:quiz_data).returns [question]
    assigns[:quiz] = quiz
    render :partial => 'quizzes/quizzes/question_statistic', object: question
    expect(response.body).to include "Download All Files"
  end
end

