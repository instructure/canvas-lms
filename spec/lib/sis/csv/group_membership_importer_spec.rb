#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::GroupMembershipImporter do

  before { account_model }

  before do
    group_model(:context => @account, :sis_source_id => "G001")
    @user1 = user_with_pseudonym(:username => 'u1@example.com')
    @user1.pseudonym.update_attribute(:sis_user_id, 'U001')
    @user1.pseudonym.update_attribute(:account, @account)
    @user2 = user_with_pseudonym(:username => 'u2@example.com')
    @user2.pseudonym.update_attribute(:sis_user_id, 'U002')
    @user2.pseudonym.update_attribute(:account, @account)
    @user3 = user_with_pseudonym(:username => 'u3@example.com')
    @user3.pseudonym.update_attribute(:sis_user_id, 'U003')
    @user3.pseudonym.update_attribute(:account, @account)
  end

  it "should skip bad content" do
    importer = process_csv_data(
      "group_id,user_id,status",
      ",U001,accepted",
      "G001,,accepted",
      "G001,U001,bogus")
    expect(GroupMembership.count).to eq 0
    expect(importer.errors.map(&:last)).to eq(
      ["No group_id given for a group user",
       "No user_id given for a group user",
       "Improper status \"bogus\" for a group user"]
    )
  end

  it "should add users to groups" do
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,accepted",
      "G001,U003,deleted")
    ms = GroupMembership.order(:id).to_a
    expect(ms.map(&:user_id)).to eq [@user1.id, @user3.id]
    expect(ms.map(&:group_id)).to eq [@group.id, @group.id]
    expect(ms.map(&:workflow_state)).to eq %w(accepted deleted)

    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,deleted",
      "G001,U003,deleted")
    ms = GroupMembership.order(:id).to_a
    expect(ms.map(&:user_id)).to eq [@user1.id, @user3.id]
    expect(ms.map(&:group_id)).to eq [@group.id, @group.id]
    expect(ms.map(&:workflow_state)).to eq %w(deleted deleted)
  end

  it "should add users to groups that the user cannot access" do
    course = course_factory(account: @account, sis_source_id: 'c001')
    group_model(context: course, sis_source_id: "G002")
    importer = process_csv_data(
      "group_id,user_id,status",
      "G002,U001,accepted")
    expect(importer.errors.last.last).to eq "User U001 doesn't have an enrollment in the course of group G002."
  end

  it "should find active gm first" do
    g = group_model(context: @account, sis_source_id: "G002")
    g.group_memberships.create!(user: @user1, workflow_state: 'accepted')
    g.group_memberships.create!(user: @user1, workflow_state: 'deleted')
    importer = process_csv_data_cleanly(
      "group_id,user_id,status",
      "G002,U001,accepted")
    expect(importer.errors).to eq []
  end

  it 'should create rollback data' do
    @account.enable_feature!(:refactor_of_sis_imports)
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,accepted",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,deleted",
      batch: batch2
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: 'non-existent').count).to eq 1
    expect(batch2.roll_back_data.first.updated_workflow_state).to eq 'deleted'
    batch2.restore_states_for_batch
    expect(@account.all_groups.where(sis_source_id: 'G001').take.group_memberships.take.workflow_state).to eq 'accepted'
  end

  it 'should handle unique constraint errors rolling back data' do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,accepted",
      "G001,U002,accepted",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,deleted",
      "G001,U002,deleted",
      batch: batch2
    )
    group = @account.all_groups.where(sis_source_id: 'G001').take
    deleted_gm = GroupMembership.where(group_id: group, user_id: @user1).take
    new_gm = group.group_memberships.create!(:workflow_state => 'accepted', :user => @user1)
    batch2.restore_states_for_batch
    expect(batch2.sis_batch_errors.last.message).to include("Couldn't rollback SIS batch data for row")
    expect(batch2.roll_back_data.where(context_type: "GroupMembership", context_id: deleted_gm.id).take.workflow_state).to eq 'failed'
    expect(group.group_memberships.where(user_id: @user2).take.workflow_state).to eq 'accepted' # should restore the one still
  end
end
