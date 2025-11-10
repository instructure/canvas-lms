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

RSpec.describe Mutations::CreateAllocationRule, type: :graphql do
  before(:once) do
    @course = course_factory(active_all: true)
    @course.enable_feature!(:peer_review_allocation)
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student1 = student_in_course(name: "Student 1", course: @course, active_all: true).user
    @student2 = student_in_course(name: "Student 2", course: @course, active_all: true).user
    @student3 = student_in_course(name: "Student 3", course: @course, active_all: true).user
    @assignment = assignment_model(course: @course, peer_reviews: true, peer_review_count: 2)
  end

  def execute_with_input(create_input, current_user = @teacher)
    mutation_command = <<~GQL
      mutation {
        createAllocationRule(input: {
          #{create_input}
        }) {
          allocationRules {
            _id
            mustReview
            reviewPermitted
            appliesToAssessor
            assignmentId
            assessor {
              _id
              name
            }
            assessee {
              _id
              name
            }
          }
          allocationErrors {
            attribute
            message
            attributeId
          }
        }
      }
    GQL
    context = { current_user:, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  describe "permissions" do
    context "when user has create permissions" do
      it "allows teachers to create allocation rules" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)
        created_allocation_rule = result["data"]["createAllocationRule"]["allocationRules"].first

        expect(result["errors"]).to be_nil
        expect(result["data"]["createAllocationRule"]["errors"]).to be_nil

        expect(created_allocation_rule["assessor"]["_id"]).to eq @student1.id.to_s
        expect(created_allocation_rule["assessee"]["_id"]).to eq @student2.id.to_s
        expect(created_allocation_rule["assignmentId"]).to eq @assignment.id.to_s
      end

      it "allows TAs with create permissions to create allocation rules" do
        ta = ta_in_course(course: @course, active_all: true).user
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query, ta)

        expect(result["data"]["createAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["errors"]).to be_nil
      end
    end

    context "when user lacks create permissions" do
      it "denies students access" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query, @student1)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("not found")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "denies TAs without create permissions" do
        @course.account.role_overrides.create!({
                                                 role: ta_role,
                                                 permission: "manage_assignments_add",
                                                 enabled: false
                                               })
        ta = ta_in_course(course: @course, active_all: true).user
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL
        result = execute_with_input(query, ta)
        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("not found")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "denies observers access" do
        observer = observer_in_course(course: @course, active_all: true).user
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query, observer)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to match("not found")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end
    end

    context "when assignment doesn't exist" do
      it "raises not found error" do
        query = <<~GQL
          assignmentId: "999999"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Assignment not found")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end
    end
  end

  describe "successful creation" do
    it "creates allocation rule with default values" do
      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
      GQL

      result = execute_with_input(query)

      errors = result["data"]["createAllocationRule"]["allocationErrors"]
      rule_data = result["data"]["createAllocationRule"]["allocationRules"].first

      expect(errors).to be_nil
      expect(rule_data["appliesToAssessor"]).to be true
      expect(rule_data["mustReview"]).to be true
      expect(rule_data["reviewPermitted"]).to be true
    end

    it "creates allocation rule with custom values" do
      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
        mustReview: false
        reviewPermitted: false
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      rule_data = result["data"]["createAllocationRule"]["allocationRules"].first

      expect(rule_data["mustReview"]).to be false
      expect(rule_data["reviewPermitted"]).to be false
      expect(rule_data["appliesToAssessor"]).to be false
    end
  end

  describe "validation errors" do
    context "invalid users" do
      it "returns error when assessor is not enrolled in course" do
        external_user = user_factory
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{external_user.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)

        errors = result["data"]["createAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessor (#{external_user.id}) must be a student assigned to this assignment")
      end

      it "returns error when assessee is not enrolled in course" do
        external_user = user_factory
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{external_user.id}"]
        GQL

        result = execute_with_input(query)
        errors = result["data"]["createAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessee (#{external_user.id}) must be a student with visibility to this assignment")
      end

      it "returns error when assessor and assessee are the same" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student1.id}"]
        GQL

        result = execute_with_input(query)
        errors = result["data"]["createAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessee (#{@student1.id}) cannot be the same as the assessor")
      end
    end

    context "conflicting rules" do
      before do
        @existing_rule = AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true
        )
      end

      it "returns error when trying to create conflicting rule" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          mustReview: false
          reviewPermitted: false
        GQL

        result = execute_with_input(query)
        errors = result["data"]["createAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("This rule conflicts with rule \"#{@student1.name} must review #{@student2.name}\"")
        expect(errors.first["attribute"]).to eq("assessee_id")
        expect(errors.first["attributeId"]).to eq(@student2.id.to_s)
      end
    end

    context "completed review conflicts" do
      before do
        submission1 = @assignment.submit_homework(@student1)
        submission2 = @assignment.submit_homework(@student2)
        submission3 = @assignment.submit_homework(@student3)

        AssessmentRequest.create!(
          assessor: @student1,
          user: @student2,
          asset: submission2,
          assessor_asset: submission1,
          workflow_state: "completed"
        )

        AssessmentRequest.create!(
          assessor: @student1,
          user: @student3,
          asset: submission3,
          assessor_asset: submission1,
          workflow_state: "completed"
        )
      end

      it "returns error when trying to prohibit completed review" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reviewPermitted: false
        GQL

        result = execute_with_input(query)
        errors = result["data"]["createAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("This rule conflicts with completed peer review. #{@student1.name} has already reviewed #{@student2.name}")
        expect(errors.first["attribute"]).to eq("assessee_id")
        expect(errors.first["attributeId"]).to eq(@student2.id.to_s)
      end
    end
  end

  describe "array validation" do
    context "when applies_to_assessor is true (default)" do
      it "allows one assessor and multiple assessees" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(2)

        created_rules.each do |rule|
          rule_type = GraphQLTypeTester.new(rule, current_user: @teacher)
          expect(rule_type.resolve("assessor { _id }")).to eq(@student1.id.to_s)
          expect(rule_type.resolve("appliesToAssessor")).to be true
        end

        assessee_ids = created_rules.map(&:assessee_id)
        expect(assessee_ids).to contain_exactly(@student2.id, @student3.id)
      end

      it "rejects multiple assessors" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}", "#{@student2.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessor is allowed when rule applies to assessor")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects empty assessee array" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: []
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("At least one assessee is required")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end
    end

    context "when applies_to_assessor is false" do
      it "allows multiple assessors and one assessee" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}", "#{@student2.id}"]
          assesseeIds: ["#{@student3.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(2)

        created_rules.each do |rule|
          rule_type = GraphQLTypeTester.new(rule, current_user: @teacher)
          expect(rule_type.resolve("assessee { _id }")).to eq(@student3.id.to_s)
          expect(rule_type.resolve("appliesToAssessor")).to be false
        end

        assessor_ids = created_rules.map(&:assessor_id)
        expect(assessor_ids).to contain_exactly(@student1.id, @student2.id)
      end

      it "rejects multiple assessees" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessee is allowed when rule applies to assessee")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects empty assessor array" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: []
          assesseeIds: ["#{@student3.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("At least one assessor is required")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end
    end

    context "edge cases" do
      it "rejects completely empty arrays" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: []
          assesseeIds: []
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("At least one assessor is required")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "creates single rule when both arrays have single items" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rule = AllocationRule.where(assignment: @assignment).first
        rule_type = GraphQLTypeTester.new(created_rule, current_user: @teacher)

        expect(rule_type.resolve("assessor { _id }")).to eq(@student1.id.to_s)
        expect(rule_type.resolve("assessee { _id }")).to eq(@student2.id.to_s)
        expect(rule_type.resolve("mustReview")).to be true
        expect(rule_type.resolve("reviewPermitted")).to be true
        expect(rule_type.resolve("appliesToAssessor")).to be true
      end

      it "validates conflicting rules" do
        @assignment.update!(peer_review_count: 3)
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true
        )

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}", "#{@student2.id}"]
          reviewPermitted: false
        GQL

        result = execute_with_input(query)

        expect(result["data"]["createAllocationRule"]["allocationErrors"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["message"]).to eq("This rule conflicts with rule \"#{@student1.name} must review #{@student2.name}\"")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attribute"]).to eq("assessee_id")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attributeId"]).to eq(@student2.id.to_s)
      end
    end

    context "multiple subjects" do
      it "creates multiple rules for one assessor reviewing multiple assessees" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(2)

        created_rules.each do |rule|
          rule_type = GraphQLTypeTester.new(rule, current_user: @teacher)
          expect(rule_type.resolve("assessor { _id }")).to eq(@student1.id.to_s)
          expect(rule_type.resolve("appliesToAssessor")).to be true
          expect(rule_type.resolve("mustReview")).to be true
        end

        assessee_ids = created_rules.map(&:assessee_id)
        expect(assessee_ids).to contain_exactly(@student2.id, @student3.id)
      end

      it "creates multiple rules for multiple assessors reviewing one assessee" do
        student4 = student_in_course(name: "Student 4", course: @course, active_all: true).user
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}", "#{@student2.id}", "#{@student3.id}"]
          assesseeIds: ["#{student4.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(3)

        created_rules.each do |rule|
          rule_type = GraphQLTypeTester.new(rule, current_user: @teacher)
          expect(rule_type.resolve("assessee { _id }")).to eq(student4.id.to_s)
          expect(rule_type.resolve("appliesToAssessor")).to be false
          expect(rule_type.resolve("mustReview")).to be true
        end

        assessor_ids = created_rules.map(&:assessor_id)
        expect(assessor_ids).to contain_exactly(@student1.id, @student2.id, @student3.id)
      end
    end

    context "array size limits" do
      it "rejects more than 50 assessors" do
        students = (1..51).map do |i|
          student_in_course(
            name: "Student #{i}",
            course: @course,
            active_all: true
          ).user
        end

        assessor_ids = students.map { |x| x.id.to_s }.join('", "')

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{assessor_ids}"]
          assesseeIds: ["#{@student1.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq(
          "A maximum of 50 assessors can be provided at once"
        )
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects more than 50 assessees" do
        students = (1..51).map do |i|
          student_in_course(
            name: "Student #{i}",
            course: @course,
            active_all: true
          ).user
        end

        assessee_ids = students.map { |x| x.id.to_s }.join('", "')

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{assessee_ids}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq(
          "A maximum of 50 assessees can be provided at once"
        )
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "allows exactly 50 assessors" do
        students = (1..50).map do |i|
          student_in_course(
            name: "Student #{i}",
            course: @course,
            active_all: true
          ).user
        end

        assessor_ids = students.map { |x| x.id.to_s }.join('", "')

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{assessor_ids}"]
          assesseeIds: ["#{@student1.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil
        expect(result["data"]["createAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationRules"].length).to eq(50)
      end

      it "allows exactly 50 assessees" do
        students = (1..50).map do |i|
          student_in_course(
            name: "Student #{i}",
            course: @course,
            active_all: true
          ).user
        end

        assessee_ids = students.map { |x| x.id.to_s }.join('", "')

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{assessee_ids}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil
        expect(result["data"]["createAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationRules"].length).to eq(50)
      end
    end
  end

  describe "reciprocal rules" do
    context "when reciprocal is true" do
      it "creates two rules for mutual review relationship" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(2)

        rule1 = created_rules.find { |rule| rule.assessor_id == @student1.id && rule.assessee_id == @student2.id }
        rule2 = created_rules.find { |rule| rule.assessor_id == @student2.id && rule.assessee_id == @student1.id }

        expect(rule1).not_to be_nil
        expect(rule2).not_to be_nil

        rule1_type = GraphQLTypeTester.new(rule1, current_user: @teacher)
        rule2_type = GraphQLTypeTester.new(rule2, current_user: @teacher)

        expect(rule1_type.resolve("assessor { _id }")).to eq(@student1.id.to_s)
        expect(rule1_type.resolve("assessee { _id }")).to eq(@student2.id.to_s)
        expect(rule1_type.resolve("mustReview")).to be true
        expect(rule1_type.resolve("reviewPermitted")).to be true
        expect(rule1_type.resolve("appliesToAssessor")).to be true

        expect(rule2_type.resolve("assessor { _id }")).to eq(@student2.id.to_s)
        expect(rule2_type.resolve("assessee { _id }")).to eq(@student1.id.to_s)
        expect(rule2_type.resolve("mustReview")).to be true
        expect(rule2_type.resolve("reviewPermitted")).to be true
        expect(rule2_type.resolve("appliesToAssessor")).to be true
      end

      it "creates reciprocal rules with custom values" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reciprocal: true
          mustReview: false
          reviewPermitted: true
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil

        created_rules = AllocationRule.where(assignment: @assignment)
        expect(created_rules.count).to eq(2)

        created_rules.each do |rule|
          rule_type = GraphQLTypeTester.new(rule, current_user: @teacher)
          expect(rule_type.resolve("mustReview")).to be false
          expect(rule_type.resolve("reviewPermitted")).to be true
          expect(rule_type.resolve("appliesToAssessor")).to be false
        end
      end

      it "rejects multiple assessors when reciprocal is true" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}", "#{@student2.id}"]
          assesseeIds: ["#{@student3.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessor is allowed when creating reciprocal rules")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects multiple assessees when reciprocal is true" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessee is allowed when creating reciprocal rules")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects empty assessor array when reciprocal is true" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: []
          assesseeIds: ["#{@student2.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("At least one assessor is required")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "rejects empty assessee array when reciprocal is true" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: []
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("At least one assessee is required")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "validates conflicting rules for both directions" do
        AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student2,
          must_review: true,
          review_permitted: true
        )

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reciprocal: true
          reviewPermitted: false
        GQL

        result = execute_with_input(query)

        expect(result["data"]["createAllocationRule"]["allocationErrors"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["message"]).to eq("This rule conflicts with rule \"#{@student1.name} must review #{@student2.name}\"")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attribute"]).to eq("assessee_id")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attributeId"]).to eq(@student2.id.to_s)
      end

      it "validates when users are the same" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student1.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["data"]["createAllocationRule"]["allocationErrors"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["message"]).to eq("assessee (#{@student1.id}) cannot be the same as the assessor")
      end
    end

    context "reciprocal with completed reviews" do
      before do
        submission1 = @assignment.submit_homework(@student1)
        submission2 = @assignment.submit_homework(@student2)

        AssessmentRequest.create!(
          assessor: @student1,
          user: @student2,
          asset: submission2,
          assessor_asset: submission1,
          workflow_state: "completed"
        )
      end

      it "validates against completed reviews in both directions" do
        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reciprocal: true
          reviewPermitted: false
        GQL

        result = execute_with_input(query)

        expect(result["data"]["createAllocationRule"]["allocationErrors"]).not_to be_empty
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["message"]).to eq("This rule conflicts with completed peer review. #{@student1.name} has already reviewed #{@student2.name}")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attribute"]).to eq("assessee_id")
        expect(result["data"]["createAllocationRule"]["allocationErrors"].first["attributeId"]).to eq(@student2.id.to_s)
      end
    end
  end

  describe "feature flag validation" do
    context "when peer_review_allocation feature is disabled" do
      it "returns error when feature flag is not enabled" do
        @course.disable_feature!(:peer_review_allocation)

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("peer_review_allocation feature flag is not enabled for this course")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end

      it "denies access even for teachers when feature is disabled" do
        @course.disable_feature!(:peer_review_allocation)

        query = <<~GQL
          assignmentId: "#{@assignment.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query, @teacher)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("peer_review_allocation feature flag is not enabled for this course")
        expect(result["errors"].first["path"]).to eq(["createAllocationRule"])
      end
    end
  end

  describe "applies_to_assessor updates on existing rules" do
    before do
      @existing_rule = AllocationRule.create!(
        course: @course,
        assignment: @assignment,
        assessor: @student1,
        assessee: @student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )
    end

    it "updates applies_to_assessor when finding existing rule with different value" do
      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
        mustReview: true
        reviewPermitted: true
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_nil

      all_rules = AllocationRule.where(assignment: @assignment)
      expect(all_rules.count).to eq(1)

      updated_rule = all_rules.first
      expect(updated_rule.id).to eq(@existing_rule.id)
      expect(updated_rule.applies_to_assessor).to be false
      expect(updated_rule.must_review).to be true
      expect(updated_rule.review_permitted).to be true
    end

    it "does not modify applies_to_assessor when value matches" do
      original_updated_at = @existing_rule.updated_at

      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
        mustReview: true
        reviewPermitted: true
        appliesToAssessor: true
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_nil

      all_rules = AllocationRule.where(assignment: @assignment)
      expect(all_rules.count).to eq(1)

      same_rule = all_rules.first
      expect(same_rule.id).to eq(@existing_rule.id)
      expect(same_rule.applies_to_assessor).to be true
      expect(same_rule.updated_at).to eq(original_updated_at)
    end
  end

  describe "soft deletion and new rule creation" do
    before do
      @original_rule = AllocationRule.create!(
        course: @course,
        assignment: @assignment,
        assessor: @student1,
        assessee: @student2
      )
      @original_rule.destroy
    end

    it "creates new rule when matching soft-deleted rule exists" do
      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_nil

      all_rules = AllocationRule.where(assignment: @assignment)
      expect(all_rules.count).to eq(2)
      expect(all_rules.active.count).to eq(1)

      new_rule = all_rules.active.first
      expect(new_rule.id).not_to eq(@original_rule.id)
      expect(new_rule.workflow_state).to eq("active")
      expect(new_rule.assessor_id).to eq(@student1.id)
      expect(new_rule.assessee_id).to eq(@student2.id)
      expect(@original_rule.reload.workflow_state).to eq("deleted")
    end

    it "creates new rule when attributes differ from soft-deleted rule" do
      query = <<~GQL
        assignmentId: "#{@assignment.id}"
        assessorIds: ["#{@student2.id}"]
        assesseeIds: ["#{@student1.id}"]
        mustReview: false
        reviewPermitted: false
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_nil

      all_rules = AllocationRule.where(assignment: @assignment)
      expect(all_rules.count).to eq(2)
      expect(all_rules.active.count).to eq(1)

      new_rule = all_rules.active.first
      expect(new_rule.id).not_to eq(@original_rule.id)
      expect(new_rule.workflow_state).to eq("active")
      expect(@original_rule.reload.workflow_state).to eq("deleted")
    end
  end
end
