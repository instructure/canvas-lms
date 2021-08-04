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

describe InstID do
  let(:signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:encryption_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:signing_priv_key) { signing_keypair.to_s }
  let(:signing_pub_key) { signing_keypair.public_key.to_s }
  let(:encryption_priv_key) { encryption_keypair.to_s }
  let(:encryption_pub_key) { encryption_keypair.public_key.to_s }

  let(:an_inst_id) { described_class.for_user('user-uuid') }
  let(:unencrypted_token) do
    described_class.with_config(signing_key: signing_priv_key) do
      an_inst_id.to_unencrypted_token
    end
  end

  describe ".is_inst_id?" do
    it 'returns false for non-JWTs' do
      expect(described_class.is_inst_id?('asdf1234stuff')).to eq(false)
    end

    it "returns false for JWTs from a different issuer" do
      jwt = JSON::JWT.new(iss: 'bridge').to_s
      expect(described_class.is_inst_id?(jwt)).to eq(false)
    end

    it 'returns true for an InstID' do
      expect(described_class.is_inst_id?(unencrypted_token)).to eq(true)
    end

    it 'returns true for an expired InstID' do
      token = unencrypted_token # instantiate it to set the expiration
      Timecop.travel(3601) do
        expect(described_class.is_inst_id?(token)).to eq(true)
      end
    end
  end

  describe ".for_user" do
    it "blows up without a user" do
      expect do
        described_class.for_user('')
      end.to raise_error(ArgumentError)
    end

    it "creates an instance for the given user uuid" do
      id = described_class.for_user('user-uuid')
      expect(id.user_uuid).to eq('user-uuid')
      expect(id.masquerading_user_uuid).to be_nil
    end

    it "accepts other details" do
      id = described_class.for_user('user-uuid', canvas_domain: 'z.instructure.com', real_user_uuid: 'masq-id', real_user_shard_id: 5)
      expect(id.canvas_domain).to eq('z.instructure.com')
      expect(id.masquerading_user_uuid).to eq('masq-id')
      expect(id.masquerading_user_shard_id).to eq(5)
    end
  end

  context "without being configured" do
    it "#to_token blows up" do
      id = described_class.for_user('user-uuid')
      expect do
        id.to_token
      end.to raise_error(InstID::ConfigError)
    end

    it ".from_token blows up" do
      expect do
        described_class.from_token(unencrypted_token)
      end.to raise_error(InstID::ConfigError)
    end
  end

  context "when configured only for signature verification" do
    around do |example|
      described_class.with_config(signing_key: signing_pub_key) do
        example.run
      end
    end

    it "#to_token blows up" do
      id = described_class.for_user('user-uuid')
      expect do
        id.to_token
      end.to raise_error(InstID::ConfigError)
    end

    it ".from_token decodes the given token" do
      id = described_class.from_token(unencrypted_token)
      expect(id.user_uuid).to eq('user-uuid')
    end

    it ".from_token blows up if the token is expired" do
      token = unencrypted_token # instantiate it to set the expiration
      Timecop.travel(3601) do
        expect do
          described_class.from_token(token)
        end.to raise_error(InstID::TokenExpired)
      end
    end

    it ".from_token blows up if the token has a bad signature" do
      # reconfigure with the wrong signing key so the signature doesn't match
      described_class.with_config(signing_key: encryption_pub_key) do
        expect do
          described_class.from_token(unencrypted_token)
        end.to raise_error(InstID::InvalidToken)
      end
    end
  end

  context "when configured for token generation" do
    around do |example|
      described_class.with_config(
        signing_key: signing_priv_key, encryption_key: encryption_pub_key
      ) do
        example.run
      end
    end

    it "#to_token signs and encrypts the payload, returning a JWE" do
      id_token = an_inst_id.to_token
      # JWEs have 5 base64-encoded sections, each separated by a dot
      expect(id_token).to match(/[\w-]+\.[\w-]+\.[\w-]+\.[\w-]+\.[\w-]+/)
      # normally another service would need to decrypt this, but we'll do it
      # here ourselves to ensure it's been encrypted properly
      jws = JSON::JWT.decode(id_token, encryption_keypair)
      jwt = JSON::JWT.decode(jws.plain_text, signing_keypair)
      expect(jwt[:sub]).to eq('user-uuid')
    end

    it ".from_token still decodes the given token" do
      id = described_class.from_token(unencrypted_token)
      expect(id.user_uuid).to eq('user-uuid')
    end
  end

  describe ".configure" do
    it "blows up if you try to pass a private key for encryption" do
      expect do
        described_class.configure(
          signing_key: signing_priv_key,
          encryption_key: encryption_priv_key
        )
      end.to raise_error(ArgumentError)
    end

    it "blows up if you pass it something that isn't an RSA key" do
      expect do
        described_class.configure(signing_key: "asdf123")
      end.to raise_error(ArgumentError)
    end
  end
end
