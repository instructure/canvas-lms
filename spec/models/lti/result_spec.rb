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
  let_once(:assignment) { assignment_model }

  context 'when validating' do
    let(:result) { lti_result_model assignment: assignment }

    it 'requires "line_item"' do
      expect do
        result.update_attributes!(line_item: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Line item can't be blank"
      )
    end

    it 'requires "user"' do
      expect do
        result.update_attributes!(user: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: User can't be blank"
      )
    end

    it 'requires the "activity_progress" be valid' do
      expect do
        result.update_attributes!(activity_progress: 'Banana')
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Activity progress is not included in the list"
      )
    end

    it 'requires the "grading_progress" be valid' do
      expect do
        result.update_attributes!(grading_progress: 'Banana')
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Grading progress is not included in the list"
      )
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
  end
end
