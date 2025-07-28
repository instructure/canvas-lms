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

require_relative "../graphql_spec_helper"

describe Types::GroupMembershipType do
  before(:once) do
    course_with_student(active_all: true)
    group_category = @course.group_categories.create! name: "test group set"
    @group = @course.groups.create(group_category:, join_level: "parent_context_auto_join")
    @membership = @group.add_user(@student, "accepted")
  end

  let(:group_type) { GraphQLTypeTester.new(@group, current_user: @teacher) }

  it "works" do
    expect(group_type.resolve("membersConnection { nodes { _id } }")).to eq [@membership.id.to_s]
    expect(group_type.resolve("membersConnection { nodes { state } }")).to eq [@membership.workflow_state]
  end

  it "resolves user field" do
    expect(group_type.resolve("membersConnection { nodes { user { _id } } }")).to eq [@membership.user_id.to_s]
    expect(group_type.resolve("membersConnection { nodes { user { name } } }")).to eq [@membership.user.name]
  end

  it "resolves group field" do
    expect(group_type.resolve("membersConnection { nodes { group { _id } } }")).to eq [@group.id.to_s]
    expect(group_type.resolve("membersConnection { nodes { group { name } } }")).to eq [@group.name]
  end

  it "resolves the created_at timestamp" do
    created_at = Time.zone.parse(group_type.resolve("membersConnection { nodes { createdAt } }")[0])
    expect(created_at.to_i).to eq @membership.created_at.to_i
  end

  it "resolves the updated_at timestamp" do
    updated_at = Time.zone.parse(group_type.resolve("membersConnection { nodes { updatedAt } }")[0])
    expect(updated_at.to_i).to eq @membership.updated_at.to_i
  end
end
