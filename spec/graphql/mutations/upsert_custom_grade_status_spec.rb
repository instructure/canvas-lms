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

describe Mutations::UpsertCustomGradeStatus do
  before :once do
    teacher_in_course(active_all: true)
    @admin = account_admin_user(account: @account)
  end

  def execute_with_input(upsert_input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        upsertCustomGradeStatus(input: {
          #{upsert_input}
        }) {
          customGradeStatus {
            _id
            name
            color
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = {
      current_user: user_executing,
      domain_root_account: @course.root_account,
      request: ActionDispatch::TestRequest.create,
      session: {},
    }
    CanvasSchema.execute(mutation_command, context:)
  end

  let(:create_query) do
    <<~GQL
      name: "Test Status"
      color: "#000000"
    GQL
  end

  let(:update_query) do
    <<~GQL
      id: #{CustomGradeStatus.first.id}
      name: "Updated Status"
      color: "#FFFFFF"
    GQL
  end

  context "as an admin" do
    it "creates a custom grade status for the current_user" do
      result = execute_with_input(create_query)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "upsertCustomGradeStatus", "errors")).to be_nil
      result = result.dig("data", "upsertCustomGradeStatus", "customGradeStatus")
      expect(result["name"]).to eq "Test Status"
      expect(result["color"]).to eq "#000000"
      expect(result["_id"]).to be_present
    end

    it "updates a custom grade status for the current_user" do
      CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin)
      result = execute_with_input(update_query)
      expect(result["errors"]).to be_nil
      expect(result.dig("data", "upsertCustomGradeStatus", "errors")).to be_nil
      result = result.dig("data", "upsertCustomGradeStatus", "customGradeStatus")
      expect(result["name"]).to eq "Updated Status"
      expect(result["color"]).to eq "#FFFFFF"
      expect(result["_id"]).to eq CustomGradeStatus.first.id.to_s
    end

    it "does not find a custom grade status for another account" do
      new_account = Account.create!
      new_admin = account_admin_user(account: new_account)
      CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: new_account, created_by: new_admin)
      result = execute_with_input(update_query)
      expect(result.dig("errors", 0, "message")).to eq "custom grade status not found"
    end
  end

  context "as a non-admin" do
    it "does not allow creating a custom grade status" do
      result = execute_with_input(create_query, user_executing: @teacher)
      expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
    end

    it "does not allow updating a custom grade status" do
      CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin)
      result = execute_with_input(update_query, user_executing: @teacher)
      expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
    end
  end

  context "errors -" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "upsertCustomGradeStatus", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end
    context "create:" do
      it "blank name" do
        query = <<~GQL
          name: ""
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect_error(result, "can't be blank")
      end

      it "name longer than 14 characters" do
        query = <<~GQL
          name: "abcdefghijklmno"
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect_error(result, "is too long")
      end

      it "invalid color" do
        query = <<~GQL
          name: "Test Status"
          color: "#ghijkl"
        GQL
        result = execute_with_input(query)
        expect_error(result, "is invalid")
      end

      it "feature flag disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        result = execute_with_input(create_query)
        expect(result["errors"]).not_to be_nil
        expect(result.dig("data", "upsertCustomGradeStatus")).to be_nil
        expect(result["errors"][0]["message"]).to eq("custom gradebook statuses feature flag is disabled")
      end
    end

    context "update:" do
      let(:custom_grade_status) { CustomGradeStatus.create(name: "Test Status", color: "#000000", root_account: @course.root_account, created_by: @admin) }

      it "blank name" do
        query = <<~GQL
          id: #{custom_grade_status.id}
          name: ""
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect_error(result, "can't be blank")
      end

      it "name longer than 14 characters" do
        query = <<~GQL
          id: #{custom_grade_status.id}
          name: "abcdefghijklmno"
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect_error(result, "is too long")
      end

      it "invalid color" do
        query = <<~GQL
          id: #{custom_grade_status.id}
          name: "Test Status"
          color: "#ghijkl"
        GQL
        result = execute_with_input(query)
        expect_error(result, "is invalid")
      end

      it "invalid id" do
        query = <<~GQL
          id: 0
          name: "Test Status"
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect_error(result, "custom grade status not found")
      end

      it "feature flag disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        query = <<~GQL
          id: #{custom_grade_status.id}
          name: "Test Status"
          color: "#000000"
        GQL
        result = execute_with_input(query)
        expect(result["errors"]).not_to be_nil
        expect(result.dig("data", "upsertCustomGradeStatus")).to be_nil
        expect(result["errors"][0]["message"]).to eq("custom gradebook statuses feature flag is disabled")
      end
    end
  end
end
