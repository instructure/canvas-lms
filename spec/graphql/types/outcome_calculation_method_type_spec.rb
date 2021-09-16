# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative "../graphql_spec_helper"

describe Types::OutcomeCalculationMethodType do
  before(:once) do
    teacher_in_course(active_all: true)
    outcome_calculation_method_model(account)
  end

  let(:account) { @course.root_account }
  let(:account_type) { GraphQLTypeTester.new(account, current_user: @teacher) }

  it 'works' do
    expect(
      account_type.resolve('outcomeCalculationMethod { _id }')
    ).to eq account.outcome_calculation_method.id.to_s
  end

  describe 'works for the field' do
    it 'calculation_method' do
      expect(
        account_type.resolve('outcomeCalculationMethod { calculationMethod }')
      ).to eq account.outcome_calculation_method.calculation_method
    end

    it 'calculation_int' do
      expect(
        account_type.resolve('outcomeCalculationMethod { calculationInt }')
      ).to eq account.outcome_calculation_method.calculation_int
    end

    it 'context_type' do
      expect(
        account_type.resolve('outcomeCalculationMethod { contextType }')
      ).to eq account.outcome_calculation_method.context_type
    end

    it 'context_id' do
      expect(
        account_type.resolve('outcomeCalculationMethod { contextId }')
      ).to eq account.outcome_calculation_method.context_id
    end
  end
end
