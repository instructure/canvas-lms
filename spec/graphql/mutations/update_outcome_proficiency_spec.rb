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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::UpdateOutcomeProficiency do
  before :once do
    @account = Account.default
    @course = @account.courses.create!
    @admin = account_admin_user(account: @account)
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
  end

  let!(:original_record) { outcome_proficiency_model(@account) }

  let(:good_query) do
    <<~GQL
      id: #{original_record.id}
      proficiencyRatings: [
        {
          color: "FFFFFF"
          description: "white"
          mastery: true
          points: 1.0
        }
      ]
    GQL
  end

  def execute_with_input(update_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        updateOutcomeProficiency(input: {
          #{update_input}
        }) {
          outcomeProficiency {
            _id
            contextId
            contextType
            proficiencyRatingsConnection(first: 10) {
              nodes {
                _id
                color
                description
                mastery
                points
              }
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "updates an outcome proficiency" do
    result = execute_with_input(good_query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateOutcomeProficiency", "errors")).to be_nil
    result = result.dig("data", "updateOutcomeProficiency", "outcomeProficiency")
    ratings = result.dig("proficiencyRatingsConnection", "nodes")
    expect(ratings.length).to eq 1
    expect(ratings[0]["color"]).to eq "FFFFFF"
    expect(ratings[0]["description"]).to eq "white"
    expect(ratings[0]["mastery"]).to be true
    expect(ratings[0]["points"]).to eq 1.0
  end

  it "restores previously soft-deleted record" do
    original_record.destroy
    result = execute_with_input(good_query)
    result = result.dig("data", "updateOutcomeProficiency", "outcomeProficiency")
    record = OutcomeProficiency.find(result["_id"])
    expect(record.id).to eq original_record.id
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateOutcomeCalculationMethod", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "requires manage_proficiency_scales permission" do
      result = execute_with_input(good_query, user_executing: @student)
      expect_error(result, "insufficient permission")
    end
  end
end
