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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OutcomeCalculationMethod, type: :model do
  subject { OutcomeCalculationMethod.create!(creation_params) }

  let_once(:account) { account_model }
  let(:calculation_method) { 'latest' }
  let(:calculation_int) { nil }
  let(:creation_params) { { context: account, calculation_method: calculation_method, calculation_int: calculation_int } }

  describe 'validations' do
    it { is_expected.to validate_presence_of :context }
    it { is_expected.to validate_uniqueness_of(:context_id).scoped_to(:context_type) }
    it { is_expected.to validate_inclusion_of(:calculation_method).in_array(OutcomeCalculationMethod::CALCULATION_METHODS) }

    context 'calculation_int' do

      context 'decaying_average' do
        let(:calculation_method) { 'decaying_average' }
        let(:calculation_int) { 3 }

        it do
          is_expected.to allow_values(
            1,
            20,
            99
          ).for(:calculation_int)
        end
        it do
          is_expected.not_to allow_values(
            -1,
            0,
            100,
            1000,
            nil
          ).for(:calculation_int)
        end
      end

      context 'n_mastery' do
        let(:calculation_method) { 'n_mastery' }
        let(:calculation_int) { 3 }

        it do
          is_expected.to allow_values(
            1,
            4,
            5
          ).for(:calculation_int)
        end
        it do
          is_expected.not_to allow_values(
            -1,
            0,
            6,
            10,
            nil
          ).for(:calculation_int)
        end
      end

      context 'highest' do
        let(:calculation_method) { 'highest' }

        it { is_expected.to allow_value(nil).for(:calculation_int) }
        it { is_expected.not_to allow_values(1, 10, 100).for(:calculation_int) }
      end

      context 'latest' do
        it { is_expected.to allow_value(nil).for(:calculation_int) }
        it { is_expected.not_to allow_values(1, 10, 100).for(:calculation_int) }
      end
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeCalculationMethod }

    let(:creation_arguments) { [creation_params, creation_params.merge(context: course_model)] }
  end
end
