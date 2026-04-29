# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::DeleteAllocationRule, type: :graphql do
  before(:once) do
    @course = course_factory(active_all: true)
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student1 = student_in_course(name: "Student 1", course: @course, active_all: true).user
    @student2 = student_in_course(name: "Student 2", course: @course, active_all: true).user
    @assignment = assignment_model(course: @course, peer_reviews: true, peer_review_count: 3)
  end

  before do
    @course.enable_feature!(:peer_review_allocation_and_grading)
    @rule = AllocationRule.create!(
      course: @course,
      assignment: @assignment,
      assessor: @student1,
      assessee: @student2,
      must_review: true,
      review_permitted: true,
      applies_to_assessor: true
    )
  end

  def execute_with_input(delete_input, current_user = @teacher)
    mutation_command = <<~GQL
      mutation DeleteAllocationRule {
        deleteAllocationRule(
          input: { #{delete_input} }
        ) {
          allocationRuleId
        }
      }
    GQL
    context = { current_user:, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  context "successful deletion" do
    it "deletes an allocation rule" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
      GQL

      result = execute_with_input(query)
      expect(result["data"]["deleteAllocationRule"]["allocationRuleId"].to_i).to eq @rule.id
      expect(@rule.reload.deleted?).to be true
    end
  end

  context "error handling" do
    it "raises an error if peer_review_allocation_and_grading is disabled" do
      @course.disable_feature!(:peer_review_allocation_and_grading)
      query = <<~GQL
        ruleId: "#{@rule.id}"
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq "peer_review_allocation_and_grading feature flag is not enabled for this course"
    end

    it "raises an error if the rule does not exist" do
      query = <<~GQL
        ruleId: "999999"
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq "Allocation rule not found"
    end

    it "raises an error if the user lacks permission" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
      GQL

      result = execute_with_input(query, @student1)

      expect(result["errors"]).to be_present
      expect(result["errors"].first["message"]).to eq "not found"
    end
  end
end
