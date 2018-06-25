#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::UserType do
  let_once(:user) { student_in_course(active_all: true); @student }
  let(:user_type) { GraphQLTypeTester.new(Types::UserType, user) }

  it "works" do
    expect(user_type._id).to eq user.id
    expect(user_type.name).to eq "User"
  end

  context "avatarUrl" do
    it "is nil when avatars are not enabled" do
      expect(user_type.avatarUrl).to be_nil
    end

    it "returns an avatar url when avatars are enabled" do
      user.account.enable_service(:avatars)
      expect(user_type.avatarUrl).to match /avatar.*png/
    end
  end

  context "enrollments" do
    before(:once) do
      @course1 = @course
      @course2 = course_factory
      student_in_course(user: @student, course: @course2, active_all: true)
    end

    it "returns enrollments for a given course" do
      expect(
        user_type.enrollments(
          args: {course_id: @course1.id.to_s},
          current_user: @teacher
        )
      ).to eq [@student.enrollments.first]
    end

    it "returns all enrollments for a user (that can be read)" do
      @course1.enroll_student(@student, enrollment_state: "active")

      expect(
        user_type.enrollments(current_user: @teacher, args: {course_id: nil})
      ).to eq [@student.enrollments.first]

      site_admin_user
      expect(
        user_type.enrollments(current_user: @admin, args: {course_id: nil})
      ).to eq @student.enrollments
    end

    it "doesn't return enrollments for courses the user doesn't have permission for" do
      expect(
        user_type.enrollments(
          args: {course_id: @course2.id.to_s},
          current_user: @teacher
        )
      ).to eq []
    end
  end

  context "email" do
    before(:once) do
      user.email = "cooldude@example.com"
      user.save!
    end

    it "returns email for teachers/admins" do
      expect(user_type.email(current_user: @teacher)).to eq user.email

      # this is for the cached branch
      allow(user).to receive(:email_cached?) { true }
      expect(user_type.email(current_user: @teacher)).to eq user.email
    end

    it "doesn't return email for others" do
      _student = user
      other_student = student_in_course(active_all: true).user
      teacher_in_other_course = teacher_in_course(course: course_factory).user

      expect(user_type.email(current_user: nil)).to be_nil
      expect(user_type.email(current_user: other_student)).to be_nil
      expect(user_type.email(current_user: teacher_in_other_course)).to be_nil
    end
  end
end
