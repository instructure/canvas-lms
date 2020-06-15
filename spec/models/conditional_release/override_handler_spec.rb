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

require_relative '../../conditional_release_spec_helper'
require_dependency "conditional_release/override_handler"

module ConditionalRelease
  describe OverrideHandler do
    context 'handle_grade_change' do
      before :once do
        # set up a trigger assignment with rules and whatnot
        course_with_student(:active_all => true)
        @trigger_assmt = @course.assignments.create!(:points_possible => 10, submission_types: "online_text_entry")
        @sub = @trigger_assmt.submit_homework(@student, body: "hi")

        @set1_assmt1 = @course.assignments.create!(:only_visible_to_overrides => true) # one in one set
        @set2_assmt1 = @course.assignments.create!(:only_visible_to_overrides => true)
        @set2_assmt2 = @course.assignments.create!(:only_visible_to_overrides => true) # two in one set
        @set3a_assmt = @course.assignments.create!(:only_visible_to_overrides => true) # two sets in one range - will have to choose
        @set3b_assmt = @course.assignments.create!(:only_visible_to_overrides => true)

        ranges = [
          ScoringRange.new(:lower_bound => 0.7, :upper_bound => 1.0, :assignment_sets => [
            AssignmentSet.new(:assignment_set_associations => [AssignmentSetAssociation.new(:assignment_id => @set1_assmt1.id)])
          ]),
          ScoringRange.new(:lower_bound => 0.4, :upper_bound => 0.7, :assignment_sets => [
            AssignmentSet.new(:assignment_set_associations => [
              AssignmentSetAssociation.new(:assignment_id => @set2_assmt1.id),
              AssignmentSetAssociation.new(:assignment_id => @set2_assmt2.id)
            ])
          ]),
          ScoringRange.new(:lower_bound => 0, :upper_bound => 0.4, :assignment_sets => [
            AssignmentSet.new(:assignment_set_associations => [AssignmentSetAssociation.new(:assignment_id => @set3a_assmt.id)]),
            AssignmentSet.new(:assignment_set_associations => [AssignmentSetAssociation.new(:assignment_id => @set3b_assmt.id)])
          ])
        ]
        @rule = @course.conditional_release_rules.create!(:trigger_assignment => @trigger_assmt, :scoring_ranges => ranges)

        Account.default.tap do |ra|
          ra.settings[:use_native_conditional_release] = true
          ra.save!
        end
        @course.enable_feature!(:conditional_release)
      end

      it "should require native conditional release" do
        expect(ConditionalRelease::Service).to receive(:natively_enabled_for_account?).and_return(false).once
        expect(ConditionalRelease::OverrideHandler).to_not receive(:handle_grade_change)
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
      end

      it "should check that the assignment is actually a trigger assignment" do
        @rule.destroy!
        expect(ConditionalRelease::OverrideHandler).to_not receive(:handle_grade_change)
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
      end

      it "should automatically assign to the proper assignment set when graded" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1)
        expect(visible_assmts).to_not include(@set2_assmt1) # and only the top set
      end

      it "should automatically unassign if the grade changes" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set1_assmt1)
        expect(visible_assmts).to include(@set2_assmt1)
        expect(visible_assmts).to include(@set2_assmt2) # assign to both
      end

      it "should reuse an existing override when assigning (and leave it be when unassigning)" do
        old_student = @student
        student_in_course(:course => @course, :active_all => true)
        @trigger_assmt.grade_student(old_student, grade: 9, grader: @teacher)
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        expect(@set1_assmt1.assignment_overrides.count).to eq 1
        expect(@set1_assmt1.assignment_overrides.first.assignment_override_students.count).to eq 2

        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # now unassign
        expect(DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a).to_not include(@set1_assmt1)
        expect(DifferentiableAssignment.scope_filter(@course.assignments, old_student, @course).to_a).to include(@set1_assmt1)
      end

      it "should not automatically assign when there are multiple applicable sets for the student to choose from" do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher) # should automatically assign to top set
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set3a_assmt)
        expect(visible_assmts).to_not include(@set3b_assmt)
      end
    end
  end
end
