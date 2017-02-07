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

require_relative '../../../spec_helper'
require_relative '../../views_helper'

describe "/quizzes/quizzes/_quiz_submission" do
  before(:each) do
    course_with_student
    view_context
  end

  context "quiz results are visible to the student" do
    before(:each) do
      quiz = @course.quizzes.create!
      submission = quiz.generate_submission(@user)
      assigns[:quiz] = quiz
      assigns[:submission] = submission
      Quizzes::SubmissionGrader.new(submission).grade_submission
    end

    it "renders" do
      render :partial => "quizzes/quizzes/quiz_submission"
      expect(response).not_to be_nil
    end

    it "sets the IS_SURVEY value in the js env" do
      render :partial => "quizzes/quizzes/quiz_submission"
      expect(controller.js_env.key?(:IS_SURVEY)).to eq(true)
    end
  end

  context "quiz results are not visible to the student" do
    it "renders" do
      quiz = @course.quizzes.create!
      quiz.hide_results = 'always'
      quiz.save!

      assigns[:quiz] = quiz
      assigns[:submission] = assigns[:quiz].generate_submission(@user)
      Quizzes::SubmissionGrader.new(assigns[:submission]).grade_submission
      render :partial => "quizzes/quizzes/quiz_submission"
      expect(response).not_to be_nil
    end
  end

  context 'as a teacher' do
    it "should render Respondus lockdown submission for soft concluded course" do
      course_with_student course: @course, active_all: true
      course_with_teacher course: @course, active_all: true
      view_context

      Quizzes::Quiz.stubs(:lockdown_browser_plugin_enabled?).returns(true)
      quiz = @course.quizzes.create!
      quiz.require_lockdown_browser = true
      quiz.require_lockdown_browser_for_results = true
      quiz.save!
      @course.soft_conclude!

      assigns[:quiz] = quiz
      assigns[:submission] = assigns[:quiz].generate_submission(@student)
      Quizzes::SubmissionGrader.new(assigns[:submission]).grade_submission
      render :partial => "quizzes/quizzes/quiz_submission"
      expect(response).not_to be_nil
    end
  end
end
