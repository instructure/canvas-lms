# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe Types::OutcomeFriendlyDescriptionType do
  before do
    account_admin_user
  end

  let(:outcome) do
    outcome_model
  end

  let(:description) { "Friendly Description" }
  let(:context) { Account.default }

  let(:outcome_friendly_description) do
    OutcomeFriendlyDescription.create!(
      learning_outcome: outcome,
      context:,
      description:
    )
  end
  let(:graphql_context) { { current_user: @user } }
  let(:outcome_friendly_description_type) { GraphQLTypeTester.new(outcome_friendly_description, graphql_context) }

  it "works" do
    expect(
      outcome_friendly_description_type.resolve("_id")
    ).to eq outcome_friendly_description.id.to_s
  end

  describe "works for the field" do
    it "learning_outcome_id" do
      expect(
        outcome_friendly_description_type.resolve("learningOutcomeId")
      ).to eq outcome.id.to_s
    end

    it "context_id" do
      expect(
        outcome_friendly_description_type.resolve("contextId")
      ).to eq Account.default.id.to_s
    end

    it "context_type" do
      expect(
        outcome_friendly_description_type.resolve("contextType")
      ).to eq "Account"
    end

    it "description" do
      expect(
        outcome_friendly_description_type.resolve("description")
      ).to eq description
    end

    it "workflowState" do
      expect(
        outcome_friendly_description_type.resolve("workflowState")
      ).to eq "active"
    end
  end

  context "without permission" do
    let(:graphql_context) { {} }

    it "returns nil" do
      expect(
        outcome_friendly_description_type.resolve("_id")
      ).to be_nil
    end
  end
end
