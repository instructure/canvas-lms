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
    @submission.update!(posted_at: Time.now)

    GraphQL::Batch.batch do
      loader.for(@assignment.id, @account.id).load(section).then do |is_posted|
        expect(is_posted).to be true
      end
    end
  end

  it "returns false if the assignment has been graded but the section has no active enrollments" do
    @submission.update!(posted_at: Time.now)
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
end
