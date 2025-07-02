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
  end

  describe ".add_submission_status_column" do
    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions) => { column: }
      expect(column).to eq("db_submission_status")
    end

    it "returns a scope with the db_submission_status column added" do
      @assignment.grade_student(@student1, score: 10, grader: @teacher)
      ComputedSubmissionColumnBuilder.add_submission_status_column(@assignment.submissions) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_submission_status).to eq("graded")
      expect(sub2.db_submission_status).to eq("not_submitted")
    end
  end

  describe ".add_submission_status_priority_column" do
    let(:priorities) { { not_graded: 1, resubmitted: 2, not_submitted: 3, graded: 4, other: 5 } }

    it "returns the generated column name" do
      ComputedSubmissionColumnBuilder.add_submission_status_priority_column(@assignment.submissions, priorities) => { column: }
      expect(column).to eq("db_submission_status_priority")
    end

    it "returns a scope with the db_submission_status_priority column added" do
      @assignment.grade_student(@student1, score: 10, grader: @teacher)
      ComputedSubmissionColumnBuilder.add_submission_status_priority_column(@assignment.submissions, priorities) => { scope: }
      sub1 = scope.find_by!(user: @student1)
      sub2 = scope.find_by!(user: @student2)
      expect(sub1.db_submission_status_priority).to eq(priorities.fetch(:graded))
      expect(sub2.db_submission_status_priority).to eq(priorities.fetch(:not_submitted))
    end

    it "yells at you if priorities are missing" do
      expect do
        ComputedSubmissionColumnBuilder.add_submission_status_priority_column(
          @assignment.submissions,
          priorities.except(:resubmitted)
        )
      end.to raise_error(KeyError, "key not found: :resubmitted")
    end
  end
end
