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

describe Mutations::UpdateLearningOutcomeGroup do
  include GraphQLSpecHelper

  before :once do
    @admin = account_admin_user(account: @account)
    course_with_student
    @old_parent_group = @course.learning_outcome_groups.create!(title: "Old Parent Outcome Group")
    @new_parent_group = @course.learning_outcome_groups.create!(title: "New Parent Outcome Group")
    @group = @course.learning_outcome_groups.create!(title: "Outcome Group", description: "Description", vendor_guid: "vg--0")
    @global_group = LearningOutcomeGroup.create(title: "Global Group")
    @new_parent_global_group = LearningOutcomeGroup.create(title: "New Parent Global Group")
  end

  let(:context) { { current_user: @admin } }

  def mutation_str(**attrs)
    <<~GQL
      mutation {
        updateLearningOutcomeGroup(
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
      it "updates learning outcome group" do
        result = execute_query(
          mutation_str(
            id: @group.id,
            title: "Updated Outcome Group",
            description: "Updated Description",
            vendorGuid: "vg--1",
            parentOutcomeGroupId: @new_parent_group.id
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Updated Outcome Group"
        expect(data["description"]).to eq "Updated Description"
        expect(data["vendorGuid"]).to eq "vg--1"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @new_parent_group.id.to_s
      end

      it "updates title of learning outcome group if only title provided" do
        result = execute_query(
          mutation_str(
            id: @group.id,
            title: "Updated Outcome Group"
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Updated Outcome Group"
        expect(data["description"]).to eq "Description"
        expect(data["vendorGuid"]).to eq "vg--0"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @old_parent_group.id.to_s
      end

      it "updates description of learning outcome group if only description provided" do
        result = execute_query(
          mutation_str(
            id: @group.id,
            description: "Updated Description"
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Outcome Group"
        expect(data["description"]).to eq "Updated Description"
        expect(data["vendorGuid"]).to eq "vg--0"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @old_parent_group.id.to_s
      end

      it "updates vendor_guid of learning outcome group if only vendor_guid provided" do
        result = execute_query(
          mutation_str(
            id: @group.id,
            vendor_guid: "vg--1"
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Outcome Group"
        expect(data["description"]).to eq "Description"
        expect(data["vendorGuid"]).to eq "vg--1"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @old_parent_group.id.to_s
      end

      it "updates parent group of learning outcome group if only new_parent_group_id provided" do
        result = execute_query(
          mutation_str(
            id: @group.id,
            parent_outcome_group_id: @new_parent_group.id
          ),
          context
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Outcome Group"
        expect(data["description"]).to eq "Description"
        expect(data["vendorGuid"]).to eq "vg--0"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @new_parent_group.id.to_s
      end
    end

    context "As user with manage_global_outcomes permission" do
      it "updates global learning outcome group" do
        result = execute_query(
          mutation_str(
            id: @global_group.id,
            title: "Updated Global Outcome Group",
            description: "Updated Description",
            vendorGuid: "vg--1",
            parentOutcomeGroupId: @new_parent_global_group.id
          ),
          { current_user: site_admin_user }
        )
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "updateLearningOutcomeGroup", "errors")).to be_nil
        data = result.dig("data", "updateLearningOutcomeGroup", "learningOutcomeGroup")
        expect(data["title"]).to eq "Updated Global Outcome Group"
        expect(data["description"]).to eq "Updated Description"
        expect(data["vendorGuid"]).to eq "vg--1"
        expect(data["parentOutcomeGroup"]["_id"]).to eq @new_parent_global_group.id.to_s
      end
    end
  end

  context "Errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateLearningOutcomeGroup", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    it "requires outcome group to exist" do
      result = execute_query(mutation_str(id: 99_999), context)
      expect_error(result, "Group not found")
    end

    it "requires parent outcome group to exist if provided" do
      result = execute_query(
        mutation_str(
          id: @group.id,
          parent_outcome_group_id: 99_999
        ),
        context
      )
      expect_error(result, "Parent group not found in this context")
    end

    it "requires parent outcome group to be in the same context as the outcome group" do
      result = execute_query(
        mutation_str(
          id: @group.id,
          parent_outcome_group_id: @global_group.id
        ),
        context
      )
      expect_error(result, "Parent group not found in this context")
    end

    it "requires user to have manage_outcomes permission to update learning outcome group" do
      result = execute_query(
        mutation_str(id: @group.id),
        { current_user: @teacher }
      )
      expect_error(result, "Insufficient permissions")
    end

    it "requires user to have manage_global_outcomes permission to update global learning outcome group" do
      result = execute_query(
        mutation_str(id: @global_group.id),
        context
      )
      expect_error(result, "Insufficient permissions")
    end
  end
end
