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

describe Types::ProficiencyRatingType do
  before(:once) do
    teacher_in_course(active_all: true)
    outcome_proficiency_model(account)
    @ratings = OutcomeProficiencyRating.all
  end

  let(:account) { @course.root_account }
  let(:account_type) { GraphQLTypeTester.new(account, current_user: @teacher) }

  it 'works' do
    expect(
      account_type.resolve('outcomeProficiency { proficiencyRatingsConnection { nodes { _id } } }').sort
    ).to eq @ratings.map { |r| r.id.to_s }.sort
  end

  describe 'works for the field' do
    it 'color' do
      expect(
        account_type.resolve('outcomeProficiency { proficiencyRatingsConnection { nodes { color } } }').sort
      ).to eq @ratings.map(&:color).sort
    end

    it 'description' do
      expect(
        account_type.resolve('outcomeProficiency { proficiencyRatingsConnection { nodes { description } } }').sort
      ).to eq @ratings.map(&:description).sort
    end

    it 'mastery' do
      expect(
        account_type.resolve('outcomeProficiency { proficiencyRatingsConnection { nodes { mastery } } }')
      ).to eq @ratings.map(&:mastery)
    end

    it 'points' do
      expect(
        account_type.resolve('outcomeProficiency { proficiencyRatingsConnection { nodes { points } } }').sort
      ).to eq @ratings.map(&:points).sort
    end
  end
end
