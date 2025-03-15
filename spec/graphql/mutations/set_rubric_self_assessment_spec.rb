# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Mutations::SetRubricSelfAssessment do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create! }
  let!(:student) { User.create! }

  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:context) { { current_user: teacher, domain_root_account: account } }

  before do
    course.enroll_student(student, enrollment_state: "active")
    assignment_model(course:)
    rubric_model(course:)
    rubric_association_model(user: teacher, context: course, association_object: @assignment, purpose: "grading", rubric: @rubric)
    course.enable_feature!(:enhanced_rubrics)
    course.enable_feature!(:assignments_2_student)
    course.root_account.enable_feature!(:rubric_self_assessment)
  end

  def mutation_str(assignment_id: @assignment.id, rubric_self_assessment_enabled: false)
    input_string = "assignmentId: #{assignment_id}, rubricSelfAssessmentEnabled: #{rubric_self_assessment_enabled}"

    <<~GQL
      mutation {
        setRubricSelfAssessment(input: {
          #{input_string}
        }) {
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  context "missing assignment or rubric association" do
    it "returns error when assignment does not exist" do
      result = CanvasSchema.execute(mutation_str(assignment_id: "123"), context:)
      expect(result.dig("errors", 0, "message")).to eq "Assignment not found"
    end

    it "returns error when rubric association for assignment does not exist" do
      new_assignment = course.assignments.create!(title: "hi", grading_type: "points", points_possible: 1)
      result = CanvasSchema.execute(mutation_str(assignment_id: new_assignment.id), context:)
      expect(result.dig("errors", 0, "message")).to eq "Rubric Association not found"
    end
  end

  context "when feature flags are not enabled" do
    it "returns error when enhanced rubrics feature is not enabled" do
      course.disable_feature!(:enhanced_rubrics)
      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "enhanced_rubrics, rubric_self_assesment and assignments_2_student must be enabled"
    end

    it "returns errors when rubric self assessment feature is not enabled" do
      course.root_account.disable_feature!(:rubric_self_assessment)
      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "enhanced_rubrics, rubric_self_assesment and assignments_2_student must be enabled"
    end
  end

  context "when executed by a user with permission to update rubric self assessment" do
    before do
      @assignment.submissions.update_all(cached_due_date: nil)
    end

    it "allows setting rubric self assessment to true" do
      CanvasSchema.execute(mutation_str(rubric_self_assessment_enabled: true), context:)
      expect(@assignment.reload.rubric_self_assessment_enabled).to be true
    end

    it "allows setting rubric self assessment to false" do
      @assignment.update!(rubric_self_assessment_enabled: true)
      CanvasSchema.execute(mutation_str(rubric_self_assessment_enabled: false), context:)
      expect(@assignment.reload.rubric_self_assessment_enabled).to be false
    end

    it "allows setting rubric self assessment when due date in the future" do
      @assignment.submissions.update_all(cached_due_date: 1.day.from_now)
      CanvasSchema.execute(mutation_str(rubric_self_assessment_enabled: true), context:)
      expect(@assignment.reload.rubric_self_assessment_enabled).to be true
    end
  end

  context "when executed by a user without permission to update rubric self assessment" do
    it "does not allow setting rubric self assessment" do
      student_context = { current_user: student, domain_root_account: account }
      result = CanvasSchema.execute(mutation_str, context: student_context)
      expect(result.dig("errors", 0, "message")).to eq "Insufficient permissions"
    end
  end

  context "when rubric self assessment is unable to be modified" do
    it "returns error when there is an existing self assessment" do
      @assignment.update!(rubric_self_assessment_enabled: true)
      rubric_assessment_model(context: course, rubric: @rubric, user: student, assessment_type: "self_assessment")

      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "Assignment has self assessments or due date has passed"
    end

    it "returns error when the due date has passed on a submission" do
      submission_model(assignment: @assignment, user: student, cached_due_date: 1.day.ago)

      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "Assignment has self assessments or due date has passed"
    end
  end

  context "when executed on a group assignment" do
    before do
      group_category = course.group_categories.create!(name: "Group Category")
      @group = group_category.groups.create!(name: "Group", context: course)
      group_membership_model(group: @group, user: student)
      @assignment.update!(group_category:)
    end

    it "returns error when group assignment" do
      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "Cannot set rubric self assessment for group assignments"
    end
  end
end
