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
#

require_relative "../graphql_spec_helper"

describe Types::AllocationRuleType do
  before(:once) do
    @course = course_factory(active_all: true)
    @teacher = teacher_in_course(active_all: true, course: @course).user
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user
    @ta = ta_in_course(course: @course, active_all: true).user
    @assignment = assignment_model(course: @course, peer_reviews: true, peer_review_count: 2)

    @allocation_rule = AllocationRule.create!(
      course: @course,
      assignment: @assignment,
      assessor: @student1,
      assessee: @student2,
      must_review: true,
      review_permitted: true,
      applies_to_assessor: true
    )
    @allocation_rule_type = GraphQLTypeTester.new(@allocation_rule, current_user: @teacher)
    @allocation_rule_type_ta = GraphQLTypeTester.new(@allocation_rule, current_user: @ta)
    @allocation_rule_type_student = GraphQLTypeTester.new(@allocation_rule, current_user: @student1)
  end

  let(:base_query) do
    <<~GQL
      query getAllocationRule($id: ID!) {
        node(id: $id) {
          ... on AllocationRule {
            id
            _id
            mustReview
            reviewPermitted
            appliesToAssessor
            workflowState
            createdAt
            updatedAt
            assignmentId
            courseId
            assessor {
              id
              _id
              name
            }
            assessee {
              id
              _id
              name
            }
          }
        }
      }
    GQL
  end

  describe "basic field resolution" do
    it "works with basic fields" do
      expect(@allocation_rule_type.resolve("_id")).to eq @allocation_rule.id.to_s
      expect(@allocation_rule_type.resolve("mustReview")).to eq @allocation_rule.must_review
      expect(@allocation_rule_type.resolve("reviewPermitted")).to eq @allocation_rule.review_permitted
      expect(@allocation_rule_type.resolve("appliesToAssessor")).to eq @allocation_rule.applies_to_assessor
      expect(@allocation_rule_type.resolve("workflowState")).to eq @allocation_rule.workflow_state
      expect(Time.iso8601(@allocation_rule_type.resolve("createdAt")).to_i).to eq @allocation_rule.created_at.to_i
      expect(Time.iso8601(@allocation_rule_type.resolve("updatedAt")).to_i).to eq @allocation_rule.updated_at.to_i
    end

    it "resolves ID fields" do
      expect(@allocation_rule_type.resolve("assignmentId")).to eq @assignment.id.to_s
      expect(@allocation_rule_type.resolve("courseId")).to eq @course.id.to_s
    end
  end

  describe "association fields" do
    it "can access the assessor user" do
      expect(@allocation_rule_type.resolve("assessor { _id }")).to eq @student1.id.to_s
      expect(@allocation_rule_type.resolve("assessor { name }")).to eq @student1.name
    end

    it "can access the assessee user" do
      expect(@allocation_rule_type.resolve("assessee { _id }")).to eq @student2.id.to_s
      expect(@allocation_rule_type.resolve("assessee { name }")).to eq @student2.name
    end
  end

  describe "permissions and access control" do
    context "when user has grading permissions" do
      it "allows teachers access" do
        expect(@allocation_rule_type.resolve("_id")).not_to be_nil
        expect(@allocation_rule_type.resolve("assessor { _id }")).not_to be_nil
        expect(@allocation_rule_type.resolve("assessee { _id }")).not_to be_nil
      end

      it "allows TAs access" do
        expect(@allocation_rule_type_ta.resolve("_id")).not_to be_nil
        expect(@allocation_rule_type_ta.resolve("assessor { _id }")).not_to be_nil
        expect(@allocation_rule_type_ta.resolve("assessee { _id }")).not_to be_nil
      end
    end

    context "when user does not have grading permissions" do
      it "does not allow students access to allocation rule assessor/assessee information" do
        expect(@allocation_rule_type_student.resolve("assessor { _id }")).to be_nil
        expect(@allocation_rule_type_student.resolve("assessee { _id }")).to be_nil
      end

      it "does not allow teacher from other course access to assessor/assessee information" do
        other_course = course_factory(active_all: true)
        external_teacher = teacher_in_course(active_all: true, course: other_course).user
        @allocation_rule_type_external = GraphQLTypeTester.new(@allocation_rule, current_user: external_teacher)
        expect(@allocation_rule_type_external.resolve("assessor { _id }")).to be_nil
        expect(@allocation_rule_type_external.resolve("assessee { _id }")).to be_nil
      end
    end
  end
end
