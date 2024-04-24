# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../conditional_release_spec_helper"

module ConditionalRelease
  describe OverrideHandler do
    before :once do
      setup_course_with_native_conditional_release
    end

    context "handle_grade_change" do
      it "checks that the assignment is actually a trigger assignment" do
        @rule.destroy!
        expect(ConditionalRelease::OverrideHandler).to_not receive(:handle_grade_change)
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
      end

      it "automatically assigns to the proper assignment set when graded" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1)
        expect(visible_assmts).to_not include(@set2_assmt1) # and only the top set
      end

      it "automatically unassigns if the grade changes" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set

        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set1_assmt1)
        expect(visible_assmts).to include(@set2_assmt1)
        expect(visible_assmts).to include(@set2_assmt2) # assign to both
      end

      it "reuses an existing override when assigning (and leave it be when unassigning)" do
        old_student = @student
        student_in_course(course: @course, active_all: true)
        @trigger_assmt.grade_student(old_student, grade: 9, grader: @teacher)
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        expect(@set1_assmt1.assignment_overrides.count).to eq 1
        expect(@set1_assmt1.assignment_overrides.first.assignment_override_students.count).to eq 2

        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # now unassign
        expect(DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a).to_not include(@set1_assmt1)
        expect(DifferentiableAssignment.scope_filter(@course.assignments, old_student, @course).to_a).to include(@set1_assmt1)
      end

      it "does not automatically assign when there are multiple applicable sets for the student to choose from" do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher)
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set3a_assmt)
        expect(visible_assmts).to_not include(@set3b_assmt)
      end

      it "does not accidentally relock an assignment if the same item is in two ranges we're switching between" do
        @set2 = @set2_assmt1.conditional_release_associations.first.assignment_set
        @set2.assignment_set_associations.create!(assignment: @set1_assmt1) # add the set1 assignment to set2 for inexplicable reasons

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1) # should still unlock

        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        visible_assmts2 = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts2).to include(@set1_assmt1) # should stay unlocked even though we technically dropped set1
      end
    end

    context "handle_assignment_set_selection" do
      before :once do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher) # set up the choice
        @set_a = @set3a_assmt.conditional_release_associations.first.assignment_set
        @set_b = @set3b_assmt.conditional_release_associations.first.assignment_set
        @invalid_set = @set1_assmt1.conditional_release_associations.first.assignment_set
      end

      it "checks that a rule exists for the assignment" do
        @rule.destroy!
        expect do
          ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "checks that the submission is actually graded" do
        Submission.where(id: @sub).update_all(posted_at: nil)
        expect do
          ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "checks that the assignment set is valid for the submissions core" do
        expect do
          ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @invalid_set.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates the assignment override" do
        assignment_ids = ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)
        expect(assignment_ids).to eq [@set3a_assmt.id]
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set3a_assmt)
        expect(visible_assmts).to_not include(@set3b_assmt)
      end

      it "is able to switch" do
        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)
        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_b.id)
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set3b_assmt)
        expect(visible_assmts).to_not include(@set3a_assmt)
      end

      it "reuses an existing override when assigning (and leave it be when unassigning)" do
        old_student = @student
        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(old_student, @trigger_assmt, @set_a.id)
        student_in_course(course: @course, active_all: true)
        @trigger_assmt.grade_student(@student, grade: 3, grader: @teacher)
        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)

        expect(@set3a_assmt.assignment_overrides.count).to eq 1
        expect(@set3a_assmt.assignment_overrides.first.assignment_override_students.count).to eq 2

        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_b.id) # now unassign
        expect(DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a).to_not include(@set3a_assmt)
        expect(DifferentiableAssignment.scope_filter(@course.assignments, old_student, @course).to_a).to include(@set3a_assmt)
      end
    end
  end
end
