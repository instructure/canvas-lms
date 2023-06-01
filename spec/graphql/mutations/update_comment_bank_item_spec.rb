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

describe Mutations::UpdateCommentBankItem do
  before :once do
    course_with_student
    @admin = account_admin_user(account: @account)
    @comment = comment_bank_item_model({ course: @course, user: @admin })
  end

  def execute_with_input(update_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        updateCommentBankItem(input: {
          #{update_input}
        }) {
          commentBankItem {
            _id
            courseId
            comment
            userId
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

  it "updates a comment bank item" do
    query = <<~GQL
      id: #{@comment.id}
      comment: "updated comment!"
    GQL
    result = execute_with_input(query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateCommentBankItem", "errors")).to be_nil
    result = result.dig("data", "updateCommentBankItem", "commentBankItem")
    expect(result["courseId"]).to eq @course.id.to_s
    expect(result["userId"]).to eq @admin.id.to_s
    expect(result["comment"]).to eq "updated comment!"
  end

  it "allows relay id for comment bank item id" do
    query = <<~GQL
      id: #{GraphQLHelpers.relay_or_legacy_id_prepare_func("CommentBankItem").call(@comment.id.to_s)},
      comment: "updated comment!"
    GQL
    comment = execute_with_input(query).dig("data", "updateCommentBankItem", "commentBankItem", "comment")
    expect(comment).to eq "updated comment!"
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateCommentBankItem", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "invalid id" do
      query = <<~GQL
        id: 0,
        comment: "comment"
      GQL
      result = execute_with_input(query)
      expect_error(result, "Record not found")
    end

    it "blank comment field" do
      query = <<~GQL
        id: #{@comment.id},
        comment: ""
      GQL
      result = execute_with_input(query)
      expect_error(result, "is too short")
    end

    it "missing comment field" do
      query = <<~GQL
        id: #{@comment.id}
      GQL
      result = execute_with_input(query)
      expect_error(result, "Argument 'comment' on InputObject 'UpdateCommentBankItemInput' is required.")
    end

    it "invalid permissions" do
      query = <<~GQL
        id: #{@comment.id},
        comment: "comment"
      GQL
      result = execute_with_input(query, user_executing: @student)
      expect_error(result, "not found")
    end
  end
end
