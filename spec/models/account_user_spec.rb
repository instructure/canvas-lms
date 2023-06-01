# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe AccountUser do
  before :once do
    @role1 = custom_account_role("role1", account: Account.default)
    @role2 = custom_account_role("role2", account: Account.default)
  end

  shared_examples_for "touching" do
    it "recaches permissions when created" do
      enable_cache do
        @user.shard.activate { User.update_all(updated_at: 1.month.ago) }
        @user.reload
        expect(@account.grants_right?(@user, :read)).to be_falsey
        @account.account_users.create!(user: @user)
        @user.reload
        @account.instance_variable_set(:@account_users_cache, {})
        expect(@account.grants_right?(@user, :read)).to be_truthy
      end
    end

    it "recaches permissions when deleted" do
      enable_cache do
        au = @account.account_users.create!(user: @user)
        @user.shard.activate { User.update_all(updated_at: 1.month.ago) }
        @user.reload
        expect(@account.grants_right?(@user, :read)).to be_truthy
        au.destroy
        @user.reload
        @account.instance_variable_set(:@account_users_cache, {})
        expect(@account.grants_right?(@user, :read)).to be_falsey
        expect(au.reload.workflow_state).to eq "deleted"
      end
    end
  end

  context "non-sharded" do
    include_examples "touching"

    before :once do
      @account = Account.default
      @user = User.create!
    end
  end

  context "sharding" do
    specs_require_sharding
    include_examples "touching"

    before :once do
      @account = @shard1.activate { Account.create! }
      @user = @shard2.activate { User.create! }
    end
  end

  describe "all_permissions_for" do
    it "includes granted permissions from multiple roles" do
      user = User.create!
      manage_wiki_permissions = { manage_wiki_create: true, manage_wiki_update: true, manage_wiki_delete: true }
      account_admin_user_with_role_changes(user:, role: @role1, role_changes: { manage_sis: true })
      account_admin_user_with_role_changes(user:, role: @role2, role_changes: manage_wiki_permissions)

      permissions = AccountUser.all_permissions_for(user, Account.default)
      expect(permissions.delete(:manage_sis)).not_to be_empty
      expect(permissions.delete(:manage_wiki_create)).not_to be_empty
      expect(permissions.delete(:manage_wiki_update)).not_to be_empty
      expect(permissions.delete(:manage_wiki_delete)).not_to be_empty
      expect(permissions.values.all?(&:empty?)).to be_truthy
    end
  end

  describe "is_subset_of?" do
    before :once do
      @user1 = User.create!
      @user2 = User.create!
      @ro1 = Account.default.role_overrides.create!(role: @role1, permission: "manage_sis", enabled: true)
      @ro2 = Account.default.role_overrides.create!(role: @role2, permission: "manage_sis", enabled: true)
      @au1 = Account.default.account_users.create!(user: @user1, role: @role1)
      @au2 = Account.default.account_users.create!(user: @user2, role: @role2)
    end

    it "is symmetric for applies_to everything" do
      expect(@au1.is_subset_of?(@user2)).to be_truthy
      expect(@au2.is_subset_of?(@user1)).to be_truthy
    end

    it "is symmetric for applies_to self" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      @ro2.applies_to_descendants = false
      @ro2.save!
      expect(@au1.is_subset_of?(@user2)).to be_truthy
      expect(@au2.is_subset_of?(@user1)).to be_truthy
    end

    it "is symmetric for applies_to descendants" do
      @ro1.applies_to_self = false
      @ro1.save!
      @ro2.applies_to_self = false
      @ro2.save!
      expect(@au1.is_subset_of?(@user2)).to be_truthy
      expect(@au2.is_subset_of?(@user1)).to be_truthy
    end

    it "properly computes differing applies_to (descendants vs. all)" do
      @ro1.applies_to_self = false
      @ro1.save!
      expect(@au1.is_subset_of?(@user2)).to be_truthy
      expect(@au2.is_subset_of?(@user1)).to be_falsey
    end

    it "properly computes differing applies_to (self vs. all)" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      expect(@au1.is_subset_of?(@user2)).to be_truthy
      expect(@au2.is_subset_of?(@user1)).to be_falsey
    end

    it "properly computes differing applies_to (self vs. descendants)" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      @ro2.applies_to_self = false
      @ro2.save!
      expect(@au1.is_subset_of?(@user2)).to be_falsey
      expect(@au2.is_subset_of?(@user1)).to be_falsey
    end
  end

  describe "set_policy" do
    it "does not allow a lesser admin to create" do
      lesser_role = custom_account_role("lesser", account: Account.default)

      account_admin_user_with_role_changes(role: lesser_role, role_changes: { manage_account_memberships: true })
      au = Account.default.account_users.build(user: @user, role: admin_role)
      expect(au.grants_right?(@user, :create)).to be_falsey
      u2 = User.create!
      au = Account.default.account_users.build(user: u2, role: lesser_role)
      expect(au.grants_right?(@user, :create)).to be_truthy
      au = Account.default.account_users.build(user: u2, role: admin_role)
      expect(au.grants_right?(@user, :create)).to be_falsey
    end
  end

  describe "valid_role?" do
    before :once do
      @account = Account.default
      @user = User.create!
      @sub1 = @account.sub_accounts.create! name: "sub1"
      @sub1role = custom_account_role("sub1", account: @sub1)
      @sub1a = @sub1.sub_accounts.create! name: "sub1a"
      @sub2 = @account.sub_accounts.create! name: "sub2"
    end

    it "accepts a custom role in the account chain" do
      au = AccountUser.create(user: @user, account: @sub1a, role: @sub1role)
      expect(au).to be_valid
    end

    it "rejects a custom role outside the account chain" do
      au = AccountUser.create(user: @user, account: @sub2, role: @sub1role)
      expect(au).not_to be_valid
    end

    it "allows an invalid AccountUser to be deleted" do
      au = AccountUser.create(user: @user, account: @sub2, role: @sub1role, workflow_state: "deleted")
      expect(au).to be_valid
    end

    describe "root_account_id" do
      it "uses root_account value from account" do
        au = AccountUser.create(user: @user, account: @sub1a, role: @sub1role)
        expect(au.root_account_id).to eq(@account.id)
      end

      it "keeps set value if it already exists" do
        au = AccountUser.create(user: @user, account: @sub1a, role: @sub1role, root_account_id: @sub1.id)
        expect(au.root_account_id).to eq(@sub1.id)
      end
    end
  end
end
