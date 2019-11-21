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
require_relative "../graphql_spec_helper"

describe Types::UserType do
  before(:once) do
    student = student_in_course(active_all: true).user
    course = @course
    teacher = @teacher
    @other_student = student_in_course(active_all: true).user

    @other_course = course_factory
    @random_person = teacher_in_course(active_all: true).user

    @course = course
    @student = student
    @teacher = teacher
  end

  let(:user_type) { GraphQLTypeTester.new(@student, current_user: @teacher, domain_root_account: @course.account.root_account, request: ActionDispatch::TestRequest.create ) }
  let(:user) { @student }

  context "node" do
    it "works" do
      expect(user_type.resolve("_id")).to eq @student.id.to_s
      expect(user_type.resolve("name")).to eq @student.name
    end

    it "works for users in the same course" do
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end

    it "doesn't work for just anyone" do
      expect(user_type.resolve("_id", current_user: @random_person)).to be_nil
    end

    it "loads inactive and concluded users" do
      @student.enrollments.update_all workflow_state: "inactive"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s

      @student.enrollments.update_all workflow_state: "completed"
      expect(user_type.resolve("_id", current_user: @other_student)).to eq @student.id.to_s
    end
  end

  context "avatarUrl" do
    before(:once) do
      @student.update_attributes! avatar_image_url: 'not-a-fallback-avatar.png'
    end

    it "is nil when avatars are not enabled" do
      expect(user_type.resolve("avatarUrl")).to be_nil
    end

    it "returns an avatar url when avatars are enabled" do
      user.account.enable_service(:avatars)
      expect(user_type.resolve("avatarUrl")).to match(/avatar.*png/)
    end

    it "returns nil when a user has no avatar" do
      user.account.enable_service(:avatars)
      user.update_attributes! avatar_image_url: nil
      expect(user_type.resolve("avatarUrl")).to be_nil
    end
  end

  context "pronouns" do
    it "returns user pronouns" do
      @student.account.root_account.settings[:can_add_pronouns] = true
      @student.account.root_account.save!
      @student.pronouns = "Dude/Guy"
      @student.save!
      expect(user_type.resolve("pronouns")).to eq "Dude/Guy"
    end
  end


  context "enrollments" do
    before(:once) do
      @course1 = @course
      @course2 = course_factory
      @course2.enroll_student(@student, enrollment_state: "active")
    end

    it "returns enrollments for a given course" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course1.id}") { _id }|)
      ).to eq [@student.enrollments.first.to_param]
    end

    it "returns all enrollments for a user (that can be read)" do
      @course1.enroll_student(@student, enrollment_state: "active")

      expect(
        user_type.resolve("enrollments { _id }")
      ).to eq [@student.enrollments.first.to_param]

      site_admin_user
      expect(
        user_type.resolve(
          "enrollments { _id }",
          current_user: @admin
        )
      ).to match_array @student.enrollments.map(&:to_param)
    end

    it "doesn't return enrollments for courses the user doesn't have permission for" do
      expect(
        user_type.resolve(%|enrollments(courseId: "#{@course2.id}") { _id }|)
      ).to eq []
    end
  end

  context "email" do
    before(:once) do
      @student.update_attributes! email: "cooldude@example.com"
    end

    it "returns email for teachers/admins" do
      expect(user_type.resolve("email")).to eq user.email

      # this is for the cached branch
      allow(user).to receive(:email_cached?) { true }
      expect(user_type.resolve("email")).to eq user.email
    end

    it "doesn't return email for others" do
      expect(user_type.resolve("email", current_user: nil)).to be_nil
      expect(user_type.resolve("email", current_user: @other_student)).to be_nil
      expect(user_type.resolve("email", current_user: @random_person)).to be_nil
    end
  end

  context "groups" do
    before(:once) do
      @user_group_ids = (1..5).map {
        group_with_user({user: @student, active_all: true}).group_id.to_s
      }
      @deleted_user_group_ids = (1..3).map {
        group = group_with_user({user: @student, active_all: true})
        group.destroy
        group.group_id.to_s
      }
    end

    it "fetches the groups associated with a user" do
      user_type.resolve('groups { _id }', current_user: @student).all? do |id|
        expect(@user_group_ids.include?(id)).to be true
        expect(@deleted_user_group_ids.include?(id)).to be false
      end
    end
  end
end
