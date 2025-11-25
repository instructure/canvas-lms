# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe PeerReview::PeerReviewSubmissionSerializer do
  before do
    course_with_teacher(active_all: true)
    @course.enable_feature!(:peer_review_allocation_and_grading)

    @student = user_factory(active_all: true)
    @course.enroll_student(@student, enrollment_state: "active")

    @assignment = @course.assignments.create!(
      title: "Assignment 1",
      peer_reviews: true,
      peer_review_count: 2
    )

    @peer_review_sub_assignment = @assignment.create_peer_review_sub_assignment!(
      peer_reviews: true,
      peer_review_count: 2
    )
  end

  let(:course) { @course }
  let(:student) { @student }
  let(:assignment) { @assignment }
  let(:peer_review_sub_assignment) { @peer_review_sub_assignment }

  describe "MissingPeerReviewSubmissionError" do
    it "is a subclass of StandardError" do
      expect(described_class::MissingPeerReviewSubmissionError).to be < StandardError
    end

    it "has a default message" do
      error = described_class::MissingPeerReviewSubmissionError.new
      expect(error.message).to eq(I18n.t("Submission is missing for PeerReviewSubAssignment"))
    end

    it "accepts a custom message" do
      custom_message = "Custom error message"
      error = described_class::MissingPeerReviewSubmissionError.new(custom_message)
      expect(error.message).to eq(custom_message)
    end
  end

  describe ".serialize" do
    context "when assignment does not have peer reviews enabled" do
      let(:regular_assignment) { course.assignments.create!(title: "Regular Assignment", peer_reviews: false) }

      it "returns false for has_peer_review_submission and nil submission" do
        result = described_class.serialize(assignment: regular_assignment, user_id: student.id)

        expect(result).to eq({
                               has_peer_review_submission: false,
                               submission: nil
                             })
      end
    end

    context "when assignment has peer review sub-assignment" do
      context "when peer review submission exists" do
        before do
          @submission = peer_review_sub_assignment.submit_homework(
            student,
            submission_type: "online_text_entry",
            body: "peer_review"
          )
        end

        it "returns true for has_peer_review_submission with submission" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_peer_review_submission]).to be true
          expect(result[:submission]).to eq(@submission)
          expect(result[:submission].assignment_id).to eq(peer_review_sub_assignment.id)
        end
      end

      context "when peer review submission does not exist" do
        before do
          peer_review_sub_assignment.find_or_create_submission(student)
        end

        it "returns false for has_peer_review_submission with nil submission" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_peer_review_submission]).to be false
          expect(result[:submission]).to be_nil
        end
      end

      context "when peer review submission exists but is deleted" do
        before do
          submission = peer_review_sub_assignment.submit_homework(
            student,
            submission_type: "online_text_entry",
            body: "peer_review"
          )
          submission.update!(workflow_state: "deleted")
        end

        it "returns false for has_peer_review_submission with nil submission" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_peer_review_submission]).to be false
          expect(result[:submission]).to be_nil
        end
      end

      context "when peer review sub-assignment is deleted" do
        before do
          peer_review_sub_assignment.update!(workflow_state: "deleted")
        end

        it "returns false for has_peer_review_submission and nil submission" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_peer_review_submission]).to be false
          expect(result[:submission]).to be_nil
        end
      end
    end
  end

  describe ".find_peer_review_submission" do
    context "when submission exists and is active" do
      before do
        @submission = peer_review_sub_assignment.submit_homework(
          student,
          submission_type: "online_text_entry",
          body: "peer_review"
        )
      end

      it "returns the submission" do
        result = described_class.find_peer_review_submission(peer_review_sub_assignment, student.id)
        expect(result).to eq(@submission)
      end
    end

    context "when submission exists but is unsubmitted" do
      before do
        @submission = peer_review_sub_assignment.find_or_create_submission(student)
      end

      it "returns nil" do
        result = described_class.find_peer_review_submission(peer_review_sub_assignment, student.id)
        expect(result).to be_nil
      end
    end

    context "when submission exists but is deleted" do
      before do
        @submission = peer_review_sub_assignment.submit_homework(
          student,
          submission_type: "online_text_entry",
          body: "peer_review"
        )
        @submission.update!(workflow_state: "deleted")
      end

      it "returns nil" do
        result = described_class.find_peer_review_submission(peer_review_sub_assignment, student.id)
        expect(result).to be_nil
      end
    end

    context "when no submission ever existed" do
      before do
        @external_user = User.create!(name: "External User")
      end

      it "raises MissingPeerReviewSubmissionError" do
        expect do
          described_class.find_peer_review_submission(peer_review_sub_assignment, @external_user.id)
        end.to raise_error(
          described_class::MissingPeerReviewSubmissionError,
          I18n.t("Submission is missing for PeerReviewSubAssignment %{assignment_id} and user %{user_id}",
                 assignment_id: peer_review_sub_assignment.id,
                 user_id: @external_user.id)
        )
      end
    end
  end
end
