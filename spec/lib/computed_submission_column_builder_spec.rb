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

describe ComputedSubmissionColumnBuilder do
  before do
    @course = Course.create!(name: "Test Course")
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user
    @assignment = @course.assignments.create!(
      name: "Test Assignment",
      submission_types: "online_text_entry",
      points_possible: 10
    )
  end

  describe ".add_group_name_column" do
    before do
      group_category = @course.group_categories.create!(name: "Fruits")
      group = group_category.groups.create!(name: "Apples", context: @course)
      group.group_memberships.create!(user: @student1)
      @assignment.update!(group_category:)
    end

    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_group_name_column(@assignment.submissions, @assignment) => { column: }
      expect(column).to eq("db_group_name")
    end

    it "returns a scope with the db_group_name column added" do
      ComputedSubmissionColumnBuilder.add_group_name_column(@assignment.submissions, @assignment) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_group_name).to eq("Apples")
      expect(sub2.db_group_name).to be_nil
    end
  end

  describe ".add_needs_grading_column" do
    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions) => { column: }
      expect(column).to eq("db_needs_grading")
    end

    it "returns a scope with the db_needs_grading column added" do
      @assignment.submit_homework(@student2, body: "hello!")
      ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_needs_grading).to be false
      expect(sub2.db_needs_grading).to be true
    end

    context "with moderated assignment" do
      before do
        @final_grader = @teacher
        @assignment.update!(moderated_grading: true, grader_count: 2, final_grader: @final_grader)
        @prov_grader1 = teacher_in_course(course: @course, active_all: true).user
        @prov_grader2 = teacher_in_course(course: @course, active_all: true).user
        @assignment.submit_homework(@student1, body: "hello!")
        @assignment.submit_homework(@student2, body: "hello!")
      end

      it "returns false for needs_grading when provisional grader has already graded" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader1, provisional: true)
        ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub1 = scope.find_by!(user: @student1)
        sub2 = scope.find_by!(user: @student2)
        expect(sub1.db_needs_grading).to be false # already graded by this user
        expect(sub2.db_needs_grading).to be true  # not yet graded by this user
      end

      it "returns true for needs_grading when provisional grade has null score" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader1, provisional: true)
        pg = @assignment.provisional_grades.find_by!(scorer: @prov_grader1, submission_id: @student1.submissions.first.id)
        pg.update!(score: nil)
        ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub1 = scope.find_by!(user: @student1)
        expect(sub1.db_needs_grading).to be true # null score means still needs grading
      end

      it "ignores provisional grades after grades are published" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader1, provisional: true)
        @assignment.update!(grades_published_at: Time.zone.now)
        # After publication, the provisional grade logic should not apply
        # The submission doesn't have a real grade yet (provisional grades aren't copied to submission automatically)
        ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub1 = scope.find_by!(user: @student1)
        sub2 = scope.find_by!(user: @student2)
        # Both still need grading because provisional grades haven't been published to submissions
        expect(sub1.db_needs_grading).to be true
        expect(sub2.db_needs_grading).to be true
      end

      it "works correctly without current_user parameter" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader1, provisional: true)
        ComputedSubmissionColumnBuilder.add_needs_grading_column(@assignment.submissions) => { scope: }
        sub1 = scope.find_by!(user: @student1)
        sub2 = scope.find_by!(user: @student2)
        # Without current_user, should still return true (uses base logic only)
        expect(sub1.db_needs_grading).to be true
        expect(sub2.db_needs_grading).to be true
      end
    end
  end

  describe ".add_submission_status_column" do
    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @teacher) => { column: }
      expect(column).to eq("db_submission_status")
    end

    it "returns a scope with the db_submission_status column added" do
      @assignment.grade_student(@student1, score: 10, grader: @teacher)
      ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @teacher) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_submission_status).to eq("graded")
      expect(sub2.db_submission_status).to eq("not_submitted")
    end

    context "status for student that has submitted on a moderated assignment" do
      before do
        @final_grader = @teacher
        @assignment.update!(moderated_grading: true, grader_count: 1, final_grader: @final_grader)
        @prov_grader1 = teacher_in_course(course: @course, active_all: true).user
        @prov_grader2 = teacher_in_course(course: @course, active_all: true).user
        @assignment.submit_homework(@student1, body: "hello!")
      end

      it "returns not_gradeable when max graders have been reached, and current_user isn't one of the graders" do
        @assignment.grade_student(@student2, score: 10, grader: @prov_grader2, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_gradeable")
      end

      it "returns not_graded when max graders have been reached, but current_user is the final grader" do
        @assignment.grade_student(@student2, score: 10, grader: @prov_grader2, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @final_grader) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end

      it "returns not_graded when max graders have been reached, and current_user is not one of the graders, but grades have been released" do
        @assignment.grade_student(@student2, score: 10, grader: @prov_grader2, provisional: true)
        @assignment.update!(grades_published_at: Time.zone.now)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end

      it "returns graded when the current_user is the final grader and has selected a provisional grade" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader2, provisional: true)
        provisional_grade = @assignment.provisional_grades.find_by!(scorer: @prov_grader2)
        selection = @assignment.moderated_grading_selections.find_by!(student: @student1)
        selection.update!(provisional_grade:)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @final_grader) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("graded")
      end

      it "returns not_graded when the current_user is the final grader and has graded the submission, but hasn't selected a provisional grade" do
        @assignment.grade_student(@student1, score: 10, grader: @final_grader, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @final_grader) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end

      it "returns graded when the current_user is a provisional grader and has graded the submission" do
        @assignment.grade_student(@student1, score: 10, grader: @prov_grader1, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("graded")
      end

      it "returns not_graded when max graders have been reached, and current_user is one of the graders" do
        @assignment.grade_student(@student2, score: 10, grader: @prov_grader1, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end

      it "returns not_graded when max graders have not been reached" do
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end

      it "does not count the final grader towards the max grader limit, and returns not_graded accordingly" do
        @assignment.grade_student(@student2, score: 10, grader: @final_grader, provisional: true)
        ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions, @prov_grader1) => { scope: }
        sub = scope.find_by!(user: @student1)
        expect(sub.db_submission_status).to eq("not_graded")
      end
    end
  end

  describe ".add_submission_status_priority_column" do
    let(:priorities) { { not_graded: 1, resubmitted: 2, not_submitted: 3, graded: 4, not_gradeable: 5, other: 6 } }

    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_submission_status_priority_column(@assignment.submissions, @teacher, priorities) => { column: }
      expect(column).to eq("db_submission_status_priority")
    end

    it "returns a scope with the db_submission_status_priority column added" do
      @assignment.grade_student(@student1, score: 10, grader: @teacher)
      ComputedSubmissionColumnBuilder.add_submission_status_priority_column(@assignment.submissions, @teacher, priorities) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_submission_status_priority).to eq(priorities.fetch(:graded))
      expect(sub2.db_submission_status_priority).to eq(priorities.fetch(:not_submitted))
    end

    it "yells at you if priorities are missing" do
      expect do
        ComputedSubmissionColumnBuilder.add_submission_status_priority_column(
          @assignment.submissions,
          @teacher,
          priorities.except(:resubmitted)
        )
      end.to raise_error(KeyError, "key not found: :resubmitted")
    end
  end
end
