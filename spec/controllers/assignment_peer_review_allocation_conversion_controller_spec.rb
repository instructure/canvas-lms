# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe AssignmentPeerReviewAllocationConversionController do
  before :once do
    @course = course_factory(active_all: true)
    @teacher = teacher_in_course(active_all: true, course: @course).user
    @student = student_in_course(active_all: true, course: @course).user
    @assignment = assignment_model(course: @course, peer_reviews: true)
  end

  describe "PUT 'convert_peer_review_allocations'" do
    context "errors" do
      it "requires proper permissions" do
        user_session(@student)
        put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AllocationRule" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a conflict if a job is already running" do
        user_session(@teacher)
        Progress.create!(context: @assignment, tag: PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG, workflow_state: "running")

        put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AllocationRule" }

        expect(response).to have_http_status(:conflict)
        expect(response.body).to include("A peer review conversion job is already in progress for this assignment.")
      end

      it "returns a bad request for invalid type parameter" do
        user_session(@teacher)
        put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "InvalidType" }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Type must be 'AllocationRule' or 'AssessmentRequest'")
      end

      it "returns a bad request when feature flag validation fails" do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        user_session(@teacher)
        put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AllocationRule" }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Feature flag peer_review_allocation_and_grading must be disabled")
      end
    end

    it "starts a conversion job with AllocationRule type" do
      @course.disable_feature!(:peer_review_allocation_and_grading)
      user_session(@teacher)
      put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AllocationRule" }

      expect(response).to have_http_status(:no_content)

      job = Progress.last
      expect(job.context).to eq(@assignment)
      expect(job.tag).to eq(PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG)
    end

    it "starts a conversion job with AssessmentRequest type" do
      @course.enable_feature!(:peer_review_allocation_and_grading)
      PeerReview::PeerReviewCreatorService.call(parent_assignment: @assignment)
      @assignment.reload

      user_session(@teacher)
      put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AssessmentRequest" }

      expect(response).to have_http_status(:no_content)

      job = Progress.last
      expect(job.context).to eq(@assignment)
      expect(job.tag).to eq(PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG)
    end

    it "accepts should_delete parameter" do
      @course.disable_feature!(:peer_review_allocation_and_grading)
      user_session(@teacher)
      put :convert_peer_review_allocations, params: { course_id: @course.id, assignment_id: @assignment.id, type: "AllocationRule", should_delete: true }

      expect(response).to have_http_status(:no_content)

      job = Progress.last
      expect(job.context).to eq(@assignment)
      expect(job.tag).to eq(PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG)
    end
  end

  describe "GET 'conversion_job_status'" do
    context "errors" do
      it "requires proper permissions" do
        user_session(@student)
        get :conversion_job_status, params: { course_id: @course.id, assignment_id: @assignment.id }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns not found if no job exists" do
        user_session(@teacher)
        get :conversion_job_status, params: { course_id: @course.id, assignment_id: @assignment.id }

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("No peer review conversion job found for this assignment.")
      end
    end

    it "returns the status of an active job" do
      user_session(@teacher)
      Progress.create!(context: @assignment, tag: PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG, workflow_state: "running", completion: 50)

      get :conversion_job_status, params: { course_id: @course.id, assignment_id: @assignment.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("workflow_state")
      expect(response.body).to include("running")
      expect(response.body).to include("progress")
      expect(response.body).to include("50")
    end
  end
end
