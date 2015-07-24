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
    expect(importer.warnings.map(&:last)).to eq(
      ["No group_id given for a group user",
       "No user_id given for a group user",
       "Improper status \"bogus\" for a group user"]
    )
    expect(importer.errors).to eq []
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

end
