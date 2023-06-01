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

describe Mutations::DeleteOutcomeLinks do
  before :once do
    course_with_teacher
    @site_admin = site_admin_user
    @admin = account_admin_user(account: @account)
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @global_group = LearningOutcomeGroup.create(title: "global group")
    @global_outcome = outcome_model(outcome_group: @global_group, title: "global outcome")
    @global_outcome_link = ContentTag.find_by(content_id: @global_outcome.id)
    @group = @course.learning_outcome_groups.create!(title: "group")
    outcome1 = @course.created_learning_outcomes.create!(title: "outcome")
    outcome2 = @course.created_learning_outcomes.create!(title: "aligned outcome")
    outcome2.align(@course.assessment_question_banks.create!, @course, mastery_type: "none")
    @group.add_outcome outcome1
    @group.add_outcome outcome2
    @outcome_link1 = @group.child_outcome_links.find_by(content_id: outcome1.id)
    @outcome_link2 = @group.child_outcome_links.find_by(content_id: outcome2.id)
  end

  def variables(args = {})
    <<~YAML
      ids: #{args[:ids] || [@outcome_link1.id]}
    YAML
  end

  def execute_with_input(input, user_executing: @admin)
    mutation_command = <<~GQL
      mutation {
        deleteOutcomeLinks(
          input: {
            #{input}
          }
          ) {
          deletedOutcomeLinkIds
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, session: {}, deleted_models: {} }
    CanvasSchema.execute(mutation_command, context:)
  end

  context "Mutation" do
    it "deletes outcome link if user has manage_outcomes permission" do
      result = execute_with_input(variables)
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      errors = result.dig("data", "deleteOutcomeLinks", "errors")
      expect(errors).to be_empty
      expect(data).to eq [@outcome_link1.id.to_s]
      expect(@group.child_outcome_links.active.size).to eq 1
    end

    it "deletes global outcome link if user has manage_global_outcomes permission" do
      result = execute_with_input(variables({ ids: [@global_outcome_link.id] }), user_executing: @site_admin)
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      errors = result.dig("data", "deleteOutcomeLinks", "errors")
      expect(errors).to be_empty
      expect(data).to eq [@global_outcome_link.id.to_s]
      expect(@global_group.child_outcome_links.active.size).to eq 0
    end
  end

  context "Error" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteOutcomeLinks", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(message)
    end

    it "fails to delete outcome link if user does not have manage_outcomes permission" do
      result = execute_with_input(variables, user_executing: @student)
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      expect_error(result, "Insufficient permissions")
      expect(data).to be_empty
      expect(@group.child_outcome_links.active.size).to eq 2
    end

    it "fails to delete global outcome link if user does not have manage_global_outcomes permission" do
      result = execute_with_input(variables({ ids: [@global_outcome_link.id] }), user_executing: @teacher)
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      expect_error(result, "Insufficient permissions")
      expect(data).to be_empty
      expect(@global_group.child_outcome_links.active.size).to eq 1
    end

    it "fails to delete outcome link if link id is not provided" do
      result = execute_with_input("")
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      expect_error(result, "Argument 'ids' on InputObject 'DeleteOutcomeLinksInput' is required. Expected type [ID!]!")
      expect(data).to be_nil
      expect(@group.child_outcome_links.active.size).to eq 2
    end

    it "fails to delete outcome link if outcome is aligned to content" do
      result = execute_with_input(variables({ ids: [@outcome_link2.id] }))
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      expect_error(result, /cannot be deleted because it is aligned to content/)
      expect(data).to be_empty
      expect(@group.child_outcome_links.active.size).to eq 2
    end

    it "fails to delete outcome link if link id is invalid" do
      result = execute_with_input(variables({ ids: [123_456_789] }))
      data = result.dig("data", "deleteOutcomeLinks", "deletedOutcomeLinkIds")
      expect_error(result, "Could not find outcome link")
      expect(data).to be_empty
      expect(@group.child_outcome_links.active.size).to eq 2
    end
  end
end
