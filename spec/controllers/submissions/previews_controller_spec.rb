# frozen_string_literal: true

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

require_relative "../../lti_spec_helper"

describe Submissions::PreviewsController do
  include LtiSpecHelper

  describe "GET :show" do
    before do
      course_with_student_and_submitted_homework
      @context = @course
    end

    it "renders show_preview" do
      user_session(@student)
      get :show, params: { course_id: @context.id, assignment_id: @assignment.id, id: @student.id, preview: true }
      expect(response).to render_template(:show_preview)
    end

    context "when assignment is a quiz" do
      before do
        quiz_with_submission
      end

      it "redirects to course_quiz_url" do
        user_session(@student)
        get :show, params: { course_id: @context.id, assignment_id: @quiz.assignment.id, id: @student.id, preview: true }
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

        it "redirects to course_quiz_history_url" do
          get :show, params: { course_id: @context.id, assignment_id: @quiz.assignment.id, id: @student.id, preview: true }
          expect(response).to redirect_to(course_quiz_history_url(@context, @quiz, {
                                                                    headless: 1,
                                                                    user_id: @student.id,
                                                                    version: assigns(:submission).quiz_submission_version
                                                                  }))
        end

        it "favors params[:version] when set" do
          version = 1
          get :show, params: {
            course_id: @context.id,
            assignment_id: @quiz.assignment.id,
            id: @student.id,
            preview: true,
            version:
          }
          expect(response).to redirect_to(course_quiz_history_url(@context, @quiz, {
                                                                    headless: 1,
                                                                    user_id: @student.id,
                                                                    version:
                                                                  }))
        end
      end
    end

    context "anonymous assignments" do
      let(:observer) do
        course_with_observer(
          course: @course,
          associated_user_id: @student.id,
          active_all: true
        ).user
      end

      it "allows observers of the submission's owner to view the preview" do
        assignment = @course.assignments.create!(title: "shhh", anonymous_grading: true)
        user_session(observer)

        get :show, params: { course_id: @course.id, assignment_id: assignment.id, id: @student.id, preview: true }
        expect(response).to be_successful
      end

      it "does not allow observers not observing the submission's owner to view the preview" do
        new_student = User.create!
        @course.enroll_student(new_student, enrollment_state: "active")
        assignment = @course.assignments.create!(title: "shhh", anonymous_grading: true)
        user_session(observer)

        get :show, params: { course_id: @course.id, assignment_id: assignment.id, id: new_student.id, preview: true }
        expect(response).to be_unauthorized
      end

      it "returns unauthorized when the viewer is a teacher and the assignment is currently anonymizing students" do
        assignment = @course.assignments.create!(title: "shhh", anonymous_grading: true)
        user_session(@teacher)

        get :show, params: { course_id: @course.id, assignment_id: assignment.id, id: @student.id, preview: true }
        expect(response).to be_unauthorized
      end

      it "returns unauthorized when the viewer is a peer reviewer and anonymous peer reviews are enabled" do
        assignment = @course.assignments.create!(title: "ok", peer_reviews: true, anonymous_peer_reviews: true)
        reviewer = @course.enroll_student(User.create!, enrollment_state: "active").user
        assignment.assign_peer_review(reviewer, @student)
        user_session(reviewer)

        get :show, params: { course_id: @course.id, assignment_id: assignment.id, id: @student.id, preview: true }
        expect(response).to be_unauthorized
      end
    end

    context "when Asset Processor is attached" do
      render_views

      before do
        @attachment1 = attachment_with_context @student, { display_name: "a1.txt", uploaded_data: StringIO.new("hello") }
        @attachment2 = attachment_with_context @student, { display_name: "a2.txt", uploaded_data: StringIO.new("world") }
        @submission = @assignment.submit_homework(@student, attachments: [@attachment1, @attachment2], submission_type: "online_upload")
        @context = @course
        user_session(@student)
      end

      it "renders show_preview with asset processor data in js ENV" do
        # Use random ids and display_names for the mock attachments
        allow_any_instance_of(AssetProcessorStudentHelper).to receive(:asset_reports).and_return([
                                                                                                   { title: "Asset Report 1", asset: { id: 101, attachment_id: @attachment1.id, attachment_name: @attachment1.display_name } },
                                                                                                   { title: "Asset Report 2", asset: { id: 102, attachment_id: @attachment2.id, attachment_name: @attachment2.display_name } }
                                                                                                 ])
        allow_any_instance_of(AssetProcessorStudentHelper).to receive(:asset_processors).and_return([
                                                                                                      { title: "Live AP" }
                                                                                                    ])

        get :show, params: { course_id: @context.id, assignment_id: @assignment.id, id: @student.id, preview: true }

        body = response.body
        # The page includes Asset Processor data js ENV
        expect(body).to include("ASSET_PROCESSORS")
        # The page includes ASSIGNMENT_NAME in js ENV
        expect(body).to include("ASSIGNMENT_NAME")
        # The page includes ASSET_REPORTS in js ENV
        expect(body).to include("ASSET_REPORTS")
        # Both random attachments are listed on the page
        expect(body).to include('data-attachment-id="' + @attachment1.id.to_s + '"')
        expect(body).to include('data-attachment-id="' + @attachment2.id.to_s + '"')
      end

      it "renders show_preview without Document Processors column if asset reports is nil" do
        allow_any_instance_of(AssetProcessorStudentHelper).to receive(:asset_reports).and_return(nil)

        get :show, params: { course_id: @context.id, assignment_id: @assignment.id, id: @student.id, preview: true }

        body = response.body
        expect(body).not_to include("Document Processors")
      end
    end
  end
end
