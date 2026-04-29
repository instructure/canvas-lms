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

describe OutcomeProficiencyRating do
  let(:proficiency) { outcome_proficiency_model(account_model) }

  it "requires a specific format for the color" do
    common_params = { description: "A", points: 4, mastery: true, outcome_proficiency: proficiency }
    expect(OutcomeProficiencyRating.new(**common_params, color: "0F160a")).to be_valid
    expect(OutcomeProficiencyRating.new(**common_params, color: "#0F160a")).not_to be_valid
  end

  describe "root_account_id" do
    let(:root_account) { account_model }
    let(:proficiency) { outcome_proficiency_model(root_account) }

    it "sets root_account_id using outcome proficiency" do
      rating = OutcomeProficiencyRating.create!(description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: proficiency)
      expect(rating.root_account_id).to be_present
      expect(rating.root_account_id).to eq(proficiency.root_account_id)
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeProficiencyRating }

    let(:creation_arguments) { [{ description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: proficiency }] }
  end

  describe "rollup calculation integration" do
    let_once(:account) { account_model }
    let_once(:course) { course_model(account:) }
    let(:course_proficiency) { outcome_proficiency_model(course) }
    let(:account_proficiency) { outcome_proficiency_model(account) }

    describe "#rollup_relevant_changes?" do
      let(:rating) { OutcomeProficiencyRating.create!(description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: course_proficiency) }

      it "returns true when points change" do
        rating.update!(points: 3)
        expect(rating.rollup_relevant_changes?).to be true
      end

      it "returns true when mastery changes" do
        rating.update!(mastery: false)
        expect(rating.rollup_relevant_changes?).to be true
      end

      it "returns false when other fields change" do
        rating.update!(description: "New description")
        expect(rating.rollup_relevant_changes?).to be false
      end
    end

    describe "#rollup_calculation" do
      context "with course context proficiency" do
        before do
          Account.site_admin.enable_feature!(:outcomes_rollup_propagation)
        end

        let(:rating) { OutcomeProficiencyRating.create!(description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: course_proficiency) }

        it "enqueues rollup calculation for the course" do
          expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_course)
            .with(course_id: course.id)

          rating.update!(points: 3)
        end

        it "does not enqueue rollup when non-relevant fields change" do
          expect(Outcomes::StudentOutcomeRollupCalculationService).not_to receive(:calculate_for_course)

          rating.update!(description: "New description")
        end
      end

      context "with account context proficiency" do
        let(:rating) { OutcomeProficiencyRating.create!(description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: account_proficiency) }

        it "does not enqueue rollup calculation for account-level changes" do
          expect(Outcomes::StudentOutcomeRollupCalculationService).not_to receive(:calculate_for_course)

          rating.update!(points: 3)
        end
      end

      context "without outcome proficiency" do
        let(:rating) { OutcomeProficiencyRating.new(description: "A", points: 4, mastery: true, color: "00ff00") }

        it "does not enqueue rollup calculation when outcome_proficiency is nil" do
          expect(Outcomes::StudentOutcomeRollupCalculationService).not_to receive(:calculate_for_course)

          rating.rollup_calculation
        end
      end
    end
  end
end
