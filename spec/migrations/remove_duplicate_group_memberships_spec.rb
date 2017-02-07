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
