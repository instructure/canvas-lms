#
# Copyright (C) 2014 Instructure, Inc.
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

describe Quizzes::QuizSubmissionEventsController do
  before :once do
    Account.default.enable_feature!(:draft_state)
    Account.default.enable_feature!(:quiz_log_auditing)
  end

  describe 'GET /log (#index)' do
    def subject
      get 'index', {
        course_id: @course.id,
        quiz_id: @quiz.id,
        quiz_submission_id: @quiz_submission.id
      }
    end

    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      quiz_model(:course => @course)
      @quiz_submission = @quiz.generate_submission(@student, false)
    end

    it "should require authorization" do
      subject()

      expect(response).to be_redirect
      expect(response).to redirect_to("/login")
    end

    it "should let the teacher in" do
      user_session(@teacher)

      subject()

      expect(response).to be_success
    end

    it "should let the student in" do
      user_session(@student)

      subject()

      expect(response).to be_success
    end

    context 'when quiz_log_auditing feature flag is off' do
      before do
        Account.default.disable_feature!(:quiz_log_auditing)
      end

      after do
        Account.default.enable_feature!(:quiz_log_auditing)
      end

      it "should redirect away" do
        user_session(@student)

        subject()

        expect(response).to be_redirect
        expect(response).to redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/history?user_id=#{@student.id}")
      end
    end
  end
end