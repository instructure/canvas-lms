# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::OutcomeAlignmentType do
  before(:once) do
    account_admin_user
    course_with_teacher
    @assignment = assignment_model({
                                     course: @course,
                                     name: "Assignment",
                                     due_at: nil,
                                     points_possible: 10,
                                     submission_types: "online_text_entry",
                                   })
    @outcome = outcome_model(context: @course, title: "outcome")
    @outcome_alignment = @outcome.align(@assignment, @course)
    @module = @course.context_modules.create!(name: "module", workflow_state: "unpublished")
    @module.add_item type: "assignment", id: @assignment.id

    @course.account.enable_feature!(:outcome_alignment_summary)
  end

  let(:graphql_context) { { current_user: @admin } }
  let(:outcome_type) { GraphQLTypeTester.new(@outcome, graphql_context) }

  describe "returns correct values for alignment fields" do
    it "returns _id" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { _id }")[0]
      ).to eq @outcome_alignment.id.to_s
    end

    it "returns learning_outcome_id" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { learningOutcomeId }")[0]
      ).to eq @outcome.id.to_s
    end

    it "returns context_id" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { contextId }")[0]
      ).to eq @course.id.to_s
    end

    it "returns context_type" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { contextType }")[0]
      ).to eq "Course"
    end

    it "returns content_id" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { contentId }")[0]
      ).to eq @outcome_alignment.content_id.to_s
    end

    it "returns content_type" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { contentType }")[0]
      ).to eq "Assignment"
    end

    it "returns title" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { title }")[0]
      ).to eq @assignment.title
    end

    it "returns url" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { url }")[0]
      ).to eq "/courses/#{@course.id}/outcomes/#{@outcome.id}/alignments/#{@outcome_alignment.id}"
    end

    it "returns module_id" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { moduleId }")[0]
      ).to eq @module.id.to_s
    end

    it "returns module_name" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { moduleName }")[0]
      ).to eq @module.name
    end

    it "returns module_url" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { moduleUrl }")[0]
      ).to eq "/courses/#{@course.id}/modules/#{@module.id}"
    end

    it "returns module_workflow_state" do
      expect(
        outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { moduleWorkflowState }")[0]
      ).to eq @module.workflow_state
    end
  end
end
