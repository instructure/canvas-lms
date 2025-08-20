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

describe AllocationRule do
  before(:once) do
    course_with_teacher(active_all: true)
    @assignment = @course.assignments.create!(
      title: "Peer Review Assignment",
      points_possible: 10,
      peer_reviews: true,
      peer_review_count: 2
    )
    @student1 = user_factory(name: "Student One")
    @student2 = user_factory(name: "Student Two")
    @student3 = user_factory(name: "Student Three")

    @course.enroll_student(@student1, enrollment_state: "active")
    @course.enroll_student(@student2, enrollment_state: "active")
    @course.enroll_student(@student3, enrollment_state: "active")
  end

  let(:valid_attributes) do
    {
      assignment: @assignment,
      course: @course,
      assessor_id: @student1.id,
      assessee_id: @student2.id
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      rule = AllocationRule.new(valid_attributes)
      expect(rule).to be_valid
    end
  end

  describe "default values" do
    it "sets default values after initialization" do
      rule = AllocationRule.new(valid_attributes)
      expect(rule.must_review).to be true
      expect(rule.review_permitted).to be true
      expect(rule.applies_to_assessor).to be true
      expect(rule.workflow_state).to eq "active"
    end

    it "doesn't override explicitly set values" do
      rule = AllocationRule.new(valid_attributes.merge(
                                  must_review: false,
                                  review_permitted: false,
                                  applies_to_assessor: false,
                                  workflow_state: "deleted"
                                ))
      expect(rule.must_review).to be false
      expect(rule.review_permitted).to be false
      expect(rule.applies_to_assessor).to be false
      expect(rule.workflow_state).to eq "deleted"
    end
  end

  describe "course_matches_assignment_course validation" do
    it "validates that course matches assignment's course" do
      other_course = Course.create!
      rule = AllocationRule.new(valid_attributes.merge(course: other_course))
      expect(rule).not_to be_valid
      expect(rule.errors[:course_id]).to include("must match assignment's course")
    end

    it "is valid when course matches assignment's course" do
      rule = AllocationRule.new(valid_attributes)
      expect(rule).to be_valid
    end
  end

  describe "assessor_and_assessee_valid validation" do
    context "when assessor is not assigned to the assignment" do
      before(:once) do
        @unassigned_student = user_factory
        @course.enroll_student(@unassigned_student, enrollment_state: "active")
      end

      it "is invalid" do
        allow_any_instance_of(Assignment).to receive(:students_with_visibility)
          .and_return(User.where(id: [@student1.id, @student2.id, @student3.id]))

        rule = AllocationRule.new(valid_attributes.merge(assessor_id: @unassigned_student.id))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessor_id]).to include("assessor (#{@unassigned_student.id}) must be a student assigned to this assignment")
      end
    end

    context "when assessor doesn't have active enrollment" do
      before(:once) do
        @inactive_student = user_factory
        enrollment = @course.enroll_student(@inactive_student)
        enrollment.deactivate
      end

      it "is invalid" do
        rule = AllocationRule.new(valid_attributes.merge(assessor_id: @inactive_student.id))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessor_id]).to include("assessor (#{@inactive_student.id}) must have an active enrollment in the course")
      end
    end

    context "when assessee is not assigned to the assignment" do
      before(:once) do
        @unassigned_student = user_factory
        @course.enroll_student(@unassigned_student, enrollment_state: "active")
      end

      it "is invalid" do
        allow_any_instance_of(Assignment).to receive(:students_with_visibility)
          .and_return(User.where(id: [@student1.id, @student2.id, @student3.id]))

        rule = AllocationRule.new(valid_attributes.merge(assessee_id: @unassigned_student.id))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessee_id]).to include("assessee (#{@unassigned_student.id}) must be a student with visibility to this assignment")
      end
    end

    context "when assessor and assessee are the same user" do
      it "is invalid" do
        rule = AllocationRule.new(valid_attributes.merge(assessee_id: @student1.id))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessee_id]).to include("assessee (#{@student1.id}) cannot be the same as the assessor")
      end
    end
  end

  describe "rule_does_not_conflict_with_existing_rules validation" do
    context "with existing rules" do
      before(:once) do
        @existing_rule = AllocationRule.create!(valid_attributes)
      end

      it "prevents conflicting review_permitted values" do
        conflicting_rule = AllocationRule.new(valid_attributes.merge(review_permitted: false))
        expect(conflicting_rule).not_to be_valid
        expect(conflicting_rule.errors[:assessee_id]).to include("conflicts with rule \"#{@student1.name} must review #{@student2.name}\"")
      end

      it "prevents conflicting must_review values" do
        conflicting_rule = AllocationRule.new(valid_attributes.merge(must_review: false))
        expect(conflicting_rule).not_to be_valid
        expect(conflicting_rule.errors[:assessee_id]).to include("conflicts with rule \"#{@student1.name} must review #{@student2.name}\"")
      end

      it "allows updating the existing rule" do
        @existing_rule.must_review = false
        expect(@existing_rule).to be_valid
      end
    end

    context "with peer review count limits" do
      it "prevents exceeding peer review count" do
        # Create 2 existing "must review" rules for student1
        AllocationRule.create!(valid_attributes)
        AllocationRule.create!(valid_attributes.merge(assessee_id: @student3.id))

        # Try to create a third one
        extra_rule = AllocationRule.new(valid_attributes.merge(
                                          assessee_id: user_factory.tap { |u| @course.enroll_student(u, enrollment_state: "active") }.id
                                        ))
        expect(extra_rule).not_to be_valid
        expect(extra_rule.errors[:must_review]).to include("would exceed the maximum number of required peer reviews (2) for this assessor")
      end

      it "allows creating rules up to the peer review count" do
        rule1 = AllocationRule.create!(valid_attributes)
        rule2 = AllocationRule.create!(valid_attributes.merge(assessee_id: @student3.id))

        expect(rule1).to be_valid
        expect(rule2).to be_valid
      end
    end
  end

  describe "check_completed_review_conflicts" do
    before(:once) do
      @submission1 = @assignment.submit_homework(@student2)
      @submission2 = @assignment.submit_homework(@student3)
      @submission_assessor = @assignment.submit_homework(@student1)
    end

    context "when assessor has completed maximum reviews" do
      before(:once) do
        AssessmentRequest.create!(
          assessor: @student1,
          user: @student2,
          asset: @submission1,
          assessor_asset: @submission_assessor,
          workflow_state: "completed"
        )
        AssessmentRequest.create!(
          assessor: @student1,
          user: @student3,
          asset: @submission2,
          assessor_asset: @submission_assessor,
          workflow_state: "completed"
        )
      end

      it "prevents adding new must_review rules" do
        new_student = user_factory
        @course.enroll_student(new_student, enrollment_state: "active")

        rule = AllocationRule.new(valid_attributes.merge(
                                    assessee_id: new_student.id,
                                    must_review: true
                                  ))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessor_id]).to include("conflicts with completed peer reviews. #{@student1.name} has already completed 2 peer review(s) for: #{@student2.name}, #{@student3.name}")
      end
    end

    context "when trying to prohibit a completed review" do
      before(:once) do
        AssessmentRequest.create!(
          assessor: @student1,
          user: @student2,
          asset: @submission1,
          assessor_asset: @submission_assessor,
          workflow_state: "completed"
        )
      end

      it "prevents creating review_permitted: false rules" do
        rule = AllocationRule.new(valid_attributes.merge(review_permitted: false))
        expect(rule).not_to be_valid
        expect(rule.errors[:assessee_id]).to include("conflicts with completed peer review. #{@student1.name} has already reviewed #{@student2.name}")
      end
    end
  end

  describe "scopes" do
    before(:once) do
      @rule1 = AllocationRule.create!(valid_attributes)
      @rule2 = AllocationRule.create!(valid_attributes.merge(
                                        assessor_id: @student2.id,
                                        assessee_id: @student1.id
                                      ))

      # Rule in different course
      other_course = Course.create!
      other_assignment = other_course.assignments.create!(title: "Other Assignment", peer_reviews: true, peer_review_count: 2)
      other_student = user_factory
      other_course.enroll_student(other_student, enrollment_state: "active")
      other_course.enroll_student(@student1, enrollment_state: "active")

      @other_rule = AllocationRule.create!(
        assignment: other_assignment,
        course: other_course,
        assessor_id: @student1.id,
        assessee_id: other_student.id
      )
    end

    describe ".for_user_in_course" do
      it "returns rules where user is assessor or assessee in the specified course" do
        rules = AllocationRule.for_user_in_course(@student1.id, @course.id)
        expect(rules).to include(@rule1, @rule2)
        expect(rules).not_to include(@other_rule)
      end

      it "returns empty when user has no rules in the course" do
        rules = AllocationRule.for_user_in_course(@student3.id, @course.id)
        expect(rules).to be_empty
      end
    end
  end

  describe "associations" do
    before(:once) do
      @rule = AllocationRule.create!(valid_attributes)
    end

    it "belongs to course" do
      expect(@rule.course).to eq @course
    end

    it "belongs to assignment" do
      expect(@rule.assignment).to eq @assignment
    end

    it "belongs to assessor" do
      expect(@rule.assessor).to eq @student1
    end

    it "belongs to assessee" do
      expect(@rule.assessee).to eq @student2
    end
  end
end
