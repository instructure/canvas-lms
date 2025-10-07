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

describe DataFixup::SetExpirationDateOnStudentAccessTokens do
  subject do
    DataFixup::SetExpirationDateOnStudentAccessTokens.run
  end

  let(:course) do
    c = course_model
    c.offer!
    c
  end

  it "only finds access tokens for students, not teachers" do
    student = student_in_course(course:, active_enrollment: true).user
    student_access_token = AccessToken.create!(user: student, purpose: "test")

    teacher = teacher_in_course(course:, active_enrollment: true).user
    teacher_access_token = AccessToken.create!(user: teacher, purpose: "test")

    subject

    expected_expiration_date = 120.days.from_now
    expect(student_access_token.reload.permanent_expires_at)
      .to be_within(10.minutes).of(expected_expiration_date)

    expect(teacher_access_token.reload.permanent_expires_at)
      .to be_nil
  end

  it "does not affect tokens that were already going to expire within 120 days" do
    student = student_in_course(course:, active_enrollment: true).user
    early_expiring_access_token = AccessToken.create!(user: student, purpose: "test", permanent_expires_at: 30.days.from_now)

    initial_expiration_date = early_expiring_access_token.permanent_expires_at

    subject

    expect(early_expiring_access_token.reload.permanent_expires_at).to eq(initial_expiration_date)
  end

  it "does not affect a user who has one student enrollment and one teacher enrollment" do
    student_teacher_hybrid = student_in_course(course:, active_enrollment: true).user

    # user is a teacher in "other_course"
    other_course = course_model
    other_course.offer!
    teacher_in_course(course: other_course, user: student_teacher_hybrid, active_enrollment: true)

    access_token = AccessToken.create!(user: student_teacher_hybrid, purpose: "student teacher hybrid")

    subject

    expect(access_token.reload.permanent_expires_at).to be_nil
  end

  it "does not affect access tokens associated with API or LTI developer keys" do
    dk = developer_key_model
    dk_access_token = dk.access_tokens.create!(purpose: "not on default dev key")

    lti_key = lti_developer_key_model
    lti_access_token = lti_key.access_tokens.create!(purpose: "lti access token")

    subject

    expect(dk_access_token.permanent_expires_at).to be_nil
    expect(lti_access_token.permanent_expires_at).to be_nil
  end

  it "affects users whose teacher enrollments are all in the past" do
    past_course = course_model(start_at: 14.days.ago, conclude_at: 7.days.ago)
    past_course.offer!
    past_course.complete!
    former_teacher = teacher_in_course(course: past_course, active_enrollment: true).user
    former_teacher.enrollments.last.update(workflow_state: "completed")

    former_teacher_access_token = AccessToken.create!(user: former_teacher, purpose: "former teacher")

    student_in_course(course:, user: former_teacher, active_enrollment: true)

    # A user with no enrollments
    no_enrollments_user = user_model
    no_enrollments_token = AccessToken.create!(user: no_enrollments_user, purpose: "no enrollments user")

    subject

    expected_expiration_date = 120.days.from_now
    expect(former_teacher_access_token.reload.permanent_expires_at)
      .to be_within(10.minutes).of(expected_expiration_date)
    expect(no_enrollments_token.reload.permanent_expires_at).to be_nil
  end
end
