#
# Copyright (C) 2019 Instructure, Inc.
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

require_relative "../spec_helper"
require_relative "./graphql_spec_helper"

describe "GraphQL Mutation Audit Log" do
  before(:once) do
    course_with_student(active_all: true)
    @assignment = @course.assignments.create! name: "asdf"
    MUTATION = <<~MUTATION
      mutation {
        updateAssignment(input: {id: "#{@assignment.id}"}) {
          assignment { name }
        }
      }
    MUTATION
  end

  before do
    allow(AuditLogFieldExtension).to receive(:enabled?) { true }
  end

  it "logs" do
    expect(AuditLogFieldExtension::Logger).to receive(:log).once
    CanvasSchema.execute(MUTATION, context: {current_user: @teacher})
  end

  it "creates a log for every item" do
    expect(AuditLogFieldExtension::Logger).to receive(:log).twice
    @course.enable_feature! :post_policies

    CanvasSchema.execute(<<~MUTATION, context: {current_user: @teacher})
      mutation {
        hideAssignmentGrades(input: {assignmentId: "#{@assignment.id}"}) {
          assignment { _id }
        }
      }
    MUTATION
  end

  it "doesn't log failed mutations" do
    expect(AuditLogFieldExtension::Logger).not_to receive(:log)
    CanvasSchema.execute(MUTATION, context: {current_user: @student})
  end

  it "fails gracefully (or silently!? when dynamo isn't working" do
    require 'canvas_dynamodb'
    dynamo = CanvasDynamoDB::Database.new("asdf", "asdf", nil,
                                          {region: "us-east-1", endpoint: "http://localhost:8000"},
                                          Rails.logger)
    expect(dynamo).to receive(:put_item).and_raise(Aws::DynamoDB::Errors::ServiceError.new("two", "arguments"))
    allow(Canvas::DynamoDB::DatabaseBuilder).to receive(:from_config).and_return(dynamo)
    response = CanvasSchema.execute(MUTATION, context: {current_user: @teacher})
    expect(response.dig("data", "updateAssignment", "assignment", "name")).to eq "asdf"
    expect(response["error"]).to be_nil
  end
end
