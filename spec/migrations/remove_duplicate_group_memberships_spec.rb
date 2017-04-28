#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../spec_helper"
require 'db/migrate/20160309135747_add_unique_index_to_group_memberships.rb'

describe DataFixup::RemoveDuplicateGroupMemberships do
  it "should keep accepted memberships first" do
    mig = AddUniqueIndexToGroupMemberships.new
    mig.down

    group_model
    user_factory
    member1 = @group.group_memberships.create!(:user => @user)
    member1.workflow_state = 'rejected'
    member1.save!

    member2 = @group.group_memberships.create!(:user => @user)
    member2.workflow_state = 'accepted'
    member2.save!

    mig.up

    expect(GroupMembership.where(:id => member1).first).to be_nil
    expect(GroupMembership.where(:id => member2).first).to eq member2
  end
end
