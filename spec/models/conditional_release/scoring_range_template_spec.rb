#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../conditional_release_spec_helper'
require_dependency "conditional_release/scoring_range_template"

module ConditionalRelease
  describe ScoringRangeTemplate, :type => :model do
    it_behaves_like 'a soft-deletable model'

    describe 'scoring range definition' do
      before do
        @scoring_range_template = build :scoring_range_template
      end

      it 'uses bounds validations' do
        @scoring_range_template.upper_bound = nil
        @scoring_range_template.lower_bound = nil
        expect(@scoring_range_template.valid?).to be false

        @scoring_range_template.upper_bound = 10
        @scoring_range_template.lower_bound = 30
        expect(@scoring_range_template.valid?).to be false
      end

      it 'must have an associated rule template' do
        @scoring_range_template.rule_template = nil
        expect(@scoring_range_template.valid?).to be false
      end
    end

    describe 'build_scoring_range' do
      it 'has the same bounds' do
        template = create :scoring_range_template
        range = template.build_scoring_range
        expect(range.upper_bound).to eq template.upper_bound
        expect(range.lower_bound).to eq template.lower_bound
      end

      it 'works with null bounds' do
        template = create :scoring_range_template, upper_bound: nil
        range = template.build_scoring_range
        expect(range.upper_bound).to be nil

        template = create :scoring_range_template, lower_bound: nil
        range = template.build_scoring_range
        expect(range.lower_bound).to be nil
      end

      it 'does not assign assignments' do
        template = create :scoring_range_template
        range = template.build_scoring_range
        expect(range.assignment_set_associations.count).to be 0
      end

      it 'does not save to database' do
        template = create :scoring_range_template
        range = template.build_scoring_range
        expect(range.new_record?).to be true
      end
    end
  end
end
