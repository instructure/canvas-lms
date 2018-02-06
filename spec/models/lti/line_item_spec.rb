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

RSpec.describe Lti::LineItem, type: :model do
  context 'when validating' do
    let(:line_item) { line_item_model }

    it 'requires "score_maximum"' do
      expect do
        line_item.update_attributes!(score_maximum: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Score maximum can't be blank, Score maximum is not a number"
      )
    end

    it 'requires "label"' do
      expect do
        line_item.update_attributes!(label: nil)
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Label can't be blank")
    end

    it 'requires "assignment"' do
      expect do
        line_item.update_attributes!(assignment: nil)
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assignment can't be blank")
    end
  end
end
