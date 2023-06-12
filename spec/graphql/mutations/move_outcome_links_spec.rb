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

describe Mutations::MoveOutcomeLinks do
  include GraphQLSpecHelper
  before(:once) do
    @site_admin = site_admin_user
    course_with_teacher
    @context = @course
    @source_group = outcome_group_model
    @destination_group = outcome_group_model

    # belonging to other account
    @other_account = account_model
    @group_without_permission = outcome_group_model(context: @other_account)
    @outcome_other_context = outcome_model(context: @other_account)
    @outcome_other_context_link = @other_account.root_outcome_group.child_outcome_links.first

    # global groups
    @global_source = LearningOutcomeGroup.create!(title: "source")
    @global_destination = LearningOutcomeGroup.create!(title: "destination")
    outcome_model(outcome_group: @global_source, global: true)
    @global_link = @global_source.child_outcome_links.first
  end

  before do
    outcome_model(outcome_group: @source_group)
    @outcome_link = @source_group.child_outcome_links.first
  end

  def mutation_str(**attrs)
    <<~GQL
      mutation {
        moveOutcomeLinks(input: {
          #{gql_arguments("", **attrs)}
        }) {
          movedOutcomeLinks {
            _id
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

  it "moves the outcome links" do
    execute_query(
      mutation_str(
        group_id: @destination_group.id,
        outcome_link_ids: [@outcome_link.id]
      ),
      {
        current_user: @teacher
      }
    )

    @outcome_link.reload
    expect(@outcome_link.associated_asset).to eql(@destination_group)
  end

  it "moves only outcomes in the same context and return errors for outcomes in different context" do
    response = execute_query(
      mutation_str(
        group_id: @destination_group.id,
        outcome_link_ids: [@outcome_link.id, @outcome_other_context_link.id]
      ),
      {
        current_user: @teacher
      }
    )
    moved_links = response.dig("data", "moveOutcomeLinks", "movedOutcomeLinks").pluck("_id")
    expect(moved_links).to eql([@outcome_link.id.to_s])
    expect(response.dig("data", "moveOutcomeLinks", "errors")).to match_array([
                                                                                { "attribute" => @outcome_other_context_link.id.to_s, "message" => "Could not find associated outcome in this context" }
                                                                              ])
  end

  it "touches parent group" do
    prev_updated_at = @course.root_outcome_group.updated_at
    execute_query(
      mutation_str(
        group_id: @destination_group.id,
        outcome_link_ids: [@outcome_link.id]
      ),
      {
        current_user: @teacher
      }
    )
    expect(@course.root_outcome_group.updated_at).to be > prev_updated_at
  end

  it "writes group to context" do
    context = {
      current_user: @teacher
    }

    execute_query(
      mutation_str(
        group_id: @destination_group.id,
        outcome_link_ids: [@outcome_link.id]
      ),
      context
    )

    expect(context[:group]).to eql(@destination_group)
  end

  describe "global groups" do
    it "allows global links to be moved" do
      execute_query(
        mutation_str(
          group_id: @global_destination.id,
          outcome_link_ids: [@global_link.id]
        ),
        {
          current_user: @site_admin
        }
      )
      @global_link.reload
      expect(@global_link.associated_asset).to eql(@global_destination)
    end
  end

  context "errors" do
    it "validates required attributes" do
      response = execute_query(mutation_str, {})

      expect(response["errors"][0]["message"]).to eql(
        "Argument 'outcomeLinkIds' on InputObject 'MoveOutcomeLinksInput' is required. Expected type [ID!]!"
      )
      expect(response["errors"][1]["message"]).to eql(
        "Argument 'groupId' on InputObject 'MoveOutcomeLinksInput' is required. Expected type ID!"
      )
    end

    it "validates group not exist" do
      response = execute_query(mutation_str(group_id: 123_123, outcome_link_ids: []), {})
      expect(response["errors"][0]["message"]).to eql(
        "Group not found"
      )
    end

    it "validates when user doesn't have permission to manage the group" do
      response = execute_query(mutation_str(group_id: @group_without_permission.id, outcome_link_ids: []), {})
      expect(response["errors"][0]["message"]).to eql(
        "Insufficient permission"
      )
    end

    it "validates when user doesn't have permission to manage global outcomes" do
      response = execute_query(
        mutation_str(
          group_id: @global_destination.id,
          outcome_link_ids: [@global_link.id]
        ),
        {
          current_user: @teacher
        }
      )
      expect(response["errors"][0]["message"]).to eql(
        "Insufficient permission"
      )
    end

    it "validates outcome does not exist" do
      response = execute_query(
        mutation_str(
          group_id: @destination_group.id,
          outcome_link_ids: [123_123]
        ),
        {
          current_user: @teacher
        }
      )

      expect(response.dig("data", "moveOutcomeLinks", "movedOutcomeLinks")).to eql([])
      expect(response.dig("data", "moveOutcomeLinks", "errors")).to match_array([
                                                                                  { "attribute" => "123123", "message" => "Could not find associated outcome in this context" }
                                                                                ])
    end

    it "validates when outcomes exists in different context" do
      response = execute_query(
        mutation_str(
          group_id: @destination_group.id,
          outcome_link_ids: [@outcome_other_context_link.id]
        ),
        {
          current_user: @teacher
        }
      )

      expect(response.dig("data", "moveOutcomeLinks", "movedOutcomeLinks")).to eql([])
      expect(response.dig("data", "moveOutcomeLinks", "errors")).to match_array([
                                                                                  { "attribute" => @outcome_other_context_link.id.to_s, "message" => "Could not find associated outcome in this context" }
                                                                                ])
    end
  end
end
