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

describe Mutations::CreateCommentBankItem do
  before :once do
    course_with_student
    @admin = account_admin_user(account: @account)
  end

  def execute_with_input(create_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        createCommentBankItem(input: {
          #{create_input}
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

  let(:valid_query) do
    <<~GQL
      courseId: #{@course.id}
      comment: "this is my assignment comment"
    GQL
  end

  it "creates a comment bank item for the current_user" do
    result = execute_with_input(valid_query)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createCommentBankItem", "errors")).to be_nil
    result = result.dig("data", "createCommentBankItem", "commentBankItem")
    record = CommentBankItem.find(result["_id"])
    expect(result["courseId"]).to eq @course.id.to_s
    expect(result["userId"]).to eq @admin.id.to_s
    expect(result["comment"]).to eq record.comment
  end

  it "allows relay id for course_id" do
    query = <<~GQL
      courseId: #{GraphQLHelpers.relay_or_legacy_id_prepare_func("Course").call(@course.id.to_s)},
      comment: "assignment comment"
    GQL
    courseId = execute_with_input(query).dig("data", "createCommentBankItem", "commentBankItem", "courseId")
    expect(courseId).to eq @course.id.to_s
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createCommentBankItem", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "invalid course id" do
      query = <<~GQL
        courseId: 0,
        comment: "comment"
      GQL
      result = execute_with_input(query)
      expect_error(result, "Course not found")
    end

    it "inactive course" do
      @course.destroy
      result = execute_with_input(valid_query)
      expect_error(result, "Course not found")
    end

    it "invalid permissions" do
      query = <<~GQL
        courseId: #{@course.id},
        comment: "comment"
      GQL
      result = execute_with_input(query, user_executing: @student)
      expect_error(result, "not found")
    end
  end
end
