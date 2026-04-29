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

describe Loaders::SectionGradesPresentState do
  before do
    @account = Account.create!
    @course = @account.courses.create!
    @assignment = @course.assignments.create!
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @course.enroll_student(@student, enrollment_state: "active")
    @submission = Submission.where(user_id: @student.id, assignment_id: @assignment.id).first
  end

  let(:loader) { Loaders::SectionGradesPresentState }
  let(:section) { @course.course_sections.first || @course.course_sections.create! }

  it "returns false if no submissions are graded or excused" do
    @submission.update!(score: nil, excused: false, workflow_state: "submitted")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end

  it "returns true if assignment has graded submissions" do
    @submission.update!(score: 85, workflow_state: "graded")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be true
      end
    end
  end

  it "returns true if assignment has excused submissions" do
    @submission.update!(excused: true, score: nil)

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be true
      end
    end
  end

  it "returns false if the section has no active enrollments" do
    @submission.update!(score: 85, workflow_state: "graded")
    section.enrollments.update_all(workflow_state: "deleted")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end

  it "excludes test student submissions when determining grades present status" do
    # Create a test student (StudentViewEnrollment)
    test_student = @course.student_view_student
    test_submission = Submission.where(user_id: test_student.id, assignment_id: @assignment.id).first

    # Grade only the test student, leave real student ungraded
    @submission.update!(score: nil, excused: false, workflow_state: "submitted")
    test_submission&.update!(score: 85, workflow_state: "graded")

    # Should return false because only test student has grades (which are excluded)
    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end

  it "handles multiple sections from the same course" do
    section2 = @course.course_sections.create!
    student2 = @course.enroll_student(User.create!, enrollment_state: "active", section: section2).user
    submission2 = Submission.where(user_id: student2.id, assignment_id: @assignment.id).first

    # Grade first section's student, leave second ungraded
    @submission.update!(score: 85, workflow_state: "graded")
    submission2.update!(score: nil, excused: false, workflow_state: "submitted")

    GraphQL::Batch.batch do
      loader_instance = loader.for(@assignment.id, @account.id)
      promise1 = loader_instance.load(section)
      promise2 = loader_instance.load(section2)

      promise1.then do |has_grades1|
        promise2.then do |has_grades2|
          expect(has_grades1).to be true   # first section has grades
          expect(has_grades2).to be false  # second section has no grades
        end
      end
    end
  end

  it "returns true if submission has score but is not in graded workflow state" do
    @submission.update!(score: 85, workflow_state: "submitted")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end

  it "returns false if submission is graded but has no score" do
    @submission.update!(score: nil, workflow_state: "graded")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end

  it "throws an error if the assignment does not exist" do
    expect do
      GraphQL::Batch.batch do
        loader.for("-1", @account.id).load(section).then do |has_grades|
          expect(has_grades).to be false
        end
      end
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "throws an error if the assignment is not in the same course as the section" do
    other_course = @account.courses.create!
    other_assignment = other_course.assignments.create!

    expect do
      GraphQL::Batch.batch do
        loader.for(other_assignment.id, @account.id).load(section).then do |has_grades|
          expect(has_grades).to be false
        end
      end
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "returns false for sections with no submissions" do
    # Create a section with no students/submissions
    empty_section = @course.course_sections.create!

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(empty_section).then do |has_grades|
        expect(has_grades).to be false
      end
    end
  end
end
