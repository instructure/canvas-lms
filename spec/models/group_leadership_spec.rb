# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe GroupLeadership do

  describe "member_changed_event" do
    before(:once) do
      course_factory
      @category = @course.group_categories.build(:name => "category 1")
      @category.save!
      @group = @category.groups.create!(:context => @course)
    end

    describe "with auto assignment enabled" do
      before(:once) do
        @category.auto_leader = "first"
        @category.save!
      end

      it "assigns the first student to join as the leader" do
        leader = user_model
        @group.group_memberships.create!(:user => leader, :workflow_state => 'accepted')
        expect(@group.reload.leader).to eq leader
      end

      it "picks a new leader if the leader leaves" do
        leader = user_model
        follower = user_model
        leader_membership = @group.group_memberships.create!(:user => leader, :workflow_state => 'accepted')
        follower_membership = @group.group_memberships.create!(:user => follower, :workflow_state => 'accepted')
        expect(@group.reload.leader).to eq leader
        leader_membership.destroy
        expect(@group.reload.leader).to eq follower
      end
    end

    describe "revocation without auto leader assignment" do
      before(:once) do
        @leader = user_model
        @leader_membership = @group.group_memberships.create!(:user => @leader, :workflow_state => 'accepted')
        @group.leader = @leader
        @group.save!
        @membership = @group.group_memberships.create!(:user => user_model, :workflow_state => 'accepted')
        @group.reload
        @leader_membership.reload
      end

      context "leader membership" do
        it "should revoke when deleted" do
          expect(@group.leader).not_to be_nil
          @leader_membership.destroy_permanently!
          expect(@group.reload.leader).to be_nil
        end

        it "should revoke when soft deleted" do
          expect(@group.leader).not_to be_nil
          @leader_membership.destroy
          expect(@group.reload.leader).to be_nil
        end

        it "should revoke when group is changed" do
          expect(@group.leader).not_to be_nil
          group2 = @category.groups.create!(:context => @course)
          @leader_membership.update_attribute(:group_id, group2.id)
          expect(@group.reload.leader).to be_nil
        end
      end

      context "non-leader membership" do
        it "should not revoke when deleted" do
          expect(@group.leader).not_to be_nil
          @membership.destroy_permanently!
          expect(@group.reload.leader).not_to be_nil
       end

        it "should not revoke when group is changed" do
          expect(@group.leader).not_to be_nil
          group2 = @category.groups.create!(:context => @course)
          @membership.update_attribute(:group_id, group2.id)
          expect(@group.reload.leader).not_to be_nil
        end
      end

    end
  end
end
