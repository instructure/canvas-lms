# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../spec_helper"

RSpec.describe Lti::Result do
  let_once(:assignment) { assignment_model(points_possible: 5) }

  context "when validating" do
    let(:result) { lti_result_model assignment: }

    it 'requires "line_item"' do
      expect do
        result.update!(line_item: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Line item can't be blank"
      )
    end

    it 'requires "user"' do
      expect do
        result.update!(user: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: User can't be blank"
      )
    end

    it 'requires the "activity_progress" be valid' do
      expect do
        result.update!(activity_progress: "Banana")
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Activity progress is not included in the list"
      )
    end

    it 'requires the "grading_progress" be valid' do
      expect do
        result.update!(grading_progress: "Banana")
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Grading progress is not included in the list"
      )
    end

    describe "#result_score" do
      subject { result.result_score }

      let(:tool_id) { 1 }
      let(:manual_grader_id) { 2 }

      let(:result) do
        lti_result_model(
          assignment:,
          result_maximum: 1,
          result_score: 0.5
        )
      end

      before { result.submission.update!(grader_id: tool_id * -1) }

      context "when the score_given has not been manually changed" do
        it { is_expected.to eq result["result_score"] }
      end

      context "when result_score is blank" do
        before { result.update!(result_score: 0) }

        it { is_expected.to eq result["result_score"] }
      end

      context "when the submission is blank" do
        before { result.update!(submission: nil) }

        it { is_expected.to eq result["result_score"] }
      end

      context "when the score_given was manually updated by a user" do
        before do
          result.submission.update!(grader_id: 2, score: 4)
          result.reload
        end

        it { is_expected.to eq 0.8 }

        context "when the assignment has 0 points_possible" do
          before { assignment.update!(points_possible: 0) }

          it { is_expected.to eq result["result_score"] }
        end
      end

      context "when the result_score/result_maximum were originally null but the score was manually updated by a user" do
        before do
          result.update(result_maximum: nil, result_score: nil)
          result.submission.update!(grader_id: 2, score: 4)
          result.reload
        end

        it "returns the raw score" do
          expect(subject).to eq(4)
        end
      end

      context "when result_maximum is nil but result_score is not (possible through speedgrader)" do
        # This happens when the original result has no result_maximum or result_score but grading
        # the submission in speedgrader gives it a result_score. Tests the same
        # as above but more of a unit test because it doesn't test the behavior
        # of updating the submission.
        # This should not be possible anymore (see update_score_for_submission)
        # but there still may be old records in the database which have this
        # issue
        before do
          result.submission.update!(grader_id: tool_id)
          described_class.where(id: result.id).update_all(result_maximum: nil, result_score: 0.75)
          result.reload
        end

        it "returns the raw score" do
          expect(subject).to eq(0.75)
        end
      end

      context "when the assignment points_possible is nil" do
        # I don't know if this is possible but the old code implied it might be
        before do
          result.submission.update!(grader_id: tool_id)
          assignment.class.where(id: assignment.id).update_all(points_possible: nil)
          result.reload
        end

        it { is_expected.to eq result["result_score"] }
      end

      context "when result_maximum is 0" do
        before do
          assignment.class.where(id: assignment.id).update_all(points_possible: 10)
          result.update(result_maximum: 0, result_score: 5)
          result.reload
        end

        it { is_expected.to eq result["result_score"] }
      end
    end

    describe "#result_maximum" do
      let(:result) { lti_result_model assignment:, result_score:, result_maximum: }
      let(:result_score) { 10 }
      let(:result_maximum) { 10 }

      context "with result_maximum absent and result_score present" do
        let(:result_maximum) { nil }

        it "raises an error" do
          expect do
            result
          end.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Result maximum can't be blank"
          )
        end
      end

      context "with result_maximum present and result_score present" do
        it "does not raise an error" do
          expect do
            result
          end.not_to raise_error
        end
      end

      context "with result_maximum present and result_score absent" do
        let(:result_score) { nil }

        it "does not raise an error" do
          expect do
            result
          end.not_to raise_error
        end
      end

      context "with result_maximum 0 and the line item's score_maximum 0" do
        it "does not raise an error" do
          expect do
            lti_result_model(
              line_item: line_item_model(
                assignment: assignment_model(points_possible: 0)
              ).tap { |li| li.update! score_maximum: 0 },
              result_maximum: 0,
              result_score: 0.5
            )
          end.not_to raise_error
        end
      end
    end

    describe "#scaled_result_score" do
      let(:result) { lti_result_model assignment:, result_score:, result_maximum: }
      let(:result_score) { 10 }
      let(:result_maximum) { 10 }

      context "when non-numeric" do
        let(:result_score) { "uh oh" }

        it "raises an error" do
          expect { result }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Result score is not a number"
          )
        end
      end

      context "when positive" do
        it "saves score" do
          expect { result }.not_to raise_error
          expect(result.result_score).to eq result_score
        end
      end

      context "when negative" do
        let(:result_score) { -1 }

        it "saves score" do
          expect { result }.not_to raise_error
          expect(result.result_score).to eq result_score
        end
      end
    end
  end

  describe "#needs_review?" do
    let(:result) { lti_result_model assignment: }

    context "when grading_progress is PendingManual" do
      before { result.update!(grading_progress: "PendingManual") }

      %w[Submitted Completed].each do |progress|
        it "returns true for activity_progress #{progress}" do
          result.update!(activity_progress: progress)
          expect(result.needs_review?).to be true
        end
      end

      %w[Initialized Started InProgress].each do |progress|
        it "returns false for activity_progress #{progress}" do
          result.update!(activity_progress: progress)
          expect(result.needs_review?).to be false
        end
      end
    end

    context "when grading_progress is not PendingManual" do
      %w[FullyGraded Pending Failed NotReady].each do |grading_progress|
        it "returns false regardless of activity_progress for #{grading_progress}" do
          result.update!(grading_progress:, activity_progress: "Submitted")
          expect(result.needs_review?).to be false
        end
      end
    end
  end

  describe "#mark_reviewed!" do
    let(:result) { lti_result_model assignment: }

    context "when the result needs review" do
      before do
        result.update!(grading_progress: "PendingManual", activity_progress: "Submitted")
      end

      it "updates grading_progress to FullyGraded" do
        expect { result.mark_reviewed! }.to change { result.grading_progress }.from("PendingManual").to("FullyGraded")
      end

      it "makes needs_review? return false" do
        result.mark_reviewed!
        expect(result.needs_review?).to be false
      end
    end

    context "when the result does not need review" do
      before do
        result.update!(grading_progress: "FullyGraded", activity_progress: "Submitted")
      end

      it "still updates grading_progress to FullyGraded" do
        expect { result.mark_reviewed! }.not_to change { result.grading_progress }
      end
    end

    context "when the record has result_score but null result_maximum (invalid state)" do
      before do
        # Create a record in an invalid state (result_score present, result_maximum null)
        # This simulates old records that might exist in the database
        described_class.where(id: result.id).update_all(result_score: 5.0, result_maximum: nil, grading_progress: "PendingManual")
        result.reload
      end

      it "updates grading_progress without triggering validation errors" do
        expect(result.result_score).to eq(5.0)
        expect(result.result_maximum).to be_nil
        expect(result.grading_progress).to eq("PendingManual")

        # This should not raise a validation error despite the invalid state
        expect { result.mark_reviewed! }.not_to raise_error

        result.reload
        expect(result.grading_progress).to eq("FullyGraded")
        # The invalid state should remain unchanged
        expect(result.result_score).to eq(5.0)
        expect(result.result_maximum).to be_nil
      end
    end
  end

  it_behaves_like "soft deletion" do
    subject { Lti::Result }

    let(:user) { user_model }
    let(:line_item) { line_item_model }
    let(:second_line_item) { line_item_model }
    let(:creation_arguments) do
      [
        {
          line_item:,
          user:,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        },
        {
          line_item: second_line_item,
          user:,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      ]
    end
  end

  context "after saving" do
    let(:result) { lti_result_model assignment: }

    it "sets root_account_id using submission" do
      expect(result.root_account_id).to eq assignment.root_account_id
    end

    it "sets root_account_id using line_item" do
      submission = graded_submission_model({ assignment: assignment_model, user: user_model })
      submission.assignment.root_account_id = nil
      result = Lti::Result.create!(line_item: line_item_model, user: user_model, created_at: Time.zone.now, updated_at: Time.zone.now, submission:)
      expect(result.root_account_id).to eq result.line_item.root_account_id
    end
  end

  describe ".update_score_for_submission" do
    let(:result) { lti_result_model assignment: }

    context "when result maximum is null" do
      it "sets and result maxmium to the assignment's points_possible, and sets the score" do
        expect(assignment.points_possible).to_not be_nil
        expect(result.result_maximum).to be_nil
        Lti::Result.update_score_for_submission(result.submission, 123)
        result.reload
        expect(result.result_maximum).to eq(assignment.points_possible)
        expect(result.result_score).to eq(123)
      end
    end

    context "when result maximum is not null" do
      it "sets the score and leaves the score_maximum untouched" do
        result.update!(result_score: 8, result_maximum: 88)
        Lti::Result.update_score_for_submission(result.submission, 123)
        result.reload
        expect(result.result_maximum).to eq(88)
        expect(result.result_score).to eq(123)
      end
    end
  end
end
