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
