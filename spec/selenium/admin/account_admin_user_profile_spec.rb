
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
    @user3 = user_with_pseudonym(:account => @account, :name => "Random User")
  end

  context 'in admin merge page' do
    before(:each) do
      user_session(@admin)
      visit_merge_user_accounts(@user1.id)
      search_username_input.click
      search_username_input.send_keys("Test")
    end

    it "allow searching for a user to merge with another user", priority: "1", test_id: 3647794 do
      expect(username_search_suggestions).to include_text @user2.name
      expect(username_search_suggestions).not_to include_text @user3.name
    end

    it "displays full user name when a user is selected from suggestions", priority: "1", test_id: 3647794 do
      choose_suggested_username(@user2.name).click

      expect(selected_user.text).to eq "Test User2"
      expect(select_user_button.attribute('href')).to include "/admin_merge?pending_user_id=#{@user2.id}"
    end

    it "navigates to user details page when user is selected", priority: "1", test_id: 3647794 do
      choose_suggested_username(@user2.name).click
      select_user_button.click

      expect(merge_user_page_application_div).to contain_css "table.merge_results"
    end
  end
end
