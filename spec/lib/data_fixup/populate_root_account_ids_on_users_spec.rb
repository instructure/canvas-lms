# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe DataFixup::PopulateRootAccountIdsOnUsers do
  it "populates from user account associations" do
    user = User.create!
    a1 = Account.create!
    a2 = Account.create!
    p1 = a1.pseudonyms.create!(user:, unique_id: "user")
    p2 = a2.pseudonyms.create!(user:, unique_id: "user")
    expect(p1.root_account_id).to eq a1.id
    expect(p2.root_account_id).to eq a2.id
    expect(user.reload.root_account_ids).to eq([])
    DataFixup::PopulateRootAccountIdsOnUsers.populate(user.id, user.id)
    expect(user.reload.root_account_ids).to eq([a1.id, a2.id])
  end

  it "appends to an existing array" do
    user = User.create!
    a1 = Account.create!
    a2 = Account.create!
    p1 = a1.pseudonyms.create!(user:, unique_id: "user")
    expect(p1.root_account_id).to eq a1.id
    expect(user.reload.root_account_ids).to eq([])

    DataFixup::PopulateRootAccountIdsOnUsers.populate(user.id, user.id)
    expect(user.reload.root_account_ids).to eq([a1.id])

    p2 = a2.pseudonyms.create!(user:, unique_id: "user")
    expect(p2.root_account_id).to eq a2.id
    DataFixup::PopulateRootAccountIdsOnUsers.populate(user.id, user.id)
    expect(user.reload.root_account_ids).to eq([a1.id, a2.id])
  end

  context "sharding" do
    specs_require_sharding

    it "populates root account ids from a different shard" do
      user1 = User.create!
      a1 = nil
      user2 = @shard2.activate { User.create! }
      @shard1.activate do
        a1 = Account.create!
        # users from 2 different foreign shards are associated with this shard
        # this ensures we exercise the part where each foreign shard is addressed
        # separately
        p1 = a1.pseudonyms.create!(user: user1, unique_id: "user1")
        p2 = a1.pseudonyms.create!(user: user2, unique_id: "user2")
        expect(p1.root_account_id).to eq a1.id
        expect(p2.root_account_id).to eq a1.id
        expect(user1.reload.root_account_ids).to eq([])
        expect(user2.reload.root_account_ids).to eq([])

        DataFixup::PopulateRootAccountIdsOnUsers.populate_table
      end
      expect(user1.reload.root_account_ids).to eq([a1.global_id])
      expect(user2.reload.root_account_ids).to eq([a1.global_id])
    end
  end
end
