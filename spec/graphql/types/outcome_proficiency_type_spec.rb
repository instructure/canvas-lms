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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::OutcomeProficiencyType do
  before(:once) do
    teacher_in_course(active_all: true)
    @outcome_proficiency = outcome_proficiency_model(account)
  end

  let(:account) { @course.root_account }
  let(:account_type) { GraphQLTypeTester.new(account, current_user: @teacher) }

  it "works" do
    expect(
      account_type.resolve("outcomeProficiency { _id }")
    ).to eq @outcome_proficiency.id.to_s
  end

  describe "works for the field" do
    it "proficiencyRatingsConnection" do
      expect(
        account_type.resolve("outcomeProficiency { proficiencyRatingsConnection { nodes { _id } } }").sort
      ).to eq(@outcome_proficiency.outcome_proficiency_ratings.map { |r| r.id.to_s })
    end
  end
end
