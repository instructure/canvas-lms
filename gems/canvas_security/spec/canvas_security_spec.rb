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

require "spec_helper"
require "canvas_cache"
require "timecop"

describe CanvasSecurity do
  describe "JWT tokens" do
    describe "encoding" do
      describe ".create_jwt" do
        it "generates a token with an expiration" do
          Timecop.freeze(Time.utc(2013, 3, 13, 9, 12)) do
            expires = 1.hour.from_now
            token = CanvasSecurity.create_jwt({ a: 1 }, expires)

            expected_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9." \
                             "eyJhIjoxLCJleHAiOjEzNjMxNjk1MjB9." \
                             "VwDKl46gfjFLPAIDwlkVPze1UwC6H_ApdyWYoUXFT8M"
            expect(token).to eq(expected_token)
          end
        end

        it "generates a token without expiration" do
          token = CanvasSecurity.create_jwt({ a: 1 })
          expected_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9." \
                           "eyJhIjoxfQ." \
                           "Pr4RQfnytL0LMwQ0pJXiKoHmEGAYw2OW3pYJTQM4d9I"
          expect(token).to eq(expected_token)
        end

        it "encodes with configured encryption key" do
          jwt = double
          expect(jwt).to receive(:sign).with(CanvasSecurity.encryption_key, :HS256).and_return("sometoken")
          allow(JSON::JWT).to receive_messages(new: jwt)
          CanvasSecurity.create_jwt({ a: 1 })
        end

        it "encodes with the supplied key" do
          jwt = double
          expect(jwt).to receive(:sign).with("mykey", :HS256).and_return("sometoken")
          allow(JSON::JWT).to receive_messages(new: jwt)
          CanvasSecurity.create_jwt({ a: 1 }, nil, "mykey")
        end

        it "encodes with supplied algorithm" do
          jwt = double
          expect(jwt).to receive(:sign).with("mykey", :HS512).and_return("sometoken")
          allow(JSON::JWT).to receive_messages(new: jwt)
          CanvasSecurity.create_jwt({ a: 1 }, nil, "mykey", :HS512)
        end
      end

      describe ".create_encrypted_jwt" do
        let(:signing_secret) { "asdfasdfasdfasdfasdfasdfasdfasdf" }
        let(:encryption_secret) { "jkl;jkl;jkl;jkl;jkl;jkl;jkl;jkl;" }
        let(:payload) { { arbitrary: "data" } }

        it "builds up an encrypted token" do
          jwt = CanvasSecurity.create_encrypted_jwt(payload, signing_secret, encryption_secret)
          expect(jwt.length).to eq(225)
        end

        it "raises InvalidJwtKey if encryption_secret is nil" do
          expect do
            CanvasSecurity.create_encrypted_jwt(payload, signing_secret, nil)
          end.to raise_error(CanvasSecurity::InvalidJwtKey)
        end

        it "raises InvalidJwtKey if signing_secret is nil" do
          expect do
            CanvasSecurity.create_encrypted_jwt(payload, nil, encryption_secret)
          end.to raise_error(CanvasSecurity::InvalidJwtKey)
        end

        it "can unpack encrypted jwts again" do
          jwt = CanvasSecurity.create_encrypted_jwt(payload, signing_secret, encryption_secret)
          original = CanvasSecurity.decrypt_encrypted_jwt(jwt, signing_secret, encryption_secret)
          expect(original[:arbitrary]).to eq("data")
        end

        it "gracefully handles using a different encryption secret" do
          different_secret = encryption_secret.upcase
          jwt = CanvasSecurity.create_encrypted_jwt(payload, signing_secret, different_secret)
          expect do
            CanvasSecurity.decrypt_encrypted_jwt(jwt, signing_secret, encryption_secret)
          end.to raise_error(CanvasSecurity::InvalidToken)
        end
      end
    end

    describe ".base64_encode" do
      it "trims off newlines" do
        input = "SuperSuperSuperSuperSuperSuperSuperSuper" \
                "SuperSuperSuperSuperSuperSuperSuperSuperLongString"
        output = "U3VwZXJTdXBlclN1cGVyU3VwZXJTdXBlclN1cGVy" \
                 "U3VwZXJTdXBlclN1cGVyU3VwZXJTdXBlclN1cGVy" \
                 "U3VwZXJTdXBlclN1cGVyU3VwZXJMb25nU3RyaW5n"
        expect(CanvasSecurity.base64_encode(input)).to eq(output)
      end
    end

    describe "decoding" do
      let(:key) { "mykey" }

      def test_jwt(claims = {})
        JSON::JWT.new({ a: 1 }.merge(claims)).sign(key, :HS256).to_s
      end

      around do |example|
        Timecop.freeze(Time.utc(2013, 3, 13, 9, 12), &example)
      end

      it "decodes token" do
        body = CanvasSecurity.decode_jwt(test_jwt, [key])
        expect(body).to eq({ "a" => 1 })
      end

      it "returns token body with indifferent access" do
        body = CanvasSecurity.decode_jwt(test_jwt, [key])
        expect(body[:a]).to eq(1)
        expect(body["a"]).to eq(1)
      end

      it "checks using past keys" do
        body = CanvasSecurity.decode_jwt(test_jwt, ["newkey", key])
        expect(body).to eq({ "a" => 1 })
      end

      it "raises on an expired token" do
        expired_jwt = test_jwt(exp: 1.hour.ago)
        expect { CanvasSecurity.decode_jwt(expired_jwt, [key]) }.to(
          raise_error(CanvasSecurity::TokenExpired)
        )
      end

      it "does not raise an error on a token with expiration in the future" do
        valid_jwt = test_jwt(exp: 1.hour.from_now)
        body = CanvasSecurity.decode_jwt(valid_jwt, [key])
        expect(body[:a]).to eq(1)
      end

      it "errors if the 'nbf' claim is in the future" do
        back_to_the_future_jwt = test_jwt(exp: 1.hour.from_now, nbf: 30.minutes.from_now)
        expect { CanvasSecurity.decode_jwt(back_to_the_future_jwt, [key]) }.to(
          raise_error(CanvasSecurity::InvalidToken)
        )
      end

      it "allows 5 minutes of future clock skew" do
        back_to_the_future_jwt = test_jwt(exp: 1.hour.from_now, nbf: 1.minute.from_now, iat: 1.minute.from_now)
        body = CanvasSecurity.decode_jwt(back_to_the_future_jwt, [key])
        expect(body[:a]).to eq 1
      end

      it "produces an InvalidToken error if string isn't a jwt (even if it looks like one)" do
        # this is an example token which base64_decodes to a thing that looks like a jwt because of the periods
        not_a_jwt = CanvasSecurity.base64_decode("1050~LvwezC5Dd3ZK9CR1lusJTRv24dN0263txia3KF3mU6pDjOv5PaoX8Jv4ikdcvoiy")
        expect { CanvasSecurity.decode_jwt(not_a_jwt, [key]) }.to raise_error(CanvasSecurity::InvalidToken)
      end
    end
  end

  describe "hmac_sha512" do
    let(:message) { "asdf1234" }

    it "verifies items signed with the same secret" do
      shared_secret = "super-sekrit"
      signature = CanvasSecurity.sign_hmac_sha512(message, shared_secret)
      verification = CanvasSecurity.verify_hmac_sha512(message, signature, shared_secret)
      expect(verification).to be_truthy
    end

    it "rejects items signed with different secrets" do
      signature = CanvasSecurity.sign_hmac_sha512(message, "super-sekrit")
      verification = CanvasSecurity.verify_hmac_sha512(message, signature, "sekrit-super")
      expect(verification).to be_falsey
    end

    it "internally manages signing-secret rotation" do
      allow(CanvasSecurity).to receive_messages(services_signing_secret: "current_secret", services_previous_signing_secret: "previous_secret")
      signature = CanvasSecurity.sign_hmac_sha512(message, "previous_secret")
      verification = CanvasSecurity.verify_hmac_sha512(message, signature, "current_secret")
      expect(verification).to be_truthy
    end
  end

  describe ".config" do
    before { described_class.instance_variable_set(:@config, nil) }

    after  { described_class.instance_variable_set(:@config, nil) }

    it "loads config as erb from config/security.yml" do
      config = "test:\n  encryption_key: <%= ENV['ENCRYPTION_KEY'] %>"
      expect(File).to receive(:read).with(Rails.root.join("config/security.yml").to_s).and_return(config)
      expect(ENV).to receive(:[]).with("ENCRYPTION_KEY").and_return("secret")
      expect(CanvasSecurity.config).to eq("encryption_key" => "secret")
    end

    it "falls back to Vault for the encryption key if not defined in the config file" do
      config = "test:\n  another_key: true"
      expect(File).to receive(:read).with(Rails.root.join("config/security.yml").to_s).and_return(config)
      expect(Rails).to receive(:application).and_return(OpenStruct.new({ credentials: OpenStruct.new({ security_encryption_key: "secret" }) }))
      expect(CanvasSecurity.config).to eq("encryption_key" => "secret", "another_key" => true)
    end
  end
end
