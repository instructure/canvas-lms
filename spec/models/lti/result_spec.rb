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
  context 'when validating' do
    let(:result) { lti_result_model }

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

    it 'requires "score_maximum" if "result_score" is present' do
      expect do
        result.update_attributes!(result_score: 12.2)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Result maximum can't be blank"
      )
    end

    it 'does not require "score_maximum" if "result_score" is blank' do
      expect do
        result.update_attributes!(result_score: nil)
      end.not_to raise_error
    end
  end
end
