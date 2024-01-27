# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::DeleteOrphanedAccountUsers do
  before(:once) do
    user_factory
    @base_account_user = @user.account_users.create!(account: Account.default)
    @subaccount = Account.default.sub_accounts.create!
    @sub_account_user = @user.account_users.create!(account: @subaccount)
  end

  it "soft-deletes orphaned account users" do
    Account.where(id: @subaccount).update_all(workflow_state: "deleted") # bypassing callbacks
    DataFixup::DeleteOrphanedAccountUsers.run
    expect(@base_account_user.reload).to be_active
    expect(@sub_account_user.reload).to be_deleted
  end
end
