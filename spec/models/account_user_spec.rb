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
        @account.add_user(@user)
        @account.shard.activate { run_transaction_commit_callbacks }
        @user.reload
        RoleOverride.clear_cached_contexts
        @account.instance_variable_set(:@account_users_cache, {})
        @account.grants_right?(@user, :read).should be_true
      end
    end

    it "should recache permissions when deleted" do
      enable_cache do
        au = @account.add_user(@user)
        @user.shard.activate { User.update_all(:updated_at => 1.month.ago) }
        @user.reload
        @account.grants_right?(@user, :read).should be_true
        au.destroy
        @account.shard.activate { run_transaction_commit_callbacks }
        @user.reload
        RoleOverride.clear_cached_contexts
        @account.instance_variable_set(:@account_users_cache, {})
        @account.grants_right?(@user, :read).should be_false
      end
    end
  end

  context "non-sharded" do
    it_should_behave_like "touching"

    before do
      @account = Account.default
      @user = User.create!
    end
  end

  context "sharding" do
    it_should_behave_like "sharding"
    it_should_behave_like "touching"

    before do
      @account = @shard1.activate { Account.create! }
      @user = @shard2.activate { User.create! }
    end
  end
end
