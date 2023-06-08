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

describe Mutations::DeleteOutcomeProficiency do
  before :once do
    @account = Account.default
    @course = @account.courses.create!
    @admin = account_admin_user(account: @account)
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
  end

  let(:original_record) { outcome_proficiency_model(@account) }

  def execute_with_input(delete_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        deleteOutcomeProficiency(input: {
          #{delete_input}
        }) {
          outcomeProficiencyId
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, deleted_models: {}, request: ActionDispatch::TestRequest.create, session: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "deletes an outcome proficency with legacy id" do
    query = <<~GQL
      id: #{original_record.id}
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteOutcomeProficiency", "errors")).to be_nil
    expect(result.dig("data", "deleteOutcomeProficiency", "outcomeProficiencyId")).to eq original_record.id.to_s
  end

  it "deletes an outcome proficency with relay id" do
    query = <<~GQL
      id: #{GraphQLHelpers.relay_or_legacy_id_prepare_func("OutcomeProficiency").call(original_record.id.to_s)}
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteOutcomeProficiency", "errors")).to be_nil
    expect(result.dig("data", "deleteOutcomeProficiency", "outcomeProficiencyId")).to eq original_record.id.to_s
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteOutcomeProficiency", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "requires manage_proficiency_scales permission" do
      query = <<~GQL
        id: #{original_record.id}
      GQL
      result = execute_with_input(query, user_executing: @teacher)
      expect_error(result, "insufficient permission")
    end

    it "invalid id" do
      query = <<~GQL
        id: 0
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find OutcomeProficiency")
    end

    it "does not delete a record twice" do
      original_record.destroy
      query = <<~GQL
        id: #{original_record.id}
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find OutcomeProficiency")
    end
  end
end
