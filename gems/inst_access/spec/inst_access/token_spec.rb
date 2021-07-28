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
#

require 'spec_helper'
require 'timecop'

describe InstAccess::Token do
  let(:signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:encryption_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:signing_priv_key) { signing_keypair.to_s }
  let(:signing_pub_key) { signing_keypair.public_key.to_s }
  let(:encryption_priv_key) { encryption_keypair.to_s }
  let(:encryption_pub_key) { encryption_keypair.public_key.to_s }

  let(:a_token) { described_class.for_user(user_uuid: 'user-uuid', account_uuid: 'acct-uuid') }
  let(:unencrypted_token) do
    InstAccess.with_config(signing_key: signing_priv_key) do
      a_token.to_unencrypted_token_string
    end
  end

  describe ".is_token?" do
    it 'returns false for non-JWTs' do
      expect(described_class.is_token?('asdf1234stuff')).to eq(false)
    end

    it "returns false for JWTs from a different issuer" do
      jwt = JSON::JWT.new(iss: 'bridge').to_s
      expect(described_class.is_token?(jwt)).to eq(false)
    end

    it 'returns true for an InstAccess token' do
      expect(described_class.is_token?(unencrypted_token)).to eq(true)
    end

    it 'returns true for an expired InstAccess token' do
      token = unencrypted_token # instantiate it to set the expiration
      Timecop.travel(3601) do
        expect(described_class.is_token?(token)).to eq(true)
      end
    end
  end

  describe ".for_user" do
    it "blows up without a user uuid" do
      expect do
        described_class.for_user(user_uuid: '', account_uuid: 'acct-uuid')
      end.to raise_error(ArgumentError)
    end

    it "blows up without an account uuid" do
      expect do
        described_class.for_user(user_uuid: 'user-uuid', account_uuid: '')
      end.to raise_error(ArgumentError)
    end

    it "creates an instance for the given uuids" do
      id = described_class.for_user(user_uuid: 'user-uuid', account_uuid: 'acct-uuid')
      expect(id.user_uuid).to eq('user-uuid')
      expect(id.masquerading_user_uuid).to be_nil
    end

    it "accepts other details" do
      id = described_class.for_user(
        user_uuid: 'user-uuid',
        account_uuid: 'acct-uuid',
        canvas_domain: 'z.instructure.com',
        real_user_uuid: 'masq-id',
        real_user_shard_id: 5
      )
      expect(id.canvas_domain).to eq('z.instructure.com')
      expect(id.masquerading_user_uuid).to eq('masq-id')
      expect(id.masquerading_user_shard_id).to eq(5)
    end
  end

  context "without being configured" do
    it "#to_token_string blows up" do
      id = described_class.for_user(user_uuid: 'user-uuid', account_uuid: 'acct-uuid')
      expect do
        id.to_token_string
      end.to raise_error(InstAccess::ConfigError)
    end

    it ".from_token_string blows up" do
      expect do
        described_class.from_token_string(unencrypted_token)
      end.to raise_error(InstAccess::ConfigError)
    end
  end

  context "when configured only for signature verification" do
    around do |example|
      InstAccess.with_config(signing_key: signing_pub_key) do
        example.run
      end
    end

    it "#to_token_string blows up" do
      id = described_class.for_user(user_uuid: 'user-uuid', account_uuid: 'acct-uuid')
      expect do
        id.to_token_string
      end.to raise_error(InstAccess::ConfigError)
    end

    it ".from_token_string decodes the given token" do
      id = described_class.from_token_string(unencrypted_token)
      expect(id.user_uuid).to eq('user-uuid')
    end

    it ".from_token_string blows up if the token is expired" do
      token = unencrypted_token # instantiate it to set the expiration
      Timecop.travel(3601) do
        expect do
          described_class.from_token_string(token)
        end.to raise_error(InstAccess::TokenExpired)
      end
    end

    it ".from_token_string blows up if the token has a bad signature" do
      # reconfigure with the wrong signing key so the signature doesn't match
      InstAccess.with_config(signing_key: encryption_pub_key) do
        expect do
          described_class.from_token_string(unencrypted_token)
        end.to raise_error(InstAccess::InvalidToken)
      end
    end
  end

  context "when configured for token generation" do
    around do |example|
      InstAccess.with_config(
        signing_key: signing_priv_key, encryption_key: encryption_pub_key
      ) do
        example.run
      end
    end

    it "#to_token_string signs and encrypts the payload, returning a JWE" do
      id_token = a_token.to_token_string
      # JWEs have 5 base64-encoded sections, each separated by a dot
      expect(id_token).to match(/[\w-]+\.[\w-]+\.[\w-]+\.[\w-]+\.[\w-]+/)
      # normally another service would need to decrypt this, but we'll do it
      # here ourselves to ensure it's been encrypted properly
      jws = JSON::JWT.decode(id_token, encryption_keypair)
      jwt = JSON::JWT.decode(jws.plain_text, signing_keypair)
      expect(jwt[:sub]).to eq('user-uuid')
    end

    it ".from_token_string still decodes the given token" do
      id = described_class.from_token_string(unencrypted_token)
      expect(id.user_uuid).to eq('user-uuid')
    end
  end
end
