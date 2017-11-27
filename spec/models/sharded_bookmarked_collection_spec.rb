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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe ShardedBookmarkedCollection do
  before(:each) do
    @user = user_factory(active_user: true)
    @user.account_users.create! account: Account.create!
    @user.account_users.create! account: Account.create! { |a| a.workflow_state = 'deleted' }
  end

  it "returns a paginatable collection" do
    collection = ShardedBookmarkedCollection.build(Account::Bookmarker, @user.adminable_accounts_scope) do |scope|
      scope.active
    end
    expect(collection.paginate(per_page: 10).size).to equal 1
    # only one sub-scope, so pass-through
    expect(collection).to be_is_a ActiveRecord::Relation
  end

  context "sharding" do
    specs_require_sharding

    it "returns a paginatable collection" do
      @shard1.activate do
        a = Account.create!
        a.account_users.create!(user: @user)
      end
      collection = ShardedBookmarkedCollection.build(Account::Bookmarker, @user.adminable_accounts_scope) do |scope|
        scope.active
      end
      expect(collection.paginate(per_page: 10).size).to equal 2
      # only one sub-scope, so pass-through
      expect(collection).to be_is_a BookmarkedCollection::MergeProxy
    end
  end
end
