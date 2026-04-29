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

describe Loaders::SectionGradePostedState do
  before do
    @account = Account.create!
    @course = @account.courses.create!
    @assignment = @course.assignments.create!
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @course.enroll_student(@student, enrollment_state: "active")
    @submission = Submission.where(user_id: @student.id, assignment_id: @assignment.id).first
  end

  let(:loader) { Loaders::SectionGradePostedState }
  let(:section) { @course.course_sections.first || @course.course_sections.create! }

  it "returns false if the assignment has not been graded" do
    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be false
      end
    end
  end

  it "returns true if the assignment has been graded" do
    @submission.update!(posted_at: Time.zone.now)

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be true
      end
    end
  end

  it "returns false if the assignment has been graded but the section has no active enrollments" do
    @submission.update!(posted_at: Time.zone.now)
    section.enrollments.update_all(workflow_state: "deleted")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be false
      end
    end
  end

  it "throws an error if the assignment does not exist" do
    expect do
      GraphQL::Batch.batch do
        loader.for("-1", @account.id).load(section).then do |is_posted|
          expect(is_posted).to be false
        end
      end
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "throws an error if the assignment is not in the same course as the section" do
    other_course = @account.courses.create!
    other_assignment = other_course.assignments.create!

    expect do
      GraphQL::Batch.batch do
        loader.for(other_assignment.id, @account.id).load(section).then do |is_posted|
          expect(is_posted).to be false
        end
      end
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "excludes test student submissions when determining grade posting status" do
    # Create a test student (StudentViewEnrollment)
    test_student = @course.student_view_student
    test_submission = Submission.where(user_id: test_student.id, assignment_id: @assignment.id).first

    # Post the real student's grade but leave test student unposted
    @submission.update!(posted_at: Time.zone.now)
    test_submission&.update!(posted_at: nil)

    # Should return true because only real student submissions matter
    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be true
      end
    end
  end

  it "handles multiple sections from the same course" do
    section2 = @course.course_sections.create!
    student2 = @course.enroll_student(User.create!, enrollment_state: "active", section: section2).user
    Submission.where(user_id: student2.id, assignment_id: @assignment.id).first

    # Post first section's grade, leave second unposted
    @submission.update!(posted_at: Time.zone.now)

    GraphQL::Batch.batch do
      loader_instance = loader.for(@assignment.id, @account.id)
      promise1 = loader_instance.load(section)
      promise2 = loader_instance.load(section2)

      promise1.then do |is_posted1|
        promise2.then do |is_posted2|
          expect(is_posted1).to be true  # first section is posted
          expect(is_posted2).to be false # second section is not posted
        end
      end
    end
  end

  it "returns false if assignment has excused but unposted submissions" do
    @submission.update!(excused: true, posted_at: nil)

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be false
      end
    end
  end

  it "returns true if assignment has ungraded submissions that are not excused" do
    @submission.update!(score: nil, excused: false, posted_at: nil, workflow_state: "submitted")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be true
      end
    end
  end

  it "returns false if assignment has graded but unposted submissions" do
    @submission.update!(score: 85, excused: false, posted_at: nil, workflow_state: "graded")

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be false
      end
    end
  end
end
