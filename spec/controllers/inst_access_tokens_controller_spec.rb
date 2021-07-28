# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe InstAccessTokensController do
  include_context "InstAccess setup"

  let_once(:user){ user_with_pseudonym }

  describe "#create" do
    it "requires being logged in" do
      post 'create'
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    context "with valid user session" do
      before(:each){ user_session(user) }

      it "generates an InstAccess token for the requeting user" do
        post 'create', format: 'json'
        expect(response.status).to eq(201)
        token = JSON.parse(response.body)['token']
        access_token = decrypt_and_deserialize_token(token)
        expect(access_token.user_uuid).to eq(user.uuid)
      end

      it "has the user's domain in the token" do
        post 'create', format: 'json'
        token = JSON.parse(response.body)['token']
        access_token = decrypt_and_deserialize_token(token)
        expect(access_token.canvas_domain).to eq("test.host")
      end
    end

    it "doesn't allow using an InstAccess token to generate an InstAccess token" do
      token = InstAccess::Token.for_user(user_uuid: user.uuid, account_uuid: user.account.uuid).to_unencrypted_token_string
      request.headers['Authorization'] = "Bearer #{token}"
      get 'create', format: 'json'
      expect(response.status).to eq(403)
      expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
    end

    context "with a services JWT" do
      include_context "JWT setup"

      it "doesn't allow you to create an InstAccess token" do
        token = build_wrapped_token(user.global_id)
        @request.headers['Authorization'] = "Bearer #{token}"
        get 'create', format: 'json'
        expect(response.status).to eq(403)
        expect(response.body).to match(/cannot generate a JWT when authorized by a JWT/)
      end
    end
  end
end
