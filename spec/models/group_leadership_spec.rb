require 'spec_helper'

describe GroupLeadership do

  describe "member_changed_event" do
    before(:each) do
      course
      @category = @course.group_categories.build(:name => "category 1")
      @category.save!
      @group = @category.groups.create!(:context => @course)
    end

    describe "with auto assignment enabled" do
      before(:each) do
        @category.auto_leader = "first"
        @category.save!
      end

      it "assigns the first student to join as the leader" do
        leader = user_model
        @group.group_memberships.create!(:user => leader, :workflow_state => 'accepted')
        @group.reload.leader.should == leader
      end

      it "picks a new leader if the leader leaves" do
        leader = user_model
        follower = user_model
        leader_membership = @group.group_memberships.create!(:user => leader, :workflow_state => 'accepted')
        follower_membership = @group.group_memberships.create!(:user => follower, :workflow_state => 'accepted')
        @group.reload.leader.should == leader
        leader_membership.destroy
        @group.reload.leader.should == follower
      end
    end

    describe "revocation without auto leader assignment" do
      before(:each) do
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
          @group.leader.should_not be_nil
          @leader_membership.destroy!
          @group.reload.leader.should be_nil
        end

        it "should revoke when soft deleted" do
          @group.leader.should_not be_nil
          @leader_membership.destroy
          @group.reload.leader.should be_nil
        end

        it "should revoke when group is changed" do
          @group.leader.should_not be_nil
          group2 = @category.groups.create!(:context => @course)
          @leader_membership.update_attribute(:group_id, group2.id)
          @group.reload.leader.should be_nil
        end
      end

      context "non-leader membership" do
        it "should not revoke when deleted" do
          @group.leader.should_not be_nil
          @membership.destroy!
          @group.reload.leader.should_not be_nil
       end

        it "should not revoke when group is changed" do
          @group.leader.should_not be_nil
          group2 = @category.groups.create!(:context => @course)
          @membership.update_attribute(:group_id, group2.id)
          @group.reload.leader.should_not be_nil
        end
      end

    end
  end
end
