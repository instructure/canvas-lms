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

describe "/quizzes/quizzes/_quiz_summary" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "should render" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create!
    assigns[:submissions_hash] = {}
    render :partial => "quizzes/quizzes/quiz_summary", :object => assigns[:quiz]
    expect(response).not_to be_nil
  end
  
  it "should not show scores on muted quizzes" do
    course_with_student
    view_context
    @quiz = @course.quizzes.create!
    @quiz.generate_quiz_data
    @quiz.workflow_state = 'available'
    @quiz.published_at = Time.now
    @quiz.save

    expect(@quiz.assignment).not_to be_nil
    @quiz.assignment.mute!
    @submission = @quiz.generate_submission(@user)
    Quizzes::SubmissionGrader.new(@submission).grade_submission

    view_context
    assigns[:quiz] = @quiz
    assigns[:submissions_hash] = { @quiz.id => @submission }
    render :partial => "quizzes/quizzes/quiz_summary", :object => @quiz

    expect(response).not_to be_nil
    expect(response.body).to match /Instructor is working on grades/
  end
end

