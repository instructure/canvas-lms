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
    it { is_expected.to validate_presence_of :context }
    it { is_expected.to validate_uniqueness_of(:context_id).scoped_to(:context_type) }
    it { is_expected.to validate_inclusion_of(:calculation_method).in_array(OutcomeCalculationMethod::CALCULATION_METHODS) }

    context "calculation_int" do
      context "decaying_average" do
        let(:calculation_method) { "decaying_average" }
        let(:calculation_int) { 3 }

        it do
          expect(subject).to allow_values(
            1,
            20,
            99
          ).for(:calculation_int)
        end

        it do
          expect(subject).not_to allow_values(
            -1,
            0,
            100,
            1000,
            nil
          ).for(:calculation_int)
        end
      end

      context "standard_decaying_average" do
        before do
          account.enable_feature!(:outcomes_new_decaying_average_calculation)
        end

        let(:calculation_method) { "standard_decaying_average" }
        let(:calculation_int) { 65 }

        it do
          expect(subject).to allow_values(
            50,
            72,
            99
          ).for(:calculation_int)
        end

        it do
          expect(subject).not_to allow_values(
            -1,
            0,
            49,
            100,
            1000,
            nil
          ).for(:calculation_int)
        end
      end

      context "n_mastery" do
        let(:calculation_method) { "n_mastery" }
        let(:calculation_int) { 3 }

        it do
          expect(subject).to allow_values(
            1,
            4,
            5,
            7,
            10
          ).for(:calculation_int)
        end

        it do
          expect(subject).not_to allow_values(
            -1,
            0,
            11,
            28,
            nil
          ).for(:calculation_int)
        end
      end

      context "highest" do
        let(:calculation_method) { "highest" }

        it { is_expected.to allow_value(nil).for(:calculation_int) }
        it { is_expected.not_to allow_values(1, 10, 100).for(:calculation_int) }
      end

      context "latest" do
        it { is_expected.to allow_value(nil).for(:calculation_int) }
        it { is_expected.not_to allow_values(1, 10, 100).for(:calculation_int) }
      end

      context "average" do
        let(:calculation_method) { "average" }

        it { is_expected.to allow_value(nil).for(:calculation_int) }
        it { is_expected.not_to allow_values(1, 10, 100).for(:calculation_int) }
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
end
