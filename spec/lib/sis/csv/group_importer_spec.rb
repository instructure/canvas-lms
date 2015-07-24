#
# Copyright (C) 2011 Instructure, Inc.
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

  before { account_model }

  it "should skip bad content" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    before_count = Group.count
    importer = process_csv_data(
      "group_id,account_id,name,status",
      "G001,A001,Group 1,available",
      "G002,A001,Group 1,blerged",
      "G003,A001,,available",
      "G004,A004,Group 4,available",
      ",A001,G1,available")
    expect(importer.errors).to eq []
    expect(importer.warnings.map(&:last)).to eq(
      ["Improper status \"blerged\" for group G002, skipping",
       "No name given for group G003, skipping",
       "Parent account didn't exist for A004",
       "No group_id given for a group"]
    )
    expect(Group.count).to eq before_count + 1
  end

  it "should create groups" do
    account_model
    @sub = @account.all_accounts.create!(:name => 'sub')
    @sub.update_attribute('sis_source_id', 'A002')
    process_csv_data_cleanly(
      "group_id,account_id,name,status",
      "G001,,Group 1,available",
      "G002,A002,Group 2,deleted")
    groups = Group.order(:id).to_a
    expect(groups.map(&:account_id)).to eq [@account.id, @sub.id]
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

  it "should update group attributes" do
    @sub = @account.sub_accounts.create!(:name => 'sub')
    @sub.update_attribute('sis_source_id', 'A002')
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
    expect(groups.map(&:account)).to eq [@account, @sub]
  end

end
