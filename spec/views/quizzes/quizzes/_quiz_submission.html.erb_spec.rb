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

describe "/quizzes/quizzes/_quiz_submission" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "should render" do
    course_with_student
    view_context
    assigns[:quiz] = @course.quizzes.create!
    assigns[:submission] = assigns[:quiz].generate_submission(@user)
    Quizzes::SubmissionGrader.new(assigns[:submission]).grade_submission
    render :partial => "quizzes/quizzes/quiz_submission"
    response.should_not be_nil
  end

  it "should render when quiz results are not supposed to be shown to the student" do
    course_with_student
    view_context
    quiz = @course.quizzes.create!
    quiz.hide_results = 'always'
    quiz.save!

    assigns[:quiz] = quiz
    assigns[:submission] = assigns[:quiz].generate_submission(@user)
    Quizzes::SubmissionGrader.new(assigns[:submission]).grade_submission
    render :partial => "quizzes/quizzes/quiz_submission"
    response.should_not be_nil
  end
end

