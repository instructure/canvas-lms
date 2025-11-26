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

RSpec.describe Mutations::UpdateAllocationRule, type: :graphql do
  before(:once) do
    @course = course_factory(active_all: true)
    @course.enable_feature!(:peer_review_allocation_and_grading)
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student1 = student_in_course(name: "Student 1", course: @course, active_all: true).user
    @student2 = student_in_course(name: "Student 2", course: @course, active_all: true).user
    @student3 = student_in_course(name: "Student 3", course: @course, active_all: true).user
    @student4 = student_in_course(name: "Student 4", course: @course, active_all: true).user
    @assignment = assignment_model(course: @course, peer_reviews: true, peer_review_count: 3)
  end

  def execute_with_input(update_input, current_user = @teacher)
    mutation_command = <<~GQL
      mutation {
        updateAllocationRule(input: {
          #{update_input}
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
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user:, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  describe "permissions" do
    before do
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

    context "when user has update permissions" do
      it "allows teachers to update allocation rules" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
          mustReview: false
        GQL

        result = execute_with_input(query)
        updated_rule = result["data"]["updateAllocationRule"]["allocationRules"].first

        expect(result["errors"]).to be_nil
        expect(result["data"]["updateAllocationRule"]["errors"]).to be_nil

        expect(updated_rule["assessor"]["_id"]).to eq @student1.id.to_s
        expect(updated_rule["assessee"]["_id"]).to eq @student3.id.to_s
        expect(updated_rule["mustReview"]).to be false
        expect(updated_rule["assignmentId"]).to eq @assignment.id.to_s
      end

      it "allows TAs with update permissions to update allocation rules" do
        ta = ta_in_course(course: @course, active_all: true).user
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query, ta)

        expect(result["data"]["updateAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["updateAllocationRule"]["errors"]).to be_nil
      end
    end

    context "when user lacks update permissions" do
      it "denies students access" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query, @student1)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("not found")
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
      end

      it "denies TAs without update permissions" do
        @course.account.role_overrides.create!({
                                                 role: ta_role,
                                                 permission: "manage_assignments_edit",
                                                 enabled: false
                                               })
        ta = ta_in_course(course: @course, active_all: true).user
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query, ta)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("not found")
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
      end

      it "denies observers access" do
        observer = observer_in_course(course: @course, active_all: true).user
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query, observer)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to match("not found")
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
      end
    end

    context "when rule doesn't exist" do
      it "raises not found error" do
        query = <<~GQL
          ruleId: "999999"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Allocation rule not found")
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
      end
    end
  end

  describe "successful updates" do
    before do
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

    it "updates allocation rule with new values" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student3.id}"]
        mustReview: false
        reviewPermitted: false
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      rule_data = result["data"]["updateAllocationRule"]["allocationRules"].first

      expect(rule_data["assessee"]["_id"]).to eq @student3.id.to_s
      expect(rule_data["mustReview"]).to be false
      expect(rule_data["reviewPermitted"]).to be false
      expect(rule_data["appliesToAssessor"]).to be false
    end

    it "updates applies_to_assessor on existing rule" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}"]
        mustReview: true
        reviewPermitted: true
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      expect(result["errors"]).to be_nil

      all_rules = AllocationRule.where(assignment: @assignment).active
      updated_existing = all_rules.find_by(id: @rule.id)
      expect(updated_existing.applies_to_assessor).to be false
    end

    it "changes assessor and assessee" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student3.id}"]
        assesseeIds: ["#{@student4.id}"]
      GQL

      result = execute_with_input(query)
      rule_data = result["data"]["updateAllocationRule"]["allocationRules"].first

      expect(rule_data["assessor"]["_id"]).to eq @student3.id.to_s
      expect(rule_data["assessee"]["_id"]).to eq @student4.id.to_s
    end

    it "updates rule with multiple assessees when applies_to_assessor is true" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
        appliesToAssessor: true
      GQL

      result = execute_with_input(query)
      rules = result["data"]["updateAllocationRule"]["allocationRules"]

      expect(rules.length).to eq(2)

      # Original rule should be updated
      original_rule = rules.find { |r| r["_id"] == @rule.id.to_s }
      expect(original_rule["assessee"]["_id"]).to eq @student2.id.to_s

      # New rule should be created
      new_rule = rules.find { |r| r["_id"] != @rule.id.to_s }
      expect(new_rule["assessor"]["_id"]).to eq @student1.id.to_s
      expect(new_rule["assessee"]["_id"]).to eq @student3.id.to_s
    end

    it "updates rule with multiple assessors when applies_to_assessor is false" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}", "#{@student3.id}"]
        assesseeIds: ["#{@student2.id}"]
        appliesToAssessor: false
      GQL

      result = execute_with_input(query)
      rules = result["data"]["updateAllocationRule"]["allocationRules"]

      expect(rules.length).to eq(2)

      # Original rule should be updated
      original_rule = rules.find { |r| r["_id"] == @rule.id.to_s }
      expect(original_rule["assessor"]["_id"]).to eq @student1.id.to_s

      # New rule should be created
      new_rule = rules.find { |r| r["_id"] != @rule.id.to_s }
      expect(new_rule["assessor"]["_id"]).to eq @student3.id.to_s
      expect(new_rule["assessee"]["_id"]).to eq @student2.id.to_s
    end
  end

  describe "reciprocal rules" do
    before do
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

    context "when reciprocal is true" do
      it "creates reciprocal rule pair" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)
        rules = result["data"]["updateAllocationRule"]["allocationRules"]

        expect(rules.length).to eq(2)

        rule1 = rules.find { |r| r["assessor"]["_id"] == @student1.id.to_s && r["assessee"]["_id"] == @student3.id.to_s }
        rule2 = rules.find { |r| r["assessor"]["_id"] == @student3.id.to_s && r["assessee"]["_id"] == @student1.id.to_s }

        expect(rule1).not_to be_nil
        expect(rule2).not_to be_nil
        expect(rule1["mustReview"]).to be true
        expect(rule2["mustReview"]).to be true
      end

      it "updates reciprocal rules with custom values" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
          reciprocal: true
          mustReview: false
          reviewPermitted: true
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)
        rules = result["data"]["updateAllocationRule"]["allocationRules"]

        expect(rules.length).to eq(2)

        rules.each do |rule|
          expect(rule["mustReview"]).to be false
          expect(rule["reviewPermitted"]).to be true
          expect(rule["appliesToAssessor"]).to be false
        end
      end

      it "rejects multiple assessors when reciprocal is true" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}", "#{@student2.id}"]
          assesseeIds: ["#{@student3.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessor is allowed when creating reciprocal rules")
      end

      it "rejects multiple assessees when reciprocal is true" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}", "#{@student3.id}"]
          reciprocal: true
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("Only one assessee is allowed when creating reciprocal rules")
      end
    end
  end

  describe "validation errors" do
    before do
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
          ruleId: "#{@rule.id}"
          assessorIds: ["#{assessor_ids}"]
          assesseeIds: ["#{@student1.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq(
          "A maximum of 50 assessors can be provided at once"
        )
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
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
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{assessee_ids}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq(
          "A maximum of 50 assessees can be provided at once"
        )
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
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
          ruleId: "#{@rule.id}"
          assessorIds: ["#{assessor_ids}"]
          assesseeIds: ["#{@student1.id}"]
          appliesToAssessor: false
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil
        expect(result["data"]["updateAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["updateAllocationRule"]["allocationRules"].length).to eq(50)
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
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{assessee_ids}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).to be_nil
        expect(result["data"]["updateAllocationRule"]["allocationRules"]).not_to be_empty
        expect(result["data"]["updateAllocationRule"]["allocationRules"].length).to eq(50)
      end
    end

    context "invalid users" do
      it "returns error when assessor is not enrolled in course" do
        external_user = user_factory
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{external_user.id}"]
          assesseeIds: ["#{@student2.id}"]
        GQL

        result = execute_with_input(query)
        errors = result["data"]["updateAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessor (#{external_user.id}) must be a student assigned to this assignment")
      end

      it "returns error when assessee is not enrolled in course" do
        external_user = user_factory
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{external_user.id}"]
        GQL

        result = execute_with_input(query)
        errors = result["data"]["updateAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessee (#{external_user.id}) must be a student with visibility to this assignment")
      end

      it "returns error when assessor and assessee are the same" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student1.id}"]
        GQL

        result = execute_with_input(query)
        errors = result["data"]["updateAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("assessee (#{@student1.id}) cannot be the same as the assessor")
      end
    end

    context "conflicting rules" do
      before do
        @conflicting_rule = AllocationRule.create!(
          course: @course,
          assignment: @assignment,
          assessor: @student1,
          assessee: @student3,
          must_review: true,
          review_permitted: true
        )
      end

      it "returns error when trying to create conflicting rule" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
          mustReview: false
          reviewPermitted: false
        GQL

        result = execute_with_input(query)
        errors = result["data"]["updateAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("This rule conflicts with rule \"#{@student1.name} must review #{@student3.name}\"")
      end
    end

    context "completed review conflicts" do
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

      it "returns error when trying to prohibit completed review" do
        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student2.id}"]
          reviewPermitted: false
        GQL

        result = execute_with_input(query)
        errors = result["data"]["updateAllocationRule"]["allocationErrors"]

        expect(errors).not_to be_empty
        expect(errors.first["message"]).to eq("This rule conflicts with completed peer review. #{@student1.name} has already reviewed #{@student2.name}")
      end
    end
  end

  describe "feature flag validation" do
    before do
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

    context "when peer_review_allocation_and_grading feature is disabled" do
      it "returns error when feature flag is not enabled" do
        @course.disable_feature!(:peer_review_allocation_and_grading)

        query = <<~GQL
          ruleId: "#{@rule.id}"
          assessorIds: ["#{@student1.id}"]
          assesseeIds: ["#{@student3.id}"]
        GQL

        result = execute_with_input(query)

        expect(result["errors"]).not_to be_empty
        expect(result["errors"].first["message"]).to eq("peer_review_allocation_and_grading feature flag is not enabled for this course")
        expect(result["errors"].first["path"]).to eq(["updateAllocationRule"])
      end
    end
  end

  describe "edge cases" do
    before do
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

    it "handles updating from single to multiple subjects" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}"]
        assesseeIds: ["#{@student2.id}", "#{@student3.id}", "#{@student4.id}"]
      GQL

      result = execute_with_input(query)
      rules = result["data"]["updateAllocationRule"]["allocationRules"]

      expect(rules.length).to eq(3)

      # Check that all rules have the same assessor
      rules.each do |rule|
        expect(rule["assessor"]["_id"]).to eq @student1.id.to_s
      end

      # Check that we have all the expected assessees
      assessee_ids = rules.map { |r| r["assessee"]["_id"] }
      expect(assessee_ids).to contain_exactly(@student2.id.to_s, @student3.id.to_s, @student4.id.to_s)
    end

    it "validates array constraints during update" do
      query = <<~GQL
        ruleId: "#{@rule.id}"
        assessorIds: ["#{@student1.id}", "#{@student3.id}"]
        assesseeIds: ["#{@student2.id}"]
        appliesToAssessor: true
      GQL

      result = execute_with_input(query)

      expect(result["errors"]).not_to be_empty
      expect(result["errors"].first["message"]).to eq("Only one assessor is allowed when rule applies to assessor")
    end
  end
end
