# frozen_string_literal: true

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
require_relative "graphql_spec_helper"

describe AuditLogFieldExtension do
  before do
    unless AuditLogFieldExtension.enabled?
      skip("AuditLog needs to be enabled by configuring dynamodb.yml")
    end
  end

  before(:once) do
    creds = Aws::Credentials.new("key", "secret")
    Canvas::DynamoDB::DevUtils.initialize_ddb_for_development!(:auditors, "graphql_mutations", recreate: true, credentials: creds)
    course_with_student(active_all: true)
    @assignment = @course.assignments.create! name: "asdf"
  end

  let(:mutation) do
    <<~GQL
      mutation {
        updateAssignment(input: {id: "#{@assignment.id}"}) {
          assignment { name }
        }
      }
    GQL
  end

  it "logs" do
    expect_any_instance_of(AuditLogFieldExtension::Logger).to receive(:log).once
    CanvasSchema.execute(mutation, context: { current_user: @teacher })
  end

  it "creates a log for every item" do
    expect_any_instance_of(AuditLogFieldExtension::Logger).to receive(:log).twice

    CanvasSchema.execute(<<~GQL, context: { current_user: @teacher })
      mutation {
        hideAssignmentGrades(input: {assignmentId: "#{@assignment.id}"}) {
          assignment { _id }
        }
      }
    GQL
  end

  it "doesn't log failed mutations" do
    expect_any_instance_of(AuditLogFieldExtension::Logger).not_to receive(:log)
    CanvasSchema.execute(mutation, context: { current_user: @student })
  end

  it "fails gracefully when dynamo isn't working, with captured exception" do
    require "canvas_dynamodb"
    dynamo = CanvasDynamoDB::Database.new(
      "asdf",
      prefix: "asdf",
      client_opts: { region: "us-east-1", endpoint: "http://localhost:8000" },
      logger: Rails.logger
    )
    expect(dynamo).to receive(:put_item).and_raise(Aws::DynamoDB::Errors::ServiceError.new("two", "arguments"))
    expect(Canvas::Errors).to receive(:capture_exception) do |name, e|
      expect(name).to eq(:graphql_mutation_audit_logs)
      expect(e.class).to eq(Aws::DynamoDB::Errors::ServiceError)
    end
    allow(Canvas::DynamoDB::DatabaseBuilder).to receive(:from_config).and_return(dynamo)
    response = CanvasSchema.execute(mutation, context: { current_user: @teacher })
    expect(response.dig("data", "updateAssignment", "assignment", "name")).to eq "asdf"
    expect(response["error"]).to be_nil
  end
end

describe AuditLogFieldExtension::Logger do
  let(:mutation) { double(graphql_name: "asdf") }

  before(:once) do
    WebMock.enable_net_connect!
    creds = Aws::Credentials.new("key", "secret")
    Canvas::DynamoDB::DevUtils.initialize_ddb_for_development!(:auditors, "graphql_mutations", recreate: true, credentials: creds)
    course_with_teacher(active_all: true)
    @entry = @course.assignments.create! name: "asdf"
  end

  it "sanitizes arguments" do
    logger = AuditLogFieldExtension::Logger.new(mutation, {}, { input: { password: "TOP SECRET" } })
    expect(logger.instance_variable_get(:@params)).to eq({ password: "[FILTERED]" })
  end

  it "truncates long text" do
    long_string = "Z" * 500
    shortened_string = "Z" * 256
    logger = AuditLogFieldExtension::Logger.new(mutation, {}, {
                                                  input: {
                                                    string: long_string,
                                                    array: [long_string],
                                                    nested_hash: { a: long_string }
                                                  }
                                                })
    expect(logger.instance_variable_get(:@params)).to eq({
                                                           string: shortened_string,
                                                           array: [shortened_string],
                                                           nested_hash: { a: shortened_string }
                                                         })
  end

  context "#log_entry_ids" do
    it "uses #asset_string and includes the domain_root_account id for the object_id" do
      logger = AuditLogFieldExtension::Logger.new(mutation, {}, { input: {} })
      expect(logger.log_entry_ids(@entry, "some_field")).to eq ["#{@course.root_account.global_id}-assignment_#{@entry.id}"]
    end

    it "allows overriding the logged object" do
      expect(mutation).to receive(:whatever_log_entry) { @entry.context }
      logger = AuditLogFieldExtension::Logger.new(mutation, {}, { input: {} })
      expect(logger.log_entry_ids(@entry, "whatever")).to eq ["#{@course.root_account.global_id}-course_#{@course.id}"]
    end
  end

  it "generates a unique mutation_id for each entry" do
    logger = AuditLogFieldExtension::Logger.new(mutation, { request_id: "REQUEST_ID" }, { input: {} })
    timestamp = logger.instance_variable_get(:@timestamp).to_f
    expect(logger.mutation_id).to eq "#{timestamp}-REQUEST_ID-#1"
    expect(logger.mutation_id).to eq "#{timestamp}-REQUEST_ID-#2"
  end
end
