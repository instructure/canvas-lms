#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "quizzes/quiz_submissions/show" do

  it "should render" do
    course_with_student
    view_context
    @submission = double('Quizzes::QuizSubmission')
    allow(@submission).to receive(:score).and_return(10)
    allow(@submission).to receive(:data).and_return([])
    @quiz = double('Quizzes::Quiz')
    allow(@quiz).to receive(:questions).and_return([])
    allow(@quiz).to receive(:points_possible).and_return(10)
    allow(@quiz).to receive(:stored_questions).and_return([])
    allow(@quiz).to receive(:show_correct_answers?).and_return(true)
    assign(:quiz, @quiz)
    assign(:submission, @submission)

    render "quizzes/quiz_submissions/show"
    expect(response).not_to be_nil
  end
end

