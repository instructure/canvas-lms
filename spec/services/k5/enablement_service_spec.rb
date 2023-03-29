# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/k5_common"

describe K5::EnablementService do
  include K5Common

  describe "enable_as_k5_account setting" do
    before :once do
      @account = Account.create!
      @user = account_admin_user(account: @account)
    end

    before do
      user_session(@user)
    end

    it "is locked once the setting is enabled" do
      K5::EnablementService.set_k5_settings(@account, true)
      @account.reload
      expect(@account.settings[:enable_as_k5_account][:value]).to be_truthy
      expect(@account.settings[:enable_as_k5_account][:locked]).to be_truthy
    end

    it "is unlocked if the setting is disabled" do
      @account.settings[:enable_as_k5_account] = {
        value: true,
        locked: true
      }
      @account.save!
      K5::EnablementService.set_k5_settings(@account, false)
      @account.reload
      expect(@account.settings[:enable_as_k5_account][:value]).to be_falsey
      expect(@account.settings[:enable_as_k5_account][:locked]).to be_falsey
    end
  end

  describe "k5_accounts set on root account" do
    before :once do
      @root_account = Account.create!
      @subaccount1 = @root_account.sub_accounts.create!
      @subaccount2 = @subaccount1.sub_accounts.create!
      @user = account_admin_user(account: @root_account)
    end

    before do
      user_session(@user)
    end

    it "is nil by default" do
      expect(@root_account.settings[:k5_accounts]).to be_nil
    end

    it "contains root account id if k5 is enabled on root account" do
      K5::EnablementService.set_k5_settings(@root_account, true)
      expect(@root_account.reload.settings[:k5_accounts]).to include(@root_account.id)
    end

    it "contains subaccount id (but not other ids) if k5 is enabled on subaccount" do
      K5::EnablementService.set_k5_settings(@subaccount2, true)
      @root_account.reload
      expect(@root_account.settings[:k5_accounts]).to include(@subaccount2.id)
      expect(@root_account.settings[:k5_accounts]).not_to include(@root_account.id)
      expect(@root_account.settings[:k5_accounts]).not_to include(@subaccount1.id)
    end

    it "contains middle subaccount id (but not other ids) if k5 is enabled on middle subaccount" do
      K5::EnablementService.set_k5_settings(@subaccount1, true)
      @root_account.reload
      expect(@root_account.settings[:k5_accounts]).to include(@subaccount1.id)
      expect(@root_account.settings[:k5_accounts]).not_to include(@root_account.id)
      expect(@root_account.settings[:k5_accounts]).not_to include(@subaccount2.id)
    end

    it "does not contain the root account if k5 is disabled on the root account" do
      toggle_k5_setting(@root_account)
      K5::EnablementService.set_k5_settings(@root_account, false)
      expect(@root_account.reload.settings[:k5_accounts]).to be_empty
    end

    it "does not contain a subaccount if k5 is disabled on that subaccount" do
      toggle_k5_setting(@subaccount1)
      K5::EnablementService.set_k5_settings(@subaccount1, false)
      expect(@root_account.reload.settings[:k5_accounts]).to be_empty
    end

    it "is not changed unless enable_as_k5_account is modified" do
      @root_account.settings[:k5_accounts] = [@root_account.id] # in reality this wouldn't ever contain the account if enable_as_k5_account is off
      @root_account.save!
      K5::EnablementService.set_k5_settings(@root_account, false) # already set to false, so shouldn't touch k5_accounts
      @root_account.reload
      expect(@root_account.settings[:k5_accounts][0]).to be @root_account.id
      expect(@root_account.settings[:k5_accounts].length).to be 1
    end
  end
end
