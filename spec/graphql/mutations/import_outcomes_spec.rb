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

describe Mutations::ImportOutcomes do
  def mutation_str(target_context_id:, target_context_type:, **attrs)
    source_context_id = attrs[:source_context_id]
    source_context_type = attrs[:source_context_type]
    outcome_id = attrs[:outcome_id]
    group_id = attrs[:group_id]

    optional_fields = []
    optional_fields << "sourceContextId: #{source_context_id}" if source_context_id
    optional_fields << "sourceContextType: \"#{source_context_type}\"" if source_context_type
    optional_fields << "outcomeId: #{outcome_id}" if outcome_id
    optional_fields << "groupId: \"#{group_id}\"" if group_id

    <<~GQL
      mutation {
        importOutcomes(input: {
          targetContextId: "#{target_context_id}",
          targetContextType: "#{target_context_type}",
          #{optional_fields.join(",\n")}
        }) {
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def execute_query(query, context)
    CanvasSchema.execute(query, context: context)
  end

  def exec_graphql(**attrs)
    execute_query(
      mutation_str(
        **attrs.reverse_merge(
          target_context_id: target_context_id,
          target_context_type: target_context_type,
          source_context_id: source_context_id,
          source_context_type: source_context_type
        )
      ),
      ctx
    )
  end

  def exec(**attrs)
    attrs.reverse_merge!(
      target_context_id: target_context_id,
      target_context_type: target_context_type,
      source_context_id: source_context_id,
      source_context_type: source_context_type
    )
    described_class.execute(progress, attrs)
  end

  def make_group(group_attrs, context, parent_group = nil)
    outcomes = group_attrs.delete(:outcomes) || 0
    groups = group_attrs.delete(:groups)

    create_group_attrs = {
      context: context,
      **group_attrs
    }

    create_group_attrs[:outcome_group_id] = parent_group&.id if parent_group&.id

    group = outcome_group_model(create_group_attrs)

    outcomes.times.each do |c|
      outcome_model(
        title: "#{c} #{group_attrs[:title]} outcome",
        outcome_group: group,
        context: context
      )
    end

    groups&.each do |child|
      make_group(child, context, group)
    end
  end

  def find_group(title)
    LearningOutcomeGroup.find_by(title: title)
  end

  def get_outcome_id(title, context = Account.default)
    LearningOutcome.find_by(context: context, short_description: title).id
  end

  let(:target_context_id) { @course.id }
  let(:target_context_type) { "Course" }
  let(:source_context_id) { Account.default.id }
  let(:source_context_type) { "Account" }
  let(:ctx) { { domain_root_account: Account.default, current_user: current_user } }
  let(:current_user) { @teacher }

  before do
    Account.default.enable_feature!(:improved_outcomes_management)
    course_with_teacher
    make_group({
      title: "Group A",
      outcomes: 5,
      groups: [{
        title: "Group C",
        outcomes: 3,
        groups: [{
          title: "Group D",
          outcomes: 5
        }, {
          title: "Group E",
          outcomes: 5
        }]
      }]
    }, Account.default)

    make_group({
      title: "Group B",
      outcomes: 5
    }, Account.default)
  end

  context "imports outcomes" do
    it "does not generate an error" do
      result = exec_graphql(outcome_id: get_outcome_id(
        "0 Group E outcome"
      ))
      errors = result.dig('data', 'importOutcomes', 'errors')
      expect(errors).to be_nil
    end
  end

  context "errors" do
    before :once do
      @course2 = Course.create!(name: "Second", account: Account.default)
      @course2_group = outcome_group_model(context: @course2)
      @course2_outcome = outcome_model(context: @course2, outcome_group: @course2_group)
    end

    def expect_validation_error(result, attribute, message)
      errors = result.dig('data', 'importOutcomes', 'errors')
      expect(errors).not_to be_nil
      expect(errors[0]['attribute']).to eq attribute
      expect(errors[0]['message']).to match(/#{message}/)
    end

    def expect_error(result, message)
      errors = result.dig('errors')
      expect(errors).not_to be_nil
      expect(errors[0]['message']).to match(/#{message}/)
    end

    it "errors when targetContextType and targetContextId are missing" do
      group_id = find_group("Group B").id
      query = <<~GQL
        mutation {
          importOutcomes(input: {
            groupId: #{group_id}
          }) {
            errors {
              attribute
              message
            }
          }
        }
      GQL
      result = execute_query(query, ctx)
      errors = result.dig('errors')
      expect(errors).not_to be_nil
      expect(errors.length).to eq 2
      expect(
        errors.select {|e| e['path'] == ["mutation", "importOutcomes", "input", "targetContextType"]}
      ).not_to be_nil
      expect(
        errors.select {|e| e['path'] == ["mutation", "importOutcomes", "input", "targetContextId"]}
      ).not_to be_nil
    end

    it "errors when sourceContextType is invalid" do
      result = exec_graphql(source_context_type: 'FooContext')
      expect_validation_error(result, "sourceContextType", "invalid value")
    end

    it "errors when no such source context is found" do
      result = exec_graphql(source_context_type: 'Account', source_context_id: -1)
      expect_error(result, "no such source context")
    end

    it "errors when sourceContextId is not provided when sourceContextType is provided" do
      result = exec_graphql(source_context_type: 'Account', source_context_id: nil)
      expect_validation_error(
        result,
        "sourceContextId",
        "sourceContextId required if sourceContextType provided"
      )
    end

    it "errors when sourceContextType is not provided when sourceContextId is provided" do
      result = exec_graphql(source_context_type: nil, source_context_id: 1)
      expect_validation_error(
        result,
        "sourceContextType",
        "sourceContextType required if sourceContextId provided"
      )
    end

    it "errors when targetContextType is blank" do
      result = exec_graphql(target_context_type: '')
      expect_validation_error(result, "targetContextType", "invalid value")
    end

    it "errors when targetContextId is blank" do
      result = exec_graphql(target_context_id: '')
      expect_error(result, "no such target context")
    end

    it "errors when targetContextType is invalid" do
      result = exec_graphql(target_context_type: 'FooContext')
      expect_validation_error(result, "targetContextType", "invalid value")
    end

    it "errors when no such context is found" do
      result = exec_graphql(target_context_type: 'Account', target_context_id: -1)
      expect_error(result, "no such target context")
    end

    it "errors when neither groupId or outcomeId value is provided" do
      result = exec_graphql
      expect_validation_error(result, "message", "Either groupId or outcomeId values are required")
    end

    context 'import group' do
      it "errors on invalid group id" do
        result = exec_graphql(group_id: 0)
        expect_error(result, "group not found")
      end

      it "errors when importing group from course to course" do
        result = exec_graphql(
          group_id: @course2_group.id,
          source_context_type: nil,
          source_context_id: nil
        )
        expect_error(result, "invalid context for group")
      end

      it "errors when importing root outcome group" do
        result = exec_graphql(group_id: Account.default.root_outcome_group.id)
        expect_error(result, "cannot import a root group")
      end

      it "errors when source context does not match the group's context" do
        result = exec_graphql(
          group_id: find_group("Group B").id,
          source_context_type: 'Course',
          source_context_id: @course2.id
        )
        expect_error(result, "source context does not match group context")
      end
    end

    context 'import outcome' do
      it "errors when importing non-existence outcome" do
        result = exec_graphql(outcome_id: 0)
        expect_error(result, "Outcome 0 is not available in context Course##{target_context_id}")
      end

      it "errors when importing ineligible outcome" do
        result = exec_graphql(outcome_id: @course2_outcome.id)
        expect_error(result, "Outcome #{@course2_outcome.id} is not available in context Course##{target_context_id}")
      end
    end

    context "without permissions" do
      let(:current_user) { nil }

      it "returns error" do
        result = exec_graphql(outcome_id: get_outcome_id(
          "0 Group E outcome"
        ))
        expect_error(result, "not found")
      end
    end
  end
end
