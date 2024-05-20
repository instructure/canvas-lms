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
#

require_relative "../spec_helper"

describe AccountGradingSettingsController, type: :request do
  require_relative "../spec_helper"

  context "account admin" do
    before(:once) do
      @root_account = Account.default
      @admin = account_admin_user(account: @root_account)
    end

    it "grants access to account admins" do
      user_session(@admin)
      get "/accounts/#{@root_account.id}/grading_settings"
      expect(response).to be_successful
    end

    it "denies access to non-account-admins" do
      course_with_teacher_logged_in(account: @root_account, active_all: true)
      get "/accounts/#{@root_account.id}/grading_settings"
      expect(response).to be_unauthorized
    end

    describe "js_env variables" do
      context "when the account is a root account" do
        it "IS_ROOT_ACCOUNT is true" do
          user_session(@admin)
          get "/accounts/#{@root_account.id}/grading_settings"
          expect(response).to be_successful
          expect(controller.js_env[:IS_ROOT_ACCOUNT]).to be(true)
        end

        it "ROOT_ACCOUNT_ID returns the account's ID" do
          user_session(@admin)
          get "/accounts/#{@root_account.id}/grading_settings"
          expect(response).to be_successful
          expect(controller.js_env[:ROOT_ACCOUNT_ID]).to eq(@root_account.id.to_s)
        end
      end

      context "when the account is a sub account" do
        let(:sub_account) { @root_account.sub_accounts.create! }

        it "IS_ROOT_ACCOUNT is false" do
          user_session(@admin)
          get "/accounts/#{sub_account.id}/grading_settings"
          expect(response).to be_successful
          expect(controller.js_env[:IS_ROOT_ACCOUNT]).to be(false)
        end

        it "ROOT_ACCOUNT_ID returns the root account id" do
          user_session(@admin)
          get "/accounts/#{sub_account.id}/grading_settings"
          expect(response).to be_successful
          expect(controller.js_env[:ROOT_ACCOUNT_ID]).to eq(@root_account.id.to_s)
        end
      end
    end
  end
end
