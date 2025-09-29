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

describe Checkpoints::SubAssignmentSubmissionSerializer do
  before do
    course_with_student(active_all: true)
    @course.account.enable_feature!(:discussion_checkpoints)
  end

  let(:course) { @course }
  let(:student) { @student }
  let(:assignment) { @course.assignments.create!(title: "Assignment 1", has_sub_assignments: true) }

  describe "MissingSubAssignmentSubmissionError" do
    it "is a subclass of StandardError" do
      expect(described_class::MissingSubAssignmentSubmissionError).to be < StandardError
    end

    it "has a default message" do
      error = described_class::MissingSubAssignmentSubmissionError.new
      expect(error.message).to eq("Submission is missing for SubAssignment")
    end

    it "accepts a custom message" do
      custom_message = "Custom error message"
      error = described_class::MissingSubAssignmentSubmissionError.new(custom_message)
      expect(error.message).to eq(custom_message)
    end
  end

  describe ".serialize" do
    context "when assignment does not have sub-assignments" do
      let(:regular_assignment) { course.assignments.create!(title: "Regular Assignment") }

      it "returns false for has_active_submissions and empty submissions array" do
        result = described_class.serialize(assignment: regular_assignment, user_id: student.id)

        expect(result).to eq({
                               has_active_submissions: false,
                               submissions: []
                             })
      end
    end

    context "when assignment has sub-assignments" do
      before do
        @reply_to_topic, @reply_to_entry, @topic = graded_discussion_topic_with_checkpoints(
          context: @course,
          points_possible_reply_to_topic: 5,
          points_possible_reply_to_entry: 3
        )
        @checkpoint_assignment = @topic.assignment
      end

      let(:sub_assignment1) { @reply_to_topic }
      let(:sub_assignment2) { @reply_to_entry }
      let(:assignment) { @checkpoint_assignment }

      context "when sub-assignment submissions exist" do
        before do
          # Create submissions through the proper workflow
          sub_assignment1.find_or_create_submission(student)
          sub_assignment2.find_or_create_submission(student)
        end

        it "returns true for has_active_submissions with submissions array" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_active_submissions]).to be true
          expect(result[:submissions].length).to eq 2
          expect(result[:submissions].map(&:assignment_id)).to contain_exactly(sub_assignment1.id, sub_assignment2.id)
        end
      end

      context "when only some sub-assignment submissions exist" do
        before do
          # Create one submission and delete the other
          sub_assignment1.find_or_create_submission(student)
          submission2 = sub_assignment2.find_or_create_submission(student)
          submission2.update!(workflow_state: "deleted")
        end

        it "returns true for has_active_submissions with only active submissions" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_active_submissions]).to be true
          expect(result[:submissions].length).to eq 1
          expect(result[:submissions].first.assignment_id).to eq sub_assignment1.id
        end
      end

      context "when no sub-assignment submissions ever existed" do
        before do
          @external_user = User.create!(name: "External User")
        end

        it "raises MissingSubAssignmentSubmissionError" do
          expect do
            described_class.serialize(assignment:, user_id: @external_user.id)
          end.to raise_error(
            described_class::MissingSubAssignmentSubmissionError,
            /Submission is missing for SubAssignment #{sub_assignment1.id} and user #{@external_user.id}/
          )
        end

        it "raises MissingSubAssignmentSubmissionError for sub assignment submission that is missing" do
          submission1 = sub_assignment1.find_or_create_submission(student)
          submission1.delete

          expect do
            described_class.serialize(assignment:, user_id: @external_user.id)
          end.to raise_error(
            described_class::MissingSubAssignmentSubmissionError,
            /Submission is missing for SubAssignment #{sub_assignment1.id} and user #{@external_user.id}/
          )
        end
      end

      context "when sub-assignment submissions exist but are deleted" do
        before do
          # Create submissions and then delete them
          submission1 = sub_assignment1.find_or_create_submission(student)
          submission1.update!(workflow_state: "deleted")
          submission2 = sub_assignment2.find_or_create_submission(student)
          submission2.update!(workflow_state: "deleted")
        end

        it "returns false for has_active_submissions with empty submissions array" do
          result = described_class.serialize(assignment:, user_id: student.id)

          expect(result[:has_active_submissions]).to be false
          expect(result[:submissions]).to be_empty
        end
      end
    end
  end

  describe ".find_single_sub_assignment_submission" do
    before do
      @reply_to_topic, @reply_to_entry, @topic = graded_discussion_topic_with_checkpoints(
        context: @course,
        points_possible_reply_to_topic: 5
      )
    end

    let(:sub_assignment) { @reply_to_topic }

    context "when submission exists and is active" do
      before do
        @submission = sub_assignment.find_or_create_submission(student)
      end

      it "returns the submission" do
        result = described_class.find_single_sub_assignment_submission(sub_assignment, student.id)
        expect(result).to eq(@submission)
      end
    end

    context "when submission exists but is deleted" do
      before do
        @submission = sub_assignment.find_or_create_submission(student)
        @submission.update!(workflow_state: "deleted")
      end

      it "returns nil" do
        result = described_class.find_single_sub_assignment_submission(sub_assignment, student.id)
        expect(result).to be_nil
      end
    end

    context "when no submission ever existed" do
      before do
        # Test with a user who has never interacted with this course
        # This represents the realistic scenario where submissions were never created
        @external_user = User.create!(name: "External User for Single Test")
      end

      it "raises MissingSubAssignmentSubmissionError" do
        expect do
          described_class.find_single_sub_assignment_submission(sub_assignment, @external_user.id)
        end.to raise_error(
          described_class::MissingSubAssignmentSubmissionError,
          "Submission is missing for SubAssignment #{sub_assignment.id} and user #{@external_user.id}"
        )
      end
    end
  end
end
