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

describe Mutations::CreateLearningOutcomeGroup do
  include GraphQLSpecHelper

  before :once do
    @admin = account_admin_user(account: @account)
    course_with_student
    @parent_group = @course.learning_outcome_groups.create!(title: "Parent Outcome Group")
    @global_parent_group = LearningOutcomeGroup.create(title: "Global Parent Outcome Group")
  end

  let(:context) { { current_user: @admin } }
  let(:title) { "New Group Title" }
  let(:description) { "New Group Description" }
  let(:vendor_guid) { "A001" }

  def mutation_str(**attrs)
    <<~GQL
      mutation {
        createLearningOutcomeGroup(
            input: {
              #{gql_arguments("", **attrs)}
            }
          ) {
          learningOutcomeGroup {
            _id
            title
            description
            vendorGuid
            parentOutcomeGroup {
              _id
              title
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def execute_query(mutation_str, context)
    CanvasSchema.execute(mutation_str, context:)
  end

  context "Mutation" do
    context "As user with manage_outcomes permisssion" do
      it "creates learning outcome group" do
        result = execute_query(
          mutation_str(
            id: @parent_group.id,
            title:,
            description:,
            vendorGuid: vendor_guid
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "createLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "createLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq title
        expect(data["description"]).to eq description
        expect(data["vendorGuid"]).to eq vendor_guid
        expect(data["parentOutcomeGroup"]["_id"]).to eq @parent_group.id.to_s
      end
    end

    context "As user with manage_global_outcomes permission" do
      it "creates global learning outcome group" do
        result = execute_query(
          mutation_str(
            id: @global_parent_group.id,
            title:,
            description:,
            vendorGuid: vendor_guid
          ),
          { current_user: site_admin_user }
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "createLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "createLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq title
        expect(data["description"]).to eq description
        expect(data["vendorGuid"]).to eq vendor_guid
        expect(data["parentOutcomeGroup"]["_id"]).to eq @global_parent_group.id.to_s
      end
    end
  end

  context "Errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createLearningOutcomeGroup", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    it "requires parent outcome group to exist" do
      result = execute_query(mutation_str(id: 99_999, title:), context)
      expect_error(result, "Group not found")
    end

    it "requires title for new outcome group" do
      result = execute_query(mutation_str(id: @parent_group.id), context)
      expect_error(result, "Argument 'title' on InputObject 'CreateLearningOutcomeGroupInput' is required. Expected type String!")
    end

    it "requires user to have manage_outcomes permission to create learning outcome group" do
      result = execute_query(
        mutation_str(id: @parent_group.id, title:),
        { current_user: @teacher }
      )
      expect_error(result, "Insufficient permissions")
    end

    it "requires user to have manage_global_outcomes permission to create global learning outcome group" do
      result = execute_query(
        mutation_str(id: @global_parent_group.id, title:),
        context
      )
      expect_error(result, "Insufficient permissions")
    end
  end
end
