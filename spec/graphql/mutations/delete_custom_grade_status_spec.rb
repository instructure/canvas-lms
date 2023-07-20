# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Mutations::DeleteCustomGradeStatus do
  before :once do
    teacher_in_course(active_all: true)
    @admin = account_admin_user(account: @account)
  end

  def execute_with_input(delete_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        deleteCustomGradeStatus(input: {
          #{delete_input}
        }) {
          customGradeStatusId
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

  let(:delete_query) do
    <<~GQL
      id: #{CustomGradeStatus.first.id}
    GQL
  end

  it "deletes an existing custom grade status" do
    CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin)
    id = CustomGradeStatus.first.id
    result = execute_with_input(delete_query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus", "errors")).to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus", "customGradeStatusId")).to eq id.to_s
  end

  it "does not allow admins to delete statuses from other accounts" do
    CustomGradeStatus.create!(name: "Test Status", color: "#000000", root_account: Account.create!, created_by: @admin).id
    result = execute_with_input(delete_query)
    expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
  end

  it "does not allow non-admins to delete" do
    CustomGradeStatus.create!(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin).id
    result = execute_with_input(delete_query, user_executing: @teacher)
    expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
  end

  it "returns an error if the custom grade status does not exist" do
    query = <<~GQL
      id: 0
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).not_to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus")).to be_nil
    expect(result["errors"][0]["message"]).to eq("custom grade status not found")
  end

  it "returns an error if the same status tries to be deleted twice" do
    CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin)
    id = CustomGradeStatus.first.id
    result = execute_with_input(delete_query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus", "errors")).to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus", "customGradeStatusId")).to eq id.to_s
    result = execute_with_input(delete_query)
    expect(result["errors"]).not_to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus")).to be_nil
    expect(result["errors"][0]["message"]).to eq("custom grade status not found")
  end

  it "doesn't allow the mutation to be called if the feature flag is disabled" do
    CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin)
    Account.site_admin.disable_feature!(:custom_gradebook_statuses)
    result = execute_with_input(delete_query)
    expect(result["errors"]).not_to be_nil
    expect(result.dig("data", "deleteCustomGradeStatus")).to be_nil
    expect(result["errors"][0]["message"]).to eq("custom gradebook statuses feature flag is disabled")
  end
end
