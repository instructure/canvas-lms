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

describe Types::GroupMembershipType do
  before(:once) do
    course_with_student(active_all: true)
    @group_set = @course.group_categories.create! name: "asdf"
    @group = @group_set.groups.create! name: "group 1", context: @course
    @membership = @group.add_user(@student)
  end

  let(:group_membership_type) { GraphQLTypeTester.new(Types::GroupMembershipType, @membership) }

  it "works" do
    expect(group_membership_type._id).to eq @membership.id
    expect(group_membership_type.user).to eq @membership.user
    expect(group_membership_type.state).to eq @membership.workflow_state
  end
end

