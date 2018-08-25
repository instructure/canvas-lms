
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'pages/user_profile_page'

describe "admin account people profile" do
  include_context "in-process server selenium tests"
  include UserProfilePage

  before(:once) do
    # set a default account
    @account = Account.default
    account_admin_user(:account => @account, :active_all => true)

    # add two users to account
    @user1 = user_with_pseudonym(:account => @account, :name => "Test User1")
    @user2 = user_with_pseudonym(:account => @account, :name => "Test User2")
  end

  context 'in admin merge page' do
    before(:each) do
      user_session(@admin)
      visit_merge_user_accounts(@user1.id)
    end

    it "allow searching for a user to merge with another user", priority: "1", test_id: 3647794 do
      search_username_input.click
      search_username_input.send_keys("Test")

      expect(username_search_suggestions).to include_text "Test User2"
    end
  end
end
