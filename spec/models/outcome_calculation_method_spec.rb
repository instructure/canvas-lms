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

describe OutcomeCalculationMethod do
  subject { OutcomeCalculationMethod.create!(creation_params) }

  let_once(:account) { account_model }
  let(:calculation_method) { "latest" }
  let(:calculation_int) { nil }
  let(:creation_params) { { context: account, calculation_method:, calculation_int: } }

  describe "validations" do
    it "restricts the range for calculation_int when the decaying_average method is used" do
      common_params = { **creation_params, calculation_method: "decaying_average" }

      [1, 20, 99].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).to be_valid
      end

      [-1, 0, 100, 1000, nil].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).not_to be_valid
      end
    end

    it "restricts the range for calculation_int when the standard_decaying_average method is used" do
      common_params = { **creation_params, calculation_method: "standard_decaying_average" }

      account.enable_feature!(:outcomes_new_decaying_average_calculation)

      [50, 72, 99].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).to be_valid
      end

      [-1, 0, 49, 100, 1000, nil].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).not_to be_valid
      end
    end

    it "restricts the range for calculation_int when the n_mastery method is used" do
      common_params = { **creation_params, calculation_method: "n_mastery" }

      [1, 4, 5, 7, 10].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).to be_valid
      end

      [-1, 0, 11, 28, nil].each do |calculation_int|
        expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).not_to be_valid
      end
    end

    it "restricts the range for calculation_int when the highest / latest / average method is used" do
      %w[highest latest average].each do |calculation_method|
        common_params = { **creation_params, calculation_method: }

        expect(OutcomeCalculationMethod.new(**common_params, calculation_int: nil)).to be_valid

        [1, 10, 100].each do |calculation_int|
          expect(OutcomeCalculationMethod.new(**common_params, calculation_int:)).not_to be_valid
        end
      end
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeCalculationMethod }

    let(:creation_arguments) { [creation_params, creation_params.merge(context: course_model)] }
  end

  describe "as_json" do
    it "includes expected keys" do
      expect(subject.as_json.keys).to match_array(%w[id calculation_method calculation_int context_type context_id])
    end
  end

  describe "find_or_create_default!" do
    it "creates the default calculation method if one doesnt exist" do
      calculation_method = OutcomeCalculationMethod.find_or_create_default!(account)
      expect(calculation_method.calculation_method).to eq "highest"
      expect(calculation_method.workflow_state).to eq "active"
      expect(calculation_method.calculation_int).to be_nil
      expect(calculation_method.context).to eq account
    end

    it "creates the default calculation method if outcomes_new_decaying_average_calculation FF enabled" do
      account.enable_feature!(:outcomes_new_decaying_average_calculation)
      calculation_method = OutcomeCalculationMethod.find_or_create_default!(account)
      expect(calculation_method.calculation_method).to eq "highest"
      expect(calculation_method.workflow_state).to eq "active"
      expect(calculation_method.calculation_int).to be_nil
      expect(calculation_method.context).to eq account
    end

    it "finds the method if one exists" do
      calculation_method = outcome_calculation_method_model(account)
      default = OutcomeCalculationMethod.find_or_create_default!(account)
      expect(calculation_method).to eq default
    end

    it "can reset and undelete soft deleted records" do
      calculation_method = outcome_calculation_method_model(account)
      calculation_method.destroy!
      default = OutcomeCalculationMethod.find_or_create_default!(account)
      calculation_method = calculation_method.reload
      expect(calculation_method).to eq default
      expect(calculation_method.workflow_state).to eq "active"
    end

    it "can graciously handle RecordInvalid errors" do
      calculation_method = outcome_calculation_method_model(account)
      allow(OutcomeCalculationMethod).to receive(:find_by).and_return(nil, calculation_method)
      default = OutcomeCalculationMethod.find_or_create_default!(@account)
      expect(calculation_method).to eq default
    end
  end

  describe "interaction with cache" do
    it "clears the account cache on save" do
      expect(account).to receive(:clear_downstream_caches).with(:resolved_outcome_proficiency)
      OutcomeProficiency.find_or_create_default!(account)
    end
  end

  describe "rollup calculation integration" do
    let_once(:course) { course_model(account:) }

    describe "#rollup_relevant_changes?" do
      it "returns true when calculation_method changes" do
        method = OutcomeCalculationMethod.create!(context: course, calculation_method: "highest")
        method.update!(calculation_method: "latest")
        expect(method.rollup_relevant_changes?).to be true
      end

      it "returns true when calculation_int changes" do
        method = OutcomeCalculationMethod.create!(context: course, calculation_method: "decaying_average", calculation_int: 65)
        method.update!(calculation_int: 75)
        expect(method.rollup_relevant_changes?).to be true
      end

      it "returns false when other fields change" do
        method = OutcomeCalculationMethod.create!(context: course, calculation_method: "highest")
        method.update!(workflow_state: "deleted")
        expect(method.rollup_relevant_changes?).to be false
      end
    end

    describe "#rollup_calculation" do
      context "with course context" do
        before do
          Account.site_admin.enable_feature!(:outcomes_rollup_propagation)
        end

        it "enqueues rollup calculation for the course" do
          method = OutcomeCalculationMethod.create!(context: course, calculation_method: "highest")
          expect(Outcomes::StudentOutcomeRollupCalculationService).to receive(:calculate_for_course)
            .with(course_id: course.id)

          method.update!(calculation_method: "latest")
        end

        it "does not enqueue rollup when non-relevant fields change" do
          method = OutcomeCalculationMethod.create!(context: course, calculation_method: "highest")
          expect(Outcomes::StudentOutcomeRollupCalculationService).not_to receive(:calculate_for_course)

          method.update!(workflow_state: "deleted")
        end
      end

      context "with account context" do
        it "does not enqueue rollup calculation for account-level changes" do
          method = OutcomeCalculationMethod.create!(context: account, calculation_method: "highest")

          expect(Outcomes::StudentOutcomeRollupCalculationService).not_to receive(:calculate_for_course)

          method.update!(calculation_method: "latest")
        end
      end
    end
  end
end
