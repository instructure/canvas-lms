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

require_relative '../../sharding_spec_helper'

describe AuthenticationMethods::InstAccessToken do
  let(:signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:encryption_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:signing_priv_key) { signing_keypair.to_s }
  let(:signing_pub_key) { signing_keypair.public_key.to_s }
  let(:encryption_priv_key) { encryption_keypair.to_s }
  let(:encryption_pub_key) { encryption_keypair.public_key.to_s }

  around(:each) do |example|
    InstAccess.with_config(signing_key: signing_priv_key) do
      example.run
    end
  end

  describe ".parse" do
    it "is false for bad tokens" do
      result = ::AuthenticationMethods::InstAccessToken.parse("not-a-token")
      expect(result).to be_falsey
    end

    it "returns a token object for good tokens" do
      token_obj = ::InstAccess::Token.for_user(user_uuid: 'fake-user-uuid', account_uuid: 'fake-acct-uuid')
      result = ::AuthenticationMethods::InstAccessToken.parse(token_obj.to_unencrypted_token_string)
      expect(result.user_uuid).to eq('fake-user-uuid')
    end
  end

  describe ".load_user_and_pseudonym_context" do
    it "finds the user who created the token" do
      account = Account.default
      user_with_pseudonym(:active_all => true)
      token_obj = ::InstAccess::Token.for_user(user_uuid: @user.uuid, account_uuid: account.uuid)
      ctx = ::AuthenticationMethods::InstAccessToken.load_user_and_pseudonym_context(token_obj, account)
      expect(ctx[:current_user]).to eq(@user)
      expect(ctx[:current_pseudonym]).to eq(@pseudonym)
    end

    it "chooses the local user when a local and shadow user share the same UUID" do
      user_model(id: (10_000_000_000_000 + (rand*10000000).to_i), uuid: 'a-shared-uuid-between-users')
      account = Account.default
      user_with_pseudonym(:active_all => true)
      @user.uuid = 'a-shared-uuid-between-users'
      @user.save!
      token_obj = ::InstAccess::Token.for_user(user_uuid: 'a-shared-uuid-between-users', account_uuid: account.uuid)
      ctx = ::AuthenticationMethods::InstAccessToken.load_user_and_pseudonym_context(token_obj, account)
      expect(ctx[:current_user]).to eq(@user)
      expect(ctx[:current_pseudonym]).to eq(@pseudonym)
    end
  end
end