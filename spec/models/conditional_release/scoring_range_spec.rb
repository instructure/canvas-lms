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
  describe ScoringRange do
    it_behaves_like "a soft-deletable model"

    describe "scoring range definition" do
      it "must have at least one bound" do
        range = build(:scoring_range)
        range.lower_bound = range.upper_bound = nil
        expect(range.valid?).to be false
      end

      it "must have lower bound less than upper" do
        range = build(:scoring_range)
        range.lower_bound = 100
        range.upper_bound = 1
        expect(range.valid?).to be false
      end

      it "can have null bounds" do
        range = build(:scoring_range)
        range.lower_bound = nil
        range.upper_bound = 100
        expect(range.valid?).to be true
        range.lower_bound = 99
        range.upper_bound = nil
        expect(range.valid?).to be true
      end

      it "must have non-negative bounds" do
        range = build(:scoring_range)
        range.lower_bound = -10
        expect(range.valid?).to be false
        range = build(:scoring_range)
        range.upper_bound = -10
        expect(range.valid?).to be false
      end
    end

    describe "for_score" do
      before do
        @rule = create(:rule)
        @range = create(:scoring_range, rule: @rule)
        create(:assignment_set_association, scoring_range: @range)
      end

      it "must return an empty relation when nothing matches" do
        expect(ScoringRange.for_score(-10_000).count).to eq 0
      end

      it "must apply bounds when both assigned" do
        @range.upper_bound = 80
        @range.lower_bound = 40
        @range.save!
        expect(@rule.scoring_ranges.for_score(90).count).to eq 0
        expect(@rule.scoring_ranges.for_score(50).count).to eq 1
        expect(@rule.scoring_ranges.for_score(30).count).to eq 0
      end

      it "must apply upper bound as > score" do
        @range.upper_bound = 90
        @range.save!
        expect(@rule.scoring_ranges.for_score(90.001).count).to eq 0
        expect(@rule.scoring_ranges.for_score(90).count).to eq 0
        expect(@rule.scoring_ranges.for_score(89.999).count).to eq 1
      end

      it "must apply lower bound as <= score" do
        @range.lower_bound = 40
        @range.save!
        expect(@rule.scoring_ranges.for_score(40.001).count).to eq 1
        expect(@rule.scoring_ranges.for_score(40).count).to eq 1
        expect(@rule.scoring_ranges.for_score(39.999).count).to eq 0
      end

      it "must apply correctly when only upper bound" do
        @range.upper_bound = 20
        @range.lower_bound = nil
        @range.save!
        expect(@rule.scoring_ranges.for_score(-10).count).to eq 1
        expect(@rule.scoring_ranges.for_score(10).count).to eq 1
        expect(@rule.scoring_ranges.for_score(30).count).to eq 0
      end

      it "must apply correctly when only lower bound" do
        @range.lower_bound = 10
        @range.upper_bound = nil
        @range.save!
        expect(@rule.scoring_ranges.for_score(-10).count).to eq 0
        expect(@rule.scoring_ranges.for_score(20).count).to eq 1
        expect(@rule.scoring_ranges.for_score(1000).count).to eq 1
      end
    end

    describe "contains_score" do
      before do
        @rule = create(:rule)
        @range = create(:scoring_range, rule: @rule)
        create(:assignment_set_association, scoring_range: @range)
      end

      it "must properly evaluate a bound of 0" do
        @range.lower_bound = nil
        @range.upper_bound = 0
        @range.save!
        range2 = create(:scoring_range, rule: @rule)
        range2.lower_bound = 0
        range2.upper_bound = 1
        range2.save!
        expect(@rule.scoring_ranges.first.contains_score(0)).to be false
        expect(@rule.scoring_ranges.last.contains_score(0)).to be true
      end

      it "must properly evaluate bounds" do
        @range.lower_bound = 1
        @range.upper_bound = 2
        @range.save!
        expect(@rule.scoring_ranges.first.contains_score(2)).to be false
        expect(@rule.scoring_ranges.last.contains_score(1)).to be true
      end
    end

    describe "#assignment_sets" do
      it "builds a assignment_set if one does not exist" do
        range = create(:scoring_range_with_assignments, assignment_set_count: 0)
        expect(AssignmentSet.count).to eq 0
        expect(range.assignment_sets.length).to eq 1
      end

      it "returns existing assignment_sets" do
        range = create(:scoring_range_with_assignments, assignment_set_count: 2)
        expect(range.assignment_sets.length).to eq 2
      end
    end
  end
end
