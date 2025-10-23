# frozen_string_literal: true

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

require_relative "../../../../lib/api/v1/group"

describe Api::V1::Group do
  include Api::V1::Group
  include Api::V1::User

  describe "group_json" do
    before :once do
      context = course_model
      @group = Group.create(name: "group1", context:)
      @group.add_user(@user)
      @user.enrollments.first.deactivate
    end

    it "basic test including users" do
      json = group_json(@group, @user, nil, include_inactive_users: true, include: ["users"])
      expect(json["id"]).to eq @group.id
      expect(json["name"]).to eq @group.name
      expect(json["users"].length).to eq 1
      user_json = json["users"].first
      expect(user_json["id"]).to eq(@user.id)
      expect(user_json["name"]).to eq(@user.name)
    end

    it "caps the number of users that will be returned" do
      other_user = user_model
      @group.add_user(other_user)
      json = group_json(@group, @user, nil, include_inactive_users: true, include: ["users"])
      expect(json["users"].length).to eq 2
      stub_const("Api::V1::Group::GROUP_MEMBER_LIMIT", 1)
      json = group_json(@group, @user, nil, include_inactive_users: true, include: ["users"])
      expect(json["users"].length).to eq 1
    end

    it "filter inactive users but do include users" do
      json = group_json(@group, @user, nil, include: ["users"])
      expect(json["id"]).to eq @group.id
      expect(json["name"]).to eq @group.name
      expect(json["users"]).not_to be_nil
      expect(json["users"].length).to eq 0
    end

    it "dont include users if not asked for" do
      json = group_json(@group, @user, nil)
      expect(json["id"]).to eq @group.id
      expect(json["name"]).to eq @group.name
      expect(json["users"]).to be_nil
    end

    context "section restrictions" do
      before :once do
        @course = course_model
        @section1 = @course.course_sections.create!(name: "Section 1")
        @section2 = @course.course_sections.create!(name: "Section 2")

        @student1 = user_model(name: "Student 1")
        @student2 = user_model(name: "Student 2")
        @student_default = user_model(name: "Student Default")

        @course.enroll_student(@student1, section: @section1, enrollment_state: "active")
        @course.enroll_student(@student2, section: @section2, enrollment_state: "active")
        @course.enroll_student(@student_default, enrollment_state: "active")

        @unrestricted_teacher = user_model(name: "Unrestricted Teacher")
        @course.enroll_teacher(@unrestricted_teacher, enrollment_state: "active")

        @restricted_teacher = user_model(name: "Restricted Teacher")
        @course.enroll_teacher(@restricted_teacher, section: @section1, enrollment_state: "active")
        Enrollment.limit_privileges_to_course_section!(@course, @restricted_teacher, true)

        @multi_section_teacher = user_model(name: "Multi Section Teacher")
        @course.enroll_teacher(@multi_section_teacher, section: @section1, enrollment_state: "active", allow_multiple_enrollments: true)
        @course.enroll_teacher(@multi_section_teacher, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
        Enrollment.limit_privileges_to_course_section!(@course, @multi_section_teacher, true)

        @group_category = @course.group_categories.create!(name: "Test Category")
        @mixed_group = @course.groups.create!(name: "Mixed Group", group_category: @group_category)
        @mixed_group.add_user(@student1)
        @mixed_group.add_user(@student2)
        @mixed_group.add_user(@student_default)
      end

      it "restricts members_count for section-restricted teachers" do
        json = group_json(@mixed_group, @restricted_teacher, nil)
        expect(json["members_count"]).to eq 1
      end

      it "shows full members_count for unrestricted teachers" do
        json = group_json(@mixed_group, @unrestricted_teacher, nil)
        expect(json["members_count"]).to eq 3
      end

      it "shows correct members_count for multi-section teachers" do
        json = group_json(@mixed_group, @multi_section_teacher, nil)
        expect(json["members_count"]).to eq 2
      end

      it "filters users list for section-restricted teachers" do
        json = group_json(@mixed_group, @restricted_teacher, nil, include: ["users"])
        user_ids = json["users"].pluck("id")
        expect(user_ids).to include(@student1.id)
        expect(user_ids).not_to include(@student2.id)
        expect(user_ids).not_to include(@student_default.id)
      end

      it "shows all users for unrestricted teachers" do
        json = group_json(@mixed_group, @unrestricted_teacher, nil, include: ["users"])
        user_ids = json["users"].pluck("id")
        expect(user_ids).to include(@student1.id)
        expect(user_ids).to include(@student2.id)
        expect(user_ids).to include(@student_default.id)
      end

      it "shows users from multiple sections for multi-section teachers" do
        json = group_json(@mixed_group, @multi_section_teacher, nil, include: ["users"])
        user_ids = json["users"].pluck("id")
        expect(user_ids).to include(@student1.id)
        expect(user_ids).to include(@student2.id)
        expect(user_ids).not_to include(@student_default.id)
      end

      it "does not apply restrictions for non-course contexts" do
        account = Account.default
        account_group = account.groups.create!(name: "Account Group")
        account_group.add_user(@student1)
        account_group.add_user(@student2)

        json = group_json(account_group, @restricted_teacher, nil, include: ["users"])
        expect(json["users"].length).to eq 2
      end

      it "handles empty groups gracefully" do
        empty_group = @course.groups.create!(name: "Empty Group", group_category: @group_category)
        json = group_json(empty_group, @restricted_teacher, nil)
        expect(json["members_count"]).to eq 0
      end
    end
  end

  describe "group_membership_json" do
    before :once do
      context = course_model
      @group = Group.create(name: "group1", context:)
      @group.add_user(@user)
      @user.enrollments.first.deactivate
    end

    it "basic test" do
      group_memberships = GroupMembership.where(group_id: @group.id, user_id: @user.id)
      expect(group_memberships.length).to eq 1
      group_membership = group_memberships.first
      json = group_membership_json(group_membership, @user, nil)
      expect(json["id"]).to eq group_membership.id
      expect(json["user_id"]).to eq @user.id
      expect(json["group_id"]).to eq @group.id
    end
  end
end
