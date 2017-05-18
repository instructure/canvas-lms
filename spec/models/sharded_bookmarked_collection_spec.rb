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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ShardedBookmarkedCollection do
  before(:each) do
    @user = user_factory(active_user: true)
    @user.account_users.create! account: Account.create!
    @user.account_users.create! account: Account.create! { |a| a.workflow_state = 'deleted' }
  end

  context "without sharding" do

    it "returns a paginatable collection" do
      collection = ShardedBookmarkedCollection.build(Account::Bookmarker, @user.accounts) do |scope|
        scope.active
      end
      expect(collection.paginate(per_page: 10).size).to equal 1
      expect(collection).to be_is_a BookmarkedCollection::MergeProxy
    end
  end
end
