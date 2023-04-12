# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Types::GroupSetType do
  before(:once) do
    course_with_student(active_all: true)
    @group_set = @course.group_categories.create! name: "asdf",
                                                  self_signup: "restricted",
                                                  auto_leader: "random",
                                                  sis_source_id: "sisSet"
    @group = @group_set.groups.create! name: "group 1", context: @course
    @membership = @group.add_user(@student)
  end

  let(:group_set_type) { GraphQLTypeTester.new(@group_set, current_user: @teacher) }

  context "node permission" do
    it "works for teachers" do
      expect(group_set_type.resolve("_id", current_user: @teacher)).to eq @group_set.id.to_s
    end

    it "works for students" do
      expect(group_set_type.resolve("_id", current_user: @student)).to eq @group_set.id.to_s
    end

    it "doesn't work for randos" do
      user = user_factory(active_all: true)
      expect(group_set_type.resolve("_id", current_user: user)).to be_nil
    end
  end

  it "works" do
    expect(group_set_type.resolve("_id")).to eq @group_set.id.to_s
    expect(group_set_type.resolve("name")).to eq @group_set.name
    expect(group_set_type.resolve("selfSignup")).to eq "restricted"
    expect(group_set_type.resolve("autoLeader")).to eq "random"
    expect(group_set_type.resolve("groupsConnection { edges { node { _id } } }")).to eq [@group.id.to_s]
  end

  it "returns 'disabled' for null self_signup" do
    @group_set.update! self_signup: nil
    expect(group_set_type.resolve("selfSignup")).to eq "disabled"
  end

  context "sis field" do
    let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false }) }
    let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false }) }

    it "returns sis_id if you have read_sis permissions" do
      tester = GraphQLTypeTester.new(@group_set, current_user: read_admin)
      expect(tester.resolve("sisId")).to eq "sisSet"
    end

    it "returns sis_id if you have manage_sis permissions" do
      tester = GraphQLTypeTester.new(@group_set, current_user: manage_admin)
      expect(tester.resolve("sisId")).to eq "sisSet"
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      tester = GraphQLTypeTester.new(@group_set, current_user: @student)
      expect(tester.resolve("sisId")).to be_nil
    end
  end

  context "current group" do
    let(:student) { GraphQLTypeTester.new(@group_set, current_user: @student) }
    let(:teacher) { GraphQLTypeTester.new(@group_set, current_user: @teacher) }

    it "returns the group where the current student belongs to" do
      expect(student.resolve("currentGroup { _id }")).to eq @group.id.to_s
    end

    it "returns null if the student doesn't belong to any group" do
      @membership.destroy
      expect(student.resolve("currentGroup { _id }")).to be_nil
    end

    it "returns null if the current user has a teacher enrollment" do
      expect(teacher.resolve("currentGroup { _id }")).to be_nil
    end
  end
end
