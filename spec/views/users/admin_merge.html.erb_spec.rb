# frozen_string_literal: true

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

require_relative "../views_helper"

describe "users/admin_merge" do
  it "only lists accounts that the user can merge users in" do
    user_factory
    @account = Account.create!(name: "My Root Account")
    @account2 = @account.sub_accounts.create!(name: "Sub-Account")
    @account.account_users.create!(user: @user)
    @course1 = Course.create!(account: Account.default)
    @course2 = Course.create!(account: @account2)
    @course1.enroll_teacher(@user)
    @course2.enroll_teacher(@user)

    expect(@user.associated_accounts.map(&:id).sort).to eq [@account.id, @account2.id, Account.default.id].sort

    assign(:current_user, @user)
    user_factory
    assign(:user, @user)

    render "users/admin_merge"
    expect(response).not_to be_nil
    expect(response.body).to match(/My Root Account/)
    expect(response.body).to match(/Sub-Account/)
    expect(response.body).not_to match(/Default Account/)
  end
end
