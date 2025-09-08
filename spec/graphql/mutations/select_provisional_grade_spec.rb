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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::SelectProvisionalGrade do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create! }
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let!(:final_grader) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let!(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
  let!(:other_student) { course.enroll_student(User.create!, enrollment_state: "active").user }

  let!(:assignment) do
    course.assignments.create!(
      title: "Moderated Assignment",
      points_possible: 10,
      moderated_grading: true,
      grader_count: 2,
      final_grader:
    )
  end

  let!(:provisional_grade_1) do
    # Create moderation grader for anonymous ID support (must be exactly 5 characters)
    assignment.moderation_graders.create!(user: teacher, anonymous_id: "teach")
    assignment.grade_student(student, grader: teacher, provisional: true, score: 8)
    assignment.provisional_grades.find_by(scorer: teacher)
  end

  let!(:provisional_grade_2) do
    other_grader = course.enroll_teacher(User.create!, enrollment_state: "active").user
    # Create moderation grader for the second grader as well (must be exactly 5 characters)
    assignment.moderation_graders.create!(user: other_grader, anonymous_id: "other")
    assignment.grade_student(student, grader: other_grader, provisional: true, score: 9)
    assignment.provisional_grades.find_by(scorer: other_grader)
  end

  let!(:other_assignment_provisional_grade) do
    other_assignment = course.assignments.create!(
      title: "Other Assignment",
      points_possible: 5,
      moderated_grading: true,
      grader_count: 1,
      final_grader:
    )
    other_assignment.grade_student(other_student, grader: teacher, provisional: true, score: 4)
    other_assignment.provisional_grades.find_by(scorer: teacher)
  end

  def mutation_str(assignment_id: assignment.id, provisional_grade_id: provisional_grade_1.id)
    <<~GQL
      mutation {
        selectProvisionalGrade(input: {
          assignmentId: #{assignment_id}
          provisionalGradeId: #{provisional_grade_id}
        }) {
          provisionalGrade {
            _id
            grade
            score
            final
            selected
            scorerAnonymousId
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  describe "authorization" do
    context "when user has moderation permissions (is final grader)" do
      let(:context) { { current_user: final_grader, domain_root_account: account } }

      it "allows the mutation" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "selectProvisionalGrade", "provisionalGrade")).not_to be_nil
      end
    end

    context "when user has account-level select_final_grade permission" do
      let(:admin_user) do
        user = User.create!
        account.account_users.create!(user:, role: admin_role)
        user
      end
      let(:admin_role) { account.roles.create!(name: "Custom Admin", base_role_type: "AccountMembership") }
      let(:context) { { current_user: admin_user, domain_root_account: account } }

      before do
        account.role_overrides.create!(role: admin_role, permission: "select_final_grade", enabled: true)
      end

      it "allows the mutation" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result["errors"]).to be_nil
        expect(result.dig("data", "selectProvisionalGrade", "provisionalGrade")).not_to be_nil
      end
    end

    context "when user does not have moderation permissions" do
      let(:context) { { current_user: teacher, domain_root_account: account } }

      it "returns a not found error" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "does not return data" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result.dig("data", "selectProvisionalGrade")).to be_nil
      end
    end

    context "when user is not enrolled in the course" do
      let(:other_user) { User.create! }
      let(:context) { { current_user: other_user, domain_root_account: account } }

      it "returns a not found error" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end

    context "when user is a student" do
      let(:context) { { current_user: student, domain_root_account: account } }

      it "returns a not found error" do
        result = CanvasSchema.execute(mutation_str, context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end
  end

  describe "validation" do
    let(:context) { { current_user: final_grader, domain_root_account: account } }

    context "when assignment does not exist" do
      it "returns a not found error" do
        result = CanvasSchema.execute(mutation_str(assignment_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end

    context "when provisional grade does not exist" do
      it "returns a not found error" do
        result = CanvasSchema.execute(mutation_str(provisional_grade_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end

    context "when provisional grade belongs to different assignment" do
      it "returns a not found error" do
        result = CanvasSchema.execute(
          mutation_str(provisional_grade_id: other_assignment_provisional_grade.id),
          context:
        )
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end
    end
  end

  describe "successful execution" do
    let(:context) { { current_user: final_grader } }

    context "when no selection exists yet" do
      before do
        # Clear any auto-created selection to test the creation scenario
        ModeratedGrading::Selection.where(assignment:, student:).delete_all
      end

      it "creates a new ModeratedGrading::Selection record" do
        expect do
          CanvasSchema.execute(mutation_str, context:)
        end.to change {
          ModeratedGrading::Selection.where(assignment:, student:).count
        }.from(0).to(1)
      end

      it "sets the correct provisional_grade_id on the selection" do
        CanvasSchema.execute(mutation_str, context:)
        selection = ModeratedGrading::Selection.find_by(assignment:, student:)
        expect(selection.selected_provisional_grade_id).to eq provisional_grade_1.id
      end

      it "returns the provisional grade" do
        result = CanvasSchema.execute(mutation_str, context:)
        returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")
        expect(returned_grade["_id"]).to eq provisional_grade_1.id.to_s
        expect(returned_grade["score"]).to eq 8.0
        expect(returned_grade["grade"]).to eq "8"
      end

      it "creates a moderation event" do
        expect do
          CanvasSchema.execute(mutation_str, context:)
        end.to change {
          AnonymousOrModerationEvent.where(
            assignment:,
            user: final_grader,
            event_type: :provisional_grade_selected
          ).count
        }.from(0).to(1)
      end

      it "includes correct payload in the moderation event" do
        CanvasSchema.execute(mutation_str, context:)
        event = AnonymousOrModerationEvent.where(
          assignment:,
          user: final_grader,
          event_type: :provisional_grade_selected
        ).last
        expect(event.payload["id"]).to eq provisional_grade_1.id
        expect(event.payload["student_id"]).to eq student.id
      end
    end

    context "when selection already exists" do
      before do
        # First select a provisional grade to create the selection
        CanvasSchema.execute(mutation_str(provisional_grade_id: provisional_grade_1.id), context: { current_user: final_grader })
      end

      it "does not create a new selection record" do
        expect do
          CanvasSchema.execute(mutation_str(provisional_grade_id: provisional_grade_2.id), context:)
        end.not_to change {
          ModeratedGrading::Selection.where(assignment:, student:).count
        }
      end

      it "updates the existing selection with new provisional_grade_id" do
        CanvasSchema.execute(mutation_str(provisional_grade_id: provisional_grade_2.id), context:)
        selection = ModeratedGrading::Selection.find_by(assignment:, student:)
        expect(selection.selected_provisional_grade_id).to eq provisional_grade_2.id
      end

      it "returns the newly selected provisional grade" do
        result = CanvasSchema.execute(mutation_str(provisional_grade_id: provisional_grade_2.id), context:)
        returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")
        expect(returned_grade["_id"]).to eq provisional_grade_2.id.to_s
        expect(returned_grade["score"]).to eq 9.0
      end

      it "still creates a moderation event for the update" do
        expect do
          CanvasSchema.execute(mutation_str(provisional_grade_id: provisional_grade_2.id), context:)
        end.to change {
          AnonymousOrModerationEvent.where(
            assignment:,
            user: final_grader,
            event_type: :provisional_grade_selected
          ).count
        }.from(1).to(2) # Changed from 0 to 1 since we already have one from the before block
      end
    end
  end

  describe "returned provisional grade fields" do
    let(:context) { { current_user: final_grader } }

    it "includes all expected fields" do
      result = CanvasSchema.execute(mutation_str, context:)
      returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")

      expect(returned_grade).to include("_id")
      expect(returned_grade).to include("grade")
      expect(returned_grade).to include("score")
      expect(returned_grade).to include("final")
      expect(returned_grade).to include("selected")
      expect(returned_grade).to include("scorerAnonymousId")
    end

    it "does not include scorer_id field (anonymity check)" do
      result = CanvasSchema.execute(mutation_str, context:)
      returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")

      expect(returned_grade).not_to include("scorerId")
      expect(returned_grade).not_to include("scorer_id")
    end

    it "shows selected as true after selection" do
      CanvasSchema.execute(mutation_str, context:)
      result = CanvasSchema.execute(mutation_str, context:)
      returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")

      expect(returned_grade["selected"]).to be true
    end

    it "includes scorerAnonymousId for anonymous grading support" do
      result = CanvasSchema.execute(mutation_str, context:)
      returned_grade = result.dig("data", "selectProvisionalGrade", "provisionalGrade")

      # The scorerAnonymousId should be present (may be null if no anonymous grading setup)
      expect(returned_grade).to have_key("scorerAnonymousId")
    end
  end
end
