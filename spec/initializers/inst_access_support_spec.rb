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

describe InstAccessSupport do
  let(:signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:encryption_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:signing_priv_key) { signing_keypair.to_s }
  let(:signing_pub_key) { signing_keypair.public_key.to_s }
  let(:encryption_priv_key) { encryption_keypair.to_s }
  let(:encryption_pub_key) { encryption_keypair.public_key.to_s }
  let(:service_keys) { nil }

  describe ".configure" do
    before do
      allow(Rails.application.credentials).to receive(:inst_access_signature).and_return(
        {
          private_key: Base64.encode64(signing_priv_key),
          encryption_public_key: Base64.encode64(encryption_pub_key),
          service_keys:
        }
      )
    end

    it "configures signing and encryption keys using base64 values" do
      expect do
        InstAccessSupport.configure_inst_access!
      end.to_not raise_error

      expect(InstAccess.config.signing_key.to_s).to eq signing_keypair.to_s
      expect(InstAccess.config.encryption_key.to_s).to eq encryption_keypair.public_key.to_s
    end

    context "with an 'oct' type service_key" do
      let(:secret) { SecureRandom.random_bytes(64) } # 512 bits for HS512
      let(:secret_encoded) { Base64.urlsafe_encode64 secret }
      let(:service_keys) do
        {
          "oct-service/purpose": {
            issuer: "service.instructure.com",
            key_type: "oct",
            secret: secret_encoded
          }
        }
      end

      it "configures service_jwks with the provided 'k' secret" do
        InstAccessSupport.configure_inst_access!

        configured_jwks = InstAccess.config.service_jwks
        expect(configured_jwks).to be_a JSON::JWK::Set

        configured_jwk = configured_jwks["oct-service/purpose"]
        expect(configured_jwk).to be_oct
        expect(configured_jwk.normalize).to eq(
          {
            kty: "oct",
            k: secret_encoded
          }
        )

        # Note that for strict correctness, we would expect this to be true:
        #
        # expect(configured_jwk.to_key).to eq secret
        #
        # Instead, the json-jwt library returns the base64 encoded string. This
        # is not a problem as long as both sides are using the same library, but
        # it's not to spec; and fixing it would be a breaking change.
      end
    end

    context "with an 'RSA' type service_key" do
      let(:public_key) { OpenSSL::PKey::RSA.new(2048).public_key }
      let(:jwk) { public_key.to_jwk }
      let(:service_keys) do
        {
          "rsa-service/purpose": {
            issuer: "service.instructure.com",
            key_type: jwk[:kty].to_s,
            e: jwk[:e],
            n: jwk[:n]
          }
        }
      end

      it "configures service_jwks with the provided 'e' and 'n' values" do
        InstAccessSupport.configure_inst_access!

        configured_jwks = InstAccess.config.service_jwks
        expect(configured_jwks).to be_a JSON::JWK::Set

        configured_jwk = configured_jwks["rsa-service/purpose"]
        expect(configured_jwk).to be_rsa
        expect(configured_jwk.to_key.to_pem).to eq public_key.to_pem
      end
    end
  end
end
