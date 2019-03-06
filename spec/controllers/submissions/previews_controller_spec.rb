#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'spec_helper'

describe Submissions::PreviewsController do
  describe 'GET :show' do
    before do
      course_with_student_and_submitted_homework
      @context = @course
      user_session(@student)
    end

    it "should render show_preview" do
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, id: @student.id, preview: true}
      expect(response).to render_template(:show_preview)
    end

    context "when assignment is a quiz" do
      before do
        quiz_with_submission
      end

      it "should redirect to course_quiz_url" do
        get :show, params: {course_id: @context.id, assignment_id: @quiz.assignment.id, id: @student.id, preview: true}
        expect(response).to redirect_to(course_quiz_url(@context, @quiz, headless: 1))
      end

      context "and user is a teacher" do
        before do
          user_session(@teacher)
          submission = @quiz.assignment.submissions.where(user_id: @student).first
          submission.quiz_submission.with_versioning(true) do
            submission.quiz_submission.update_attribute(:finished_at, 1.hour.ago)
          end
        end

        it "should redirect to course_quiz_history_url" do
          get :show, params: {course_id: @context.id, assignment_id: @quiz.assignment.id, id: @student.id, preview: true}
          expect(response).to redirect_to(course_quiz_history_url(@context, @quiz, {
            headless: 1,
            user_id: @student.id,
            version: assigns(:submission).quiz_submission_version
          }))
        end

        it "should favor params[:version] when set" do
          version = 1
          get :show, params: {
            course_id: @context.id,
            assignment_id: @quiz.assignment.id,
            id: @student.id,
            preview: true,
            version: version
          }
          expect(response).to redirect_to(course_quiz_history_url(@context, @quiz, {
            headless: 1,
            user_id: @student.id,
            version: version
          }))
        end
      end
    end

    it "returns unauthorized when the viewer is a teacher and the assignment is currently anonymizing students" do
      assignment = @course.assignments.create!(title: 'shhh', anonymous_grading: true)
      user_session(@teacher)

      get :show, params: {course_id: @course.id, assignment_id: assignment.id, id: @student.id, preview: true}
      expect(response).to be_unauthorized
    end

    it "returns unauthorized when the viewer is a peer reviewer and anonymous peer reviews are enabled" do
      assignment = @course.assignments.create!(title: 'ok', peer_reviews: true, anonymous_peer_reviews: true)
      reviewer = @course.enroll_student(User.create!, enrollment_state: 'active').user
      assignment.assign_peer_review(reviewer, @student)
      user_session(reviewer)

      get :show, params: {course_id: @course.id, assignment_id: assignment.id, id: @student.id, preview: true}
      expect(response).to be_unauthorized
    end
  end
end
