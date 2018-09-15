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

describe SIS::CSV::GroupImporter do

  before {account_model}

  it "should skip bad content" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    before_count = Group.count
    importer = process_csv_data(
      "group_id,account_id,name,status,group_category_id,course_id",
      "G001,A001,Group 1,available,",
      "G001,,Group 1,available,,invalid",
      "G001,invalid,Group 1,available,,invalid",
      "G002,A001,Group 1,blerged,",
      "G003,A001,,available,",
      "G004,A004,Group 4,available,",
      ",A001,G1,available,",
      "G006,A001,Group 6,available,invalid",
    )
    err = ["Course with sis id invalid didn't exist for group G001.",
           "Only one context is allowed and both course_id and account_id where provided for group G001.",
           "Improper status \"blerged\" for group G002.",
           "No name given for group G003.",
           "Account with sis id A004 didn't exist for group G004.",
           "No group_id given for a group.",
           "Group Category invalid didn't exist in account A001 for group G006."]
    expect(importer.errors.map(&:last)).to eq err
    expect(Group.count).to eq before_count + 1
  end

  it "should create groups" do
    account_model
    sub = @account.all_accounts.create!(name: 'sub')
    sub.update_attribute('sis_source_id', 'A002')
    process_csv_data_cleanly(
      "group_id,account_id,name,status",
      "G001,,Group 1,available",
      "G002,A002,Group 2,deleted")
    groups = Group.order(:id).to_a
    expect(groups.map(&:account_id)).to eq [@account.id, sub.id]
    expect(groups.map(&:sis_source_id)).to eq %w(G001 G002)
    expect(groups.map(&:name)).to eq ["Group 1", "Group 2"]
    expect(groups.map(&:workflow_state)).to eq %w(available deleted)
  end

  it "should create groups with no account id column" do
    account_model
    process_csv_data_cleanly(
      "group_id,name,status",
      "G001,Group 1,available")
    groups = Group.order(:id).to_a
    expect(groups.map(&:account_id)).to eq [@account.id]
    expect(groups.map(&:sis_source_id)).to eq %w(G001)
    expect(groups.map(&:name)).to eq ["Group 1"]
    expect(groups.map(&:workflow_state)).to eq %w(available)
  end

  it 'should create rollback data' do
    batch1 = @account.sis_batches.create! {|sb| sb.data = {}}
    process_csv_data_cleanly(
      "group_id,name,status",
      "G001,Group 1,available",
      batch: batch1
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "group_id,user_id,status",
      "G001,U001,accepted",
      batch: batch2
    )
    batch3 = @account.sis_batches.create! {|sb| sb.data = {}}
    process_csv_data_cleanly(
      "group_id,name,status",
      "G001,Group 1,deleted",
      batch: batch3
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: 'non-existent').count).to eq 1
    expect(batch3.roll_back_data.where(updated_workflow_state: 'deleted').count).to eq 2
    batch3.restore_states_for_batch
    expect(@account.all_groups.where(sis_source_id: 'G001').take.workflow_state).to eq 'available'
  end

  it "should update group attributes" do
    sub = @account.sub_accounts.create!(name: 'sub')
    sub.update_attribute('sis_source_id', 'A002')
    process_csv_data_cleanly(
      "group_id,account_id,name,status",
      "G001,,Group 1,available",
      "G002,,Group 2,available")
    expect(Group.count).to eq 2
    Group.where(sis_source_id: 'G001').first.update_attribute(:name, 'Group 1-1')
    process_csv_data_cleanly(
      "group_id,account_id,name,status",
      "G001,,Group 1-b,available",
      "G002,A002,Group 2-b,deleted")
    # group 1's name won't change because it was manually changed
    groups = Group.order(:id).to_a
    expect(groups.map(&:name)).to eq ["Group 1-1", "Group 2-b"]
    expect(groups.map(&:root_account)).to eq [@account, @account]
    expect(groups.map(&:workflow_state)).to eq %w(available deleted)
    expect(groups.map(&:account)).to eq [@account, sub]
  end

  it "should use group_category_id and set sis_id" do
    sub = @account.sub_accounts.create!(name: 'sub')
    sub.update_attribute('sis_source_id', 'A002')
    process_csv_data_cleanly(
      "group_category_id,account_id,category_name,status",
      "Gc001,,Group Cat 1,active",
      "Gc002,A002,Group Cat 2,active")
    process_csv_data_cleanly(
      "group_id,account_id,name,status,group_category_id",
      "G001,,Group 1,available,Gc001",
      "G002,,Group 2,available,Gc002")
    group1 = Group.where(sis_source_id: 'G001').take
    group2 = Group.where(sis_source_id: 'G002').take
    groups = [group1, group2]
    expect(groups.map(&:account)).to eq [@account, sub]
    expect(groups.map(&:group_category)).to eq GroupCategory.order(:id).to_a
  end

  it "should use course_id" do
    course = course_factory(account: @account, sis_source_id: 'c001')
    process_csv_data_cleanly(
      "group_id,course_id,name,status",
      "G001,c001,Group 1,available")
    expect(Group.where(sis_source_id: 'G001').take.context).to eq course
  end

  it "should not allow changing course_id with group_memberships" do
    course1 = course_factory(account: @account, sis_source_id: 'c001')
    course_factory(account: @account, sis_source_id: 'c002')
    group = group_model(context: course1, sis_source_id: "G001")
    group.group_memberships.create!(user: user_model)

    importer = process_csv_data(
      "group_id,course_id,name,status",
      "G001,c002,Group 1,available")
    expect(importer.errors.last.last).to eq "Cannot move group G001 because it has group_memberships."
  end
end
