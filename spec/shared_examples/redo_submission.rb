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

RSpec.shared_examples "a submission redo_submission action" do |controller|
  before(:once) do
    course_with_student(active_all: true)
    @teacher = User.create!
    @course.enroll_teacher(@teacher)
  end

  it "does not allow on assignments without due date" do
    @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@teacher)
    put :redo_submission, params: @params
    assert_unauthorized
  end

  it "does not allow from users without the right permissions" do
    @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload", due_at: 3.days.from_now)
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@student)
    put :redo_submission, params: @params
    assert_unauthorized
  end

  it "allows on assignments with due date" do
    @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload", due_at: 3.days.from_now)
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@teacher)
    put :redo_submission, params: @params
    assert_status 204
    expect(@submission.reload.redo_request).to be true
  end

  it "allows on assignments with a lock date in the future and proper permissions" do
    @assignment = @course.assignments.create!(
      title: "some assignment",
      submission_types: "online_url,online_upload",
      due_at: 3.days.from_now,
      lock_at: 3.days.from_now
    )
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@teacher)
    put :redo_submission, params: @params
    assert_status 204
    expect(@submission.reload.redo_request).to be true
  end

  it "does not allow on assignments with a lock date in the future and improper permissions" do
    @assignment = @course.assignments.create!(
      title: "some assignment",
      submission_types: "online_url,online_upload",
      due_at: 3.days.from_now,
      lock_at: 3.days.from_now
    )
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@student)
    put :redo_submission, params: @params
    assert_unauthorized
  end

  it "does not allow on assignments with a lock date in the past and proper permissions" do
    @assignment = @course.assignments.create!(
      title: "some assignment",
      submission_types: "online_url,online_upload",
      due_at: 3.days.ago,
      lock_at: 3.days.ago
    )
    @submission = @assignment.submit_homework(@user)
    @resource_pair = (controller == :anonymous_submissions) ? { anonymous_id: @submission.anonymous_id } : { submission_id: @user.id }
    @params = { course_id: @course.id, assignment_id: @assignment.id }.merge(@resource_pair)
    user_session(@teacher)
    put :redo_submission, params: @params
    assert_status 422
    expect(@submission.reload.redo_request).to be false
  end
end
