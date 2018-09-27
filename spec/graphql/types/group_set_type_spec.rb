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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::GroupSetType do
  before(:once) do
    course_with_student(active_all: true)
    @group_set = @course.group_categories.create! name: "asdf",
      self_signup: "restricted",
      auto_leader: "random"
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
    @group_set.update_attributes! self_signup: nil
    expect(group_set_type.resolve("selfSignup")).to eq "disabled"
  end
end
