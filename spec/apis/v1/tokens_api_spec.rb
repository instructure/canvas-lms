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

require_relative "../api_spec_helper"

describe TokensController, type: :request do
  include Api

  describe "#destroy" do
    let_once(:user) { User.create!(workflow_state: "registered") }
    let_once(:token) { user.access_tokens.create! }

    it "allows a user to delete their own tokens" do
      @user = user

      api_call(:delete,
               "/api/v1/users/self/tokens/#{token.id}",
               controller: "tokens",
               action: "destroy",
               format: "json",
               user_id: "self",
               id: token.id)
      assert_status(200)
      expect(token.reload).to be_deleted
    end

    it "does not allow an unrelated user to delete tokens" do
      @user = User.create!(workflow_state: "registered")

      api_call(:delete,
               "/api/v1/users/#{user.id}/tokens/#{token.id}",
               controller: "tokens",
               action: "destroy",
               format: "json",
               user_id: user.id,
               id: token.id)
      assert_status(401)
      expect(token.reload).not_to be_deleted
    end

    context "with an admin" do
      let(:admin) do
        u = User.create!(workflow_state: "registered")
        Account.default.account_users.create!(user: u)
        u
      end

      before do
        @user = admin
        Account.default.pseudonyms.create!(user:, unique_id: "unique@email.com")
      end

      context "with admin_manage_access_tokens feature flag" do
        before { Account.default.enable_feature!(:admin_manage_access_tokens) }

        it "allows them to delete tokens" do
          api_call(:delete,
                   "/api/v1/users/#{user.id}/tokens/#{token.id}",
                   controller: "tokens",
                   action: "destroy",
                   format: "json",
                   user_id: user.id,
                   id: token.id)
          assert_status(200)
          expect(token.reload).to be_deleted
        end

        it "allows them to delete tokens by hint" do
          api_call(:delete,
                   "/api/v1/users/#{user.id}/tokens/#{token.token_hint}",
                   controller: "tokens",
                   action: "destroy",
                   format: "json",
                   user_id: user.id,
                   id: token.token_hint)
          assert_status(200)
          expect(token.reload).to be_deleted
        end

        it "allows the admin to delete the token while masquerading as the user" do
          api_call(:delete,
                   "/api/v1/users/self/tokens/#{token.id}?as_user_id=#{user.id}",
                   controller: "tokens",
                   action: "destroy",
                   format: "json",
                   user_id: "self",
                   as_user_id: user.id,
                   id: token.id)
          assert_status(200)
          expect(token.reload).to be_deleted
        end
      end

      context "without admin_manage_access_tokens feature flag" do
        it "doesn't allow them to delete tokens" do
          api_call(:delete,
                   "/api/v1/users/#{user.id}/tokens/#{token.id}",
                   controller: "tokens",
                   action: "destroy",
                   format: "json",
                   user_id: user.id,
                   id: token.id)
          assert_status(401)
          expect(token.reload).not_to be_deleted
        end
      end
    end
  end
end
