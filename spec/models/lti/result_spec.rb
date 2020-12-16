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

require_relative '../../spec_helper'

RSpec.describe Lti::Result, type: :model do
  let_once(:assignment) { assignment_model(points_possible: 5) }

  context 'when validating' do
    let(:result) { lti_result_model assignment: assignment }

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
        result.update!(activity_progress: 'Banana')
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Activity progress is not included in the list"
      )
    end

    it 'requires the "grading_progress" be valid' do
      expect do
        result.update!(grading_progress: 'Banana')
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Grading progress is not included in the list"
      )
    end

    describe '#scaled_result_score' do
      subject { result.scaled_result_score }

      let(:tool_id) { 1 }
      let(:manual_grader_id) { 2 }

      let(:result) do
        lti_result_model(
          assignment: assignment,
          result_maximum: 1,
          result_score: 0.5,
        )
      end

      before { result.submission.update!(grader_id: tool_id * -1) }

      context 'when the score_given has not been manually changed' do
        it { is_expected.to eq result.result_score }
      end

      context 'when result_score is blank' do
        before { result.update!(result_score: 0) }

        it { is_expected.to eq result.result_score }
      end

      context 'when the submission is blank' do
        before { result.update!(submission: nil) }

        it { is_expected.to eq result.result_score }
      end

      context 'when the score_given was manually updated by a user' do
        before { result.submission.update!(grader_id: 2, score: 4) }

        it { is_expected.to eq 0.1 }

        context 'when the assignment has 0 points_possible' do
          before { assignment.update!(points_possible: 0) }

          it { is_expected.to eq result.result_score }
        end
      end
    end

    describe '#result_maximum' do
      let(:result) { lti_result_model assignment: assignment, result_score: result_score, result_maximum: result_maximum}
      let(:result_score) { 10 }
      let(:result_maximum) { 10 }

      context 'with result_maximum absent and result_score present' do
        let(:result_maximum) { nil }

        it 'raises an error' do
          expect do
            result
          end.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Result maximum can't be blank"
          )
        end
      end

      context 'with result_maximum present and result_score present' do
        it 'does not raise an error' do
          expect do
            result
          end.not_to raise_error
        end
      end

      context 'with result_maximum present and result_score absent' do
        let(:result_score) { nil }

        it 'does not raise an error' do
          expect do
            result
          end.not_to raise_error
        end
      end

      context 'with result_maximum less than 0' do
        let(:result_maximum) { -1 }

        it 'raises an error' do
          expect do
            result
          end.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Result maximum must be greater than 0"
          )
        end
      end
    end

    describe '#result_score' do
      let(:result) { lti_result_model assignment: assignment, result_score: result_score, result_maximum: result_maximum}
      let(:result_score) { 10 }
      let(:result_maximum) { 10 }

      context 'with result_score less than 0' do
        let(:result_score) { -1 }

        it 'raises an error' do
          expect do
            result
          end.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Result score must be greater than or equal to 0"
          )
        end
      end
    end

    it_behaves_like "soft deletion" do
      let(:user) { user_model }
      let(:line_item) { line_item_model }
      let(:second_line_item) { line_item_model }
      let(:creation_arguments) do
        [
          {
            line_item: line_item,
            user: user,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          },
          {
            line_item: second_line_item,
            user: user,
            created_at: Time.zone.now,
            updated_at: Time.zone.now
          }
        ]
      end
      subject { Lti::Result }
    end
  end

  context 'after saving' do
    let(:result) { lti_result_model assignment: assignment }

    it 'sets root_account_id using submission' do
      expect(result.root_account_id).to eq assignment.root_account_id
    end

    it 'sets root_account_id using line_item' do
      submission = graded_submission_model({ assignment: assignment_model, user: user_model })
      submission.assignment.root_account_id = nil
      result = Lti::Result.create!(line_item: line_item_model, user: user_model, created_at: Time.zone.now, updated_at: Time.zone.now, submission: submission)
      expect(result.root_account_id).to eq result.line_item.root_account_id
    end
  end
end
