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

  describe '#assignment_line_item?' do
    let(:resource_link) { resource_link_model }
    let(:line_item) { line_item_model }
    let(:assignment) { assignment_model }

    it 'returns true if there is no resource link' do
      expect(line_item.assignment_line_item?).to eq true
    end

    it 'returns true if the line item was created before all others in the resource' do
      line_item_one = line_item_model(resource_link: resource_link, assignment: assignment)
      line_item_two = line_item_model(resource_link: resource_link, assignment: assignment)
      line_item_two.update_attributes!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_one.assignment_line_item?).to eq true
    end

    it 'returns false if there is a link and the line item is not the first in the resource' do
      line_item_one = line_item_model(resource_link: resource_link, assignment: assignment)
      line_item_two = line_item_model(resource_link: resource_link, assignment: assignment)
      line_item_two.update_attributes!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_two.assignment_line_item?).to eq false
    end
  end

  context 'with lti_link not matching assignment' do
    let(:resource_link) { resource_link_model }
    let(:line_item) { line_item_model resource_link: resource_link }
    let(:line_item_two) { line_item_model resource_link: resource_link }

    it 'returns true if the line item was created before all others in the resource' do
      line_item
      expect do
        line_item_two
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assignment does not match ltiLink")
    end
  end
end
