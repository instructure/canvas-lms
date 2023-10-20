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

describe Mutations::SetFriendlyDescription do
  def mutation_str(description:, outcome_id:, context_id:, context_type:)
    <<~GQL
      mutation {
        setFriendlyDescription(input: {
          description: "#{description}",
          outcomeId: #{outcome_id},
          contextId: #{context_id},
          contextType: "#{context_type}"
        }) {
          outcomeFriendlyDescription {
            _id
            description
            workflowState
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

  def exec(attrs = {})
    attrs = attrs.reverse_merge({
                                  description:,
                                  outcome_id: outcome.id,
                                  context_id: context.id,
                                  context_type: context.class.name,
                                })

    execute_query(mutation_str(**attrs), ctx)
  end

  let(:ctx) { { current_user: } }
  let(:description) { "This is a friendly Description" }
  let(:outcome) { outcome_model }
  let(:context) { @course }
  let(:current_user) { @teacher }

  before do
    course_with_teacher
  end

  def expect_error(result, message)
    errors = result["errors"]
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to match(/#{message}/)
  end

  def res_field(result, field)
    result.dig(*[
      "data", "setFriendlyDescription", "outcomeFriendlyDescription", field
    ].flatten)
  end

  context "passing description" do
    it "creates description if not on database" do
      result = exec
      expect(res_field(result, "_id")).to be_present
      expect(res_field(result, "description")).to eql(description)
      expect(res_field(result, "workflowState")).to eql("active")
    end

    it "updates description if on database" do
      friendly_description = OutcomeFriendlyDescription.create!(
        learning_outcome: outcome,
        context: @course,
        description: "Some description"
      )
      result = exec
      expect(res_field(result, "_id")).to eql(friendly_description.id.to_s)
      friendly_description.reload
      expect(friendly_description.description).to eql(description)
    end

    it "updates description correctly if on database but destroyed" do
      friendly_description = OutcomeFriendlyDescription.create!(
        learning_outcome: outcome,
        context: @course,
        description: "Some description"
      )
      friendly_description.destroy
      expect(friendly_description.workflow_state).to eql("deleted")
      result = exec
      expect(res_field(result, "_id")).to eql(friendly_description.id.to_s)
      friendly_description.reload
      expect(friendly_description.workflow_state).to eql("active")
      expect(friendly_description.description).to eql(description)
    end
  end

  context "passing empty string" do
    it "destroy description on database" do
      friendly_description = OutcomeFriendlyDescription.create!(
        learning_outcome: outcome,
        context: @course,
        description: "Some description"
      )
      result = exec({ description: "" })
      expect(res_field(result, "_id")).to eql(friendly_description.id.to_s)
      expect(res_field(result, "workflowState")).to eql("deleted")
      expect(res_field(result, "description")).to eql("")
      friendly_description.reload
      expect(friendly_description.workflow_state).to eql("deleted")
    end

    it "do nothing when there isn't friendly description on database" do
      result = nil
      expect do
        result = exec({ description: "" })
      end.not_to change(OutcomeFriendlyDescription, :count)

      expect(res_field(result, "_id")).to be_nil
    end

    it "do nothing when there is a soft deleted friendly description on database" do
      friendly_description = OutcomeFriendlyDescription.create!(
        learning_outcome: outcome,
        context: @course,
        description: "Some description"
      )
      friendly_description.destroy
      result = nil
      expect do
        result = exec({ description: "" })
      end.not_to change(OutcomeFriendlyDescription, :count)

      expect(res_field(result, "_id")).to eql(friendly_description.id.to_s)
      friendly_description.reload
      expect(friendly_description.workflow_state).to eql("deleted")
    end
  end

  context "validations!" do
    it "validates required fields" do
      mutation_str = <<~GQL
        mutation {
          setFriendlyDescription(input: {}) {
            outcomeFriendlyDescription {
              _id
              description
            }
            errors {
              attribute
              message
            }
          }
        }
      GQL
      result = execute_query(mutation_str, ctx)
      expect(result["errors"].pluck("message")).to eql([
                                                         "Argument 'description' on InputObject 'SetFriendlyDescriptionInput' is required. Expected type String!",
                                                         "Argument 'outcomeId' on InputObject 'SetFriendlyDescriptionInput' is required. Expected type ID!",
                                                         "Argument 'contextId' on InputObject 'SetFriendlyDescriptionInput' is required. Expected type ID!",
                                                         "Argument 'contextType' on InputObject 'SetFriendlyDescriptionInput' is required. Expected type String!"
                                                       ])
    end

    it "returns error when pass invalid context type" do
      result = exec({ context_type: "Foo" })
      expect_error(result, "Invalid context type")
    end

    it "returns error when context isn't on database" do
      result = exec({ context_id: "0" })
      expect_error(result, "No such context for Course#0")
    end

    context "without manage_outcomes permission" do
      before do
        student_in_course
      end

      let(:current_user) { @student }

      it "returns error" do
        result = exec
        expect_error(result, "not found")
      end
    end

    it "return error when outcome isn't available in context" do
      course2 = Course.create!(name: "Second", account: Account.default)
      course2_group = outcome_group_model(context: course2)
      course2_outcome = outcome_model(context: course2, outcome_group: course2_group)
      result = exec(outcome_id: course2_outcome.id)
      expect_error(result, "Outcome #{course2_outcome.id} is not available in context Course##{context.id}")
    end

    it "return error when outcome isn't on database" do
      result = exec(outcome_id: 0)
      expect_error(result, "No such outcome for id 0")
    end
  end
end
