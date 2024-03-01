# frozen_string_literal: true

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

require_relative "../../conditional_release_spec_helper"

module ConditionalRelease
  describe Rule do
    it_behaves_like "a soft-deletable model"

    describe "rule definition" do
      it "must have a root account id" do
        rule = build(:rule)
        rule.root_account_id = nil
        expect(rule.valid?).to be false
        rule.root_account_id = ""
        expect(rule.valid?).to be false
      end
    end

    describe "assignment_sets_for_score" do
      before :once do
        @rule = create(:rule)
        create(:scoring_range_with_assignments,
               rule: @rule,
               lower_bound: 90,
               upper_bound: nil,
               assignment_set_count: 1)
        create(:scoring_range_with_assignments,
               rule: @rule,
               lower_bound: 70,
               upper_bound: 90,
               assignment_set_count: 1)
        create(:scoring_range_with_assignments,
               rule: @rule,
               lower_bound: 50,
               upper_bound: 70,
               assignment_set_count: 1)
      end

      it "must apply all scoring ranges" do
        expect(@rule.assignment_sets_for_score(91).length).to eq(1)
        # create a range that crosses the ranges above
        create(:scoring_range_with_assignments,
               rule: @rule,
               lower_bound: 80,
               upper_bound: 95,
               assignment_set_count: 2)
        expect(@rule.assignment_sets_for_score(91).length).to eq(3)
      end

      it "must return [] if no assignments match" do
        expect(@rule.assignment_sets_for_score(10)).to eq([])
      end

      it "must return [] if no scoring ranges are defined" do
        rule = create(:rule)
        expect(rule.assignment_sets_for_score(10)).to eq([])
      end
    end

    describe "with_assignments" do
      before do
        @rule1 = create(:rule_with_scoring_ranges)
        @rule1.scoring_ranges.last.assignment_sets.destroy_all
        @rule2 = create(:rule_with_scoring_ranges, assignment_set_count: 0)
        @rule3 = create(:rule_with_scoring_ranges, assignment_count: 0)
        @rule4 = create(:rule_with_scoring_ranges,
                        scoring_range_count: 1,
                        assignment_set_count: 1,
                        assignment_count: 1)
        @rule5 = create(:rule)
      end

      let(:rules) { Rule.with_assignments.to_a }

      it "only returns rules with assignments" do
        expect(rules).to match_array [@rule1, @rule4]
      end

      it "returns complete rules when assignments are present" do
        rule = rules.find { |r| r.id == @rule1.id }
        expect(rule.scoring_ranges.length).to eq @rule1.scoring_ranges.length
      end
    end
  end
end
