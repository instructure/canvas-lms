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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe AccountUser do

  shared_examples_for "touching" do
    it "should recache permissions when created" do
      enable_cache do
        @user.shard.activate { User.update_all(:updated_at => 1.month.ago) }
        @user.reload
        @account.grants_right?(@user, :read).should be_false
        @account.account_users.create!(user: @user)
        @user.reload
        RoleOverride.clear_cached_contexts
        @account.instance_variable_set(:@account_users_cache, {})
        @account.grants_right?(@user, :read).should be_true
      end
    end

    it "should recache permissions when deleted" do
      enable_cache do
        au = @account.account_users.create!(user: @user)
        @user.shard.activate { User.update_all(:updated_at => 1.month.ago) }
        @user.reload
        @account.grants_right?(@user, :read).should be_true
        au.destroy
        @user.reload
        RoleOverride.clear_cached_contexts
        @account.instance_variable_set(:@account_users_cache, {})
        @account.grants_right?(@user, :read).should be_false
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
    it "should include granted permissions from multiple roles" do
      user = User.create!
      account_admin_user_with_role_changes(:user => user, :membership_type => 'role1', :role_changes => {:manage_sis => true})
      account_admin_user_with_role_changes(:user => user, :membership_type => 'role2', :role_changes => {:manage_wiki => true})

      permissions = AccountUser.all_permissions_for(user, Account.default)
      permissions.delete(:manage_sis).should_not be_empty
      permissions.delete(:manage_wiki).should_not be_empty
      permissions.values.all?(&:empty?).should be_true
    end
  end

  describe "is_subset_of?" do
    before :once do
      @user1 = User.create!
      @user2 = User.create!
      @ro1 = Account.default.role_overrides.create!(:enrollment_type => 'role1', :permission => 'manage_sis', :enabled => true)
      @ro2 = Account.default.role_overrides.create!(:enrollment_type => 'role2', :permission => 'manage_sis', :enabled => true)
      @au1 = Account.default.account_users.create!(user: @user1, membership_type: 'role1')
      @au2 = Account.default.account_users.create!(user: @user2, membership_type: 'role2')
    end

    it "should be symmetric for applies_to everything" do
      @au1.is_subset_of?(@user2).should be_true
      @au2.is_subset_of?(@user1).should be_true
    end

    it "should be symmetric for applies_to self" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      @ro2.applies_to_descendants = false
      @ro2.save!
      @au1.is_subset_of?(@user2).should be_true
      @au2.is_subset_of?(@user1).should be_true
    end

    it "should be symmetric for applies_to descendants" do
      @ro1.applies_to_self = false
      @ro1.save!
      @ro2.applies_to_self = false
      @ro2.save!
      @au1.is_subset_of?(@user2).should be_true
      @au2.is_subset_of?(@user1).should be_true
    end

    it "should properly compute differing applies_to (descendants vs. all)" do
      @ro1.applies_to_self = false
      @ro1.save!
      @au1.is_subset_of?(@user2).should be_true
      @au2.is_subset_of?(@user1).should be_false
    end

    it "should properly compute differing applies_to (self vs. all)" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      @au1.is_subset_of?(@user2).should be_true
      @au2.is_subset_of?(@user1).should be_false
    end

    it "should properly compute differing applies_to (self vs. descendants)" do
      @ro1.applies_to_descendants = false
      @ro1.save!
      @ro2.applies_to_self = false
      @ro2.save!
      @au1.is_subset_of?(@user2).should be_false
      @au2.is_subset_of?(@user1).should be_false
    end
  end

  describe "set_policy" do
    it "should not allow a lesser admin to create" do
      account_admin_user_with_role_changes(membership_type: 'lesser', role_changes: { manage_account_memberships: true })
      au = Account.default.account_users.build(user: @user, membership_type: 'AccountAdmin')
      au.grants_right?(@user, :create).should be_false
      u2 = User.create!
      au = Account.default.account_users.build(user: u2, membership_type: 'lesser')
      au.grants_right?(@user, :create).should be_true

    end
  end
end
