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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::DeleteCommentBankItem do
  before :once do
    course_with_teacher(active_all: true)
    @comment_bank_item = comment_bank_item_model(course: @course, user: @teacher)
  end

  def execute_with_input(delete_input, user_executing: @teacher)
    mutation_command = <<~GQL
      mutation {
        deleteCommentBankItem(input: {
          #{delete_input}
        }) {
          commentBankItemId
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, deleted_models: {}, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "deletes a comment bank item with legacy id" do
    query = <<~GQL
      id: #{@comment_bank_item.id}
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteCommentBankItem", "errors")).to be_nil
    expect(result.dig("data", "deleteCommentBankItem", "commentBankItemId")).to eq @comment_bank_item.id.to_s
  end

  it "deletes a comment bank item with relay id" do
    query = <<~GQL
      id: #{GraphQLHelpers.relay_or_legacy_id_prepare_func("CommentBankItem").call(@comment_bank_item.id.to_s)}
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteCommentBankItem", "errors")).to be_nil
    expect(result.dig("data", "deleteCommentBankItem", "commentBankItemId")).to eq @comment_bank_item.id.to_s
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteCommentBankItem", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "requires delete permission" do
      query = <<~GQL
        id: #{@comment_bank_item.id}
      GQL
      result = execute_with_input(query, user_executing: user_model)
      expect_error(result, "not found")
    end

    it "invalid id" do
      query = <<~GQL
        id: 0
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find CommentBankItem")
    end

    it "does not destroy a record twice" do
      @comment_bank_item.destroy
      query = <<~GQL
        id: #{@comment_bank_item.id}
      GQL
      result = execute_with_input(query)
      expect_error(result, "Unable to find CommentBankItem")
    end
  end
end
