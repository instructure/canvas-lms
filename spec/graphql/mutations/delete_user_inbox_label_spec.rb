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

describe Mutations::DeleteUserInboxLabel do
  before do
    @account = Account.default
    @user = user_factory
    @user.preferences[:inbox_labels] = ["Test 1", "Test 2", "Test 3"]
    @user.save!
  end

  def run_mutation(names)
    mutation_str = <<~GQL
      mutation DeleteUserInboxLabel {
        deleteUserInboxLabel(input: {names: #{names}}) {
          errors {
            message
          }
          inboxLabels
        }
      }
    GQL
    context = { current_user: @user, request: ActionDispatch::TestRequest.create }

    CanvasSchema.execute(mutation_str, context:)
  end

  it "deletes an inbox label" do
    result = run_mutation(["Test 1", "Test 2"])
    expect(result["data"]["deleteUserInboxLabel"]["errors"]).to be_nil
    expect(result["data"]["deleteUserInboxLabel"]["inboxLabels"]).to eq(["Test 3"])
  end

  describe "gets an error" do
    it "when trying a non existent label name" do
      result = run_mutation(["Test 4"])
      expect(result["data"]["deleteUserInboxLabel"]["errors"][0]["message"]).to eq("Invalid label name. It doesn't exist.")
      expect(result["data"]["deleteUserInboxLabel"]["inboxLabels"]).to be_nil
    end

    it "when trying to leave the label name blank" do
      result = run_mutation([""])
      expect(result["data"]["deleteUserInboxLabel"]["errors"][0]["message"]).to eq("Invalid label name. It cannot be blank.")
      expect(result["data"]["deleteUserInboxLabel"]["inboxLabels"]).to be_nil
    end
  end
end
