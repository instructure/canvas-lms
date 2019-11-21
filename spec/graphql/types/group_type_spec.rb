#
# Copyright (C) 2017 Instructure, Inc.
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

describe Types::GroupType do
  before(:once) do
    course_with_student(active_all: true)
    @student_not_in_group = @student

    student_in_course(active_all: true)
    @student_in_group = @student

    @group_set = @course.group_categories.create! name: "asdf"
    @group = @group_set.groups.create! name: "group 1", context: @course
    @membership = @group.add_user(@student_in_group)
  end

  let(:group_type) { GraphQLTypeTester.new(@group, current_user: @teacher) }

  it "works" do
    expect(group_type.resolve("_id")).to eq @group.id.to_s
    expect(group_type.resolve("name")).to eq @group.name
    expect(group_type.resolve("membersConnection { edges { node { _id } } }")).
      to eq @group.group_memberships.map(&:to_param)
  end

  it "requires read permission" do
    user = user_factory(active_all: true)
    expect(group_type.resolve("_id", current_user: user)).to be_nil
  end

  describe "membersConnection" do
    it "works" do
      expect(group_type.resolve("membersConnection { nodes { user { _id } } }")).to eq [@membership.user_id.to_s]
      expect(group_type.resolve("membersConnection { nodes { state } }")).to eq [@membership.workflow_state]
    end

    it "requires permission" do
      expect(
        group_type.resolve("membersConnection { nodes { _id } }",
                           current_user: @student_not_in_group)
      ).to be_nil
    end
  end

  describe "member" do
    it "works" do
      expect(
        group_type.resolve(%|member(userId: "#{@student_in_group.id}") { _id }|)
      ).to eq @membership.id.to_s
    end

    it "requires permission" do
      expect(
        group_type.resolve(%|member(userId: "#{@student_in_group.id}") { _id }|,
                           current_user: @student_not_in_group)
      ).to be_nil
    end
  end
end
