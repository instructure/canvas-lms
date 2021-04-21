# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "lti/resource_placement"

module Lti
  describe ResourcePlacement do

    describe 'validations' do

      it 'requires a resource_handler' do
        subject.save
        expect(subject.errors.first).to eq [:message_handler, "can't be blank"]
      end

      it 'accepts types in PLACEMENT_LOOKUP' do
        subject.placement = ResourcePlacement::PLACEMENT_LOOKUP.values.first
        subject.save
        expect(subject.errors).to_not include(:placement)
      end

    end

    describe 'valid_placements' do
      it 'does not include conference_selection when FF disabled' do
        expect(described_class.valid_placements(Account.default)).not_to include(:conference_selection)
      end

      it 'includes conference_selection when FF enabled' do
        Account.site_admin.enable_feature! :conference_selection_lti_placement
        expect(described_class.valid_placements(Account.default)).to include(:conference_selection)
      end

      it 'does not include submission_type_selection when FF disabled' do
        expect(described_class.valid_placements(Account.default)).not_to include(:submission_type_selection)
      end

      it 'includes submission_type_selection when FF enabled' do
        Account.default.enable_feature!(:submission_type_tool_placement)
        expect(described_class.valid_placements(Account.default)).to include(:submission_type_selection)
      end
    end
  end
end
