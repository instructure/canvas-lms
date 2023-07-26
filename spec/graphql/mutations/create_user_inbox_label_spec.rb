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

describe Mutations::CreateUserInboxLabel do
  before do
    @account = Account.default
    @user = user_factory
  end

  def run_mutation(names)
    mutation_str = <<~GQL
      mutation CreateUserInboxLabel {
        createUserInboxLabel(input: {names: #{names}}) {
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

  it "creates a new inbox label" do
    result = run_mutation(["New Label 1", "New Label 2"])
    expect(result["data"]["createUserInboxLabel"]["errors"]).to be_nil
    expect(result["data"]["createUserInboxLabel"]["inboxLabels"]).to eq(["New Label 1", "New Label 2"])
  end

  describe "gets an error" do
    it "when trying to repeat label name" do
      run_mutation(["New Label 1", "New Label 2"])
      result = run_mutation(["New Label 1"])
      expect(result["data"]["createUserInboxLabel"]["errors"][0]["message"]).to eq("Invalid label name. It already exists.")
      expect(result["data"]["createUserInboxLabel"]["inboxLabels"]).to be_nil
    end

    it "when trying to leave the label name blank" do
      result = run_mutation([""])
      expect(result["data"]["createUserInboxLabel"]["errors"][0]["message"]).to eq("Invalid label name. It cannot be blank.")
      expect(result["data"]["createUserInboxLabel"]["inboxLabels"]).to be_nil
    end
  end
end
