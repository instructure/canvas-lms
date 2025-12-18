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
        run_jobs
      end

      it "automatically assigns to the proper assignment set when graded" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        run_jobs
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1)
        expect(visible_assmts).to_not include(@set2_assmt1) # and only the top set
      end

      it "automatically unassigns if the grade changes" do
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        run_jobs
        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        run_jobs
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        run_jobs
        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        run_jobs

        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set1_assmt1)
        expect(visible_assmts).to include(@set2_assmt1)
        expect(visible_assmts).to include(@set2_assmt2) # assign to both
      end

      it "reuses an existing override when assigning (and leave it be when unassigning)" do
        old_student = @student
        student_in_course(course: @course, active_all: true)
        @trigger_assmt.grade_student(old_student, grade: 9, grader: @teacher)
        run_jobs
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs
        expect(@set1_assmt1.assignment_overrides.count).to eq 1
        expect(@set1_assmt1.assignment_overrides.first.assignment_override_students.count).to eq 2

        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # now unassign
        run_jobs
        expect(DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a).to_not include(@set1_assmt1)
        expect(DifferentiableAssignment.scope_filter(@course.assignments, old_student, @course).to_a).to include(@set1_assmt1)
      end

      it "does not automatically assign when there are multiple applicable sets for the student to choose from" do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher)
        run_jobs
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to_not include(@set3a_assmt)
        expect(visible_assmts).to_not include(@set3b_assmt)
      end

      it "does not accidentally relock an assignment if the same item is in two ranges we're switching between" do
        @set2 = @set2_assmt1.conditional_release_associations.first.assignment_set
        @set2.assignment_set_associations.create!(assignment: @set1_assmt1) # add the set1 assignment to set2 for inexplicable reasons

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher) # should automatically assign to top set
        run_jobs
        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1) # should still unlock

        @trigger_assmt.grade_student(@student, grade: 5, grader: @teacher) # actually nvm should automatically assign to middle set
        run_jobs
        visible_assmts2 = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts2).to include(@set1_assmt1) # should stay unlocked even though we technically dropped set1
      end

      it "reuses existing override when manually edited due dates exist without course pacing" do
        old_student = @student
        student_in_course(course: @course, active_all: true)

        @trigger_assmt.grade_student(old_student, grade: 9, grader: @teacher)
        run_jobs

        override = @set1_assmt1.assignment_overrides.first
        manual_due_date = 3.days.from_now
        override.update!(due_at: manual_due_date)

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs

        expect(@set1_assmt1.assignment_overrides.count).to eq 1
        final_override = @set1_assmt1.assignment_overrides.first
        expect(final_override.assignment_override_students.count).to eq 2
        expect(final_override.due_at.to_i).to eq manual_due_date.to_i
      end

      it "inherits due date from Mastery Paths Noop override when creating ADHOC overrides" do
        noop_due_date = 5.days.from_now
        @set1_assmt1.assignment_overrides.create!(set_type: "Noop", title: "Mastery Paths", due_at: noop_due_date)

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs

        adhoc_override = @set1_assmt1.assignment_overrides.where(set_type: "ADHOC").first
        expect(adhoc_override).to be_present
        expect(adhoc_override.due_at.to_i).to eq noop_due_date.to_i
      end

      it "groups students in same override when course pacing gives them the same due date" do
        old_student = @student
        student_in_course(course: @course, active_all: true)

        module1 = @course.context_modules.create!(name: "Module 1")
        module1.add_item(type: "assignment", id: @set1_assmt1.id)

        course_pace = course_pace_model(course: @course)
        course_pace.course_pace_module_items.create!(
          duration: 5,
          module_item: @set1_assmt1.context_module_tags.first,
          root_account_id: @course.root_account_id
        )
        course_pace.publish

        @trigger_assmt.grade_student(old_student, grade: 9, grader: @teacher)
        run_jobs
        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs

        expect(@set1_assmt1.assignment_overrides.where(set_type: "ADHOC").count).to eq 1
        override = @set1_assmt1.assignment_overrides.where(set_type: "ADHOC").first
        expect(override.assignment_override_students.count).to eq 2
        expect(override.assignment_override_students.pluck(:user_id)).to contain_exactly(old_student.id, @student.id)
      end

      it "assigns students with 100% score to the correct mastery path" do
        @rule.scoring_ranges.first.update!(lower_bound: 0.8, upper_bound: 1.0)

        @trigger_assmt.grade_student(@student, grade: 10, grader: @teacher)
        run_jobs

        visible_assmts = DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a
        expect(visible_assmts).to include(@set1_assmt1)
      end

      it "assigns due dates to quizzes with course pacing enabled" do
        quiz = @course.quizzes.create!(title: "Quiz 1", quiz_type: "assignment")
        quiz.workflow_state = "available"
        quiz.save!

        @set1_assmt1.destroy!
        @rule.scoring_ranges.first.assignment_sets.first.assignment_set_associations.create!(
          assignment: quiz.assignment,
          root_account_id: @course.root_account_id
        )

        module1 = @course.context_modules.create!(name: "Module 1")
        module1.add_item(type: "quiz", id: quiz.id)

        course_pace = course_pace_model(course: @course)
        course_pace.course_pace_module_items.create!(
          duration: 5,
          module_item: quiz.context_module_tags.first,
          root_account_id: @course.root_account_id
        )
        course_pace.publish

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs

        adhoc_override = quiz.assignment_overrides.where(set_type: "ADHOC").first
        expect(adhoc_override).to be_present
        expect(adhoc_override.due_at).to be_present
      end

      it "assigns due dates to graded discussions with course pacing enabled" do
        discussion = @course.discussion_topics.create!(
          title: "Discussion 1",
          assignment: @course.assignments.create!(title: "Discussion 1", submission_types: "discussion_topic")
        )

        @set1_assmt1.destroy!
        @rule.scoring_ranges.first.assignment_sets.first.assignment_set_associations.create!(
          assignment: discussion.assignment,
          root_account_id: @course.root_account_id
        )

        module1 = @course.context_modules.create!(name: "Module 1")
        module1.add_item(type: "discussion_topic", id: discussion.id)

        course_pace = course_pace_model(course: @course)
        course_pace.course_pace_module_items.create!(
          duration: 5,
          module_item: discussion.context_module_tags.first,
          root_account_id: @course.root_account_id
        )
        course_pace.publish

        @trigger_assmt.grade_student(@student, grade: 9, grader: @teacher)
        run_jobs

        adhoc_override = discussion.assignment.assignment_overrides.where(set_type: "ADHOC").first
        expect(adhoc_override).to be_present
        expect(adhoc_override.due_at).to be_present
      end
    end

    context "handle_assignment_set_selection" do
      before :once do
        @trigger_assmt.grade_student(@student, grade: 2, grader: @teacher) # set up the choice
        run_jobs
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
        run_jobs
        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)

        expect(@set3a_assmt.assignment_overrides.count).to eq 1
        expect(@set3a_assmt.assignment_overrides.first.assignment_override_students.count).to eq 2

        ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_b.id) # now unassign
        expect(DifferentiableAssignment.scope_filter(@course.assignments, @student, @course).to_a).to_not include(@set3a_assmt)
        expect(DifferentiableAssignment.scope_filter(@course.assignments, old_student, @course).to_a).to include(@set3a_assmt)
      end

      context "with course pace" do
        before :once do
          @course.update start_at: "2021-06-30", restrict_enrollments_to_course_dates: true, time_zone: "UTC"
          @course.enable_course_paces = true
          @course.save!
          @module = @course.context_modules.create!
          @tags = [@trigger_assmt, @set1_assmt1, @set2_assmt1, @set3a_assmt, @set3b_assmt].map do |assignment|
            assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
          end
          @course_pace = @course.course_paces.create! workflow_state: "active", published_at: Time.zone.now, selected_days_to_skip: []
          @course_pace_module_items = @tags.map do |tag|
            @course_pace.course_pace_module_items.create! module_item: tag
          end

          @course_pace.publish
        end

        it "creates the assignment override with the due date from the course pace" do
          ConditionalRelease::OverrideHandler.handle_assignment_set_selection(@student, @trigger_assmt, @set_a.id)

          override = @set3a_assmt.assignment_overrides.last

          expect(override.due_at).to eq Time.zone.now.end_of_day
        end
      end
    end
  end
end
