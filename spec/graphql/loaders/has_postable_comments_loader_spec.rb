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

describe Loaders::HasPostableCommentsLoader do
  before do
    account = Account.create!
    course = account.courses.create!
    @teacher = course_with_user("TeacherEnrollment", course: @course, name: "Teacher", active_all: true).user
    @first_student = course.enroll_student(User.create!, enrollment_state: "active").user
    @second_student = course.enroll_student(User.create!, enrollment_state: "active").user
    @third_student = course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = course.assignments.create!(title: "Example Assignment")
  end

  let(:submission_1) { @assignment.submissions.find_by(user: @first_student) }
  let(:submission_2) { @assignment.submissions.find_by(user: @second_student) }
  let(:submission_3) { @assignment.submissions.find_by(user: @third_student) }

  it "correctly loads whether submissions have postable comments" do
    @assignment.submit_homework(@first_student, body: "help my legs are stuck under my desk!")
    @assignment.submit_homework(@second_student, body: "hello world!")

    # Submission 1: Has at least one postable comment (hidden: true, draft: false)
    submission_1.add_comment(author: @teacher, comment: "Hidden comment", hidden: true, draft: false)
    submission_1.add_comment(author: @teacher, comment: "Comment", hidden: false, draft: false)

    # Submission 2: No postable comments (hidden: false, draft: false)
    submission_2.add_comment(author: @teacher, comment: "Comment", hidden: false, draft: false)

    result = GraphQL::Batch.batch do
      Loaders::HasPostableCommentsLoader.load_many([submission_1.id, submission_2.id, submission_3.id])
    end

    expect(result).to eq([true, false, false])
  end
end
