# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require "spec_helper"

module Lti
  module OAuth2
    describe AccessToken do
      let(:aud) { "http://example.com" }
      let(:sub) { "12084434-0c58-4058-b8c0-4af2da9c2ef8" }
      let(:body) do
        {
          iss: "Canvas",
          sub:,
          exp: 5.minutes.from_now.to_i,
          aud:,
          iat: Time.zone.now.to_i,
          nbf: 30.seconds.ago,
          jti: "34084434-0c58-405a-b8c0-4af2da9c2efd",
          shard_id: Shard.current.id
        }
      end

      describe "#to_s" do
        let(:access_token) { Lti::OAuth2::AccessToken.create_jwt(aud:, sub:) }

        it "is signed by the canvas secret" do
          expect { Canvas::Security.decode_jwt(access_token.to_s) }.to_not raise_error
        end

        it "has an 'iss' set to 'Canvas'" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)["iss"]).to eq("Canvas")
        end

        it "has an 'aud' set to the current domain" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)["aud"]).to eq aud
        end

        it "has an 'exp' of 1 hour" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)["exp"]).to eq 1.hour.from_now.to_i
          end
        end

        it "has an 'iat' set to the current time" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)["iat"]).to eq Time.zone.now.to_i
          end
        end

        it "has a 'nbf' 30 seconds ago" do
          Timecop.freeze do
            expect(Canvas::Security.decode_jwt(access_token.to_s)["nbf"]).to eq 30.seconds.ago.to_i
          end
        end

        it "has a 'jti' that is uniquely generated" do
          jti_1 = Canvas::Security.decode_jwt(access_token.to_s)["jti"]
          jti_2 = Canvas::Security.decode_jwt(AccessToken.create_jwt(aud:, sub:).to_s)["jti"]
          expect(jti_1).not_to eq jti_2
        end

        it "memoizes the jwt" do
          expect(access_token.to_s).to eq access_token.to_s
        end

        it "has a 'sub' that is set to the ToolProxy guid" do
          expect(Canvas::Security.decode_jwt(access_token.to_s)["sub"]).to eq sub
        end

        it "includes the reg_key if passed in" do
          access_token = Lti::OAuth2::AccessToken.create_jwt(aud:, sub:, reg_key: "reg_key")
          expect(Canvas::Security.decode_jwt(access_token.to_s)["reg_key"]).to eq("reg_key")
        end

        it "sets the 'shard_id' to the current shard" do
          access_token = Lti::OAuth2::AccessToken.create_jwt(aud:, sub:, reg_key: "reg_key")
          expect(access_token.shard_id).to eq Shard.current.id
        end
      end

      describe ".from_jwt" do
        let(:token) { Canvas::Security.create_jwt(body) }
        let(:access_token) { Lti::OAuth2::AccessToken.from_jwt(aud:, jwt: token) }

        it "raises an InvalidTokenError if not signed by the correct secret" do
          invalid_token = Canvas::Security.create_jwt(body, nil, "invalid")
          expect { Lti::OAuth2::AccessToken.from_jwt(aud:, jwt: invalid_token) }.to raise_error InvalidTokenError
        end

        it "Sets the 'shard_id'" do
          expect(access_token.shard_id).to eq Shard.current.id
        end
      end

      describe "#validate!" do
        let(:token) { Canvas::Security.create_jwt(body) }
        let(:access_token) { Lti::OAuth2::AccessToken.from_jwt(aud:, jwt: token) }

        it "returns true if there are no errors" do
          expect(access_token.validate!).to be true
        end

        it "raises InvalidTokenError if any of the assertions are missing" do
          body.delete :jti
          expect { access_token.validate! }.to raise_error InvalidTokenError, "the following assertions are missing: jti"
        end

        it "raises an InvalidTokenError if 'iss' is not 'Canvas'" do
          body[:iss] = "invalid iss"
          expect { access_token.validate! }.to raise_error InvalidTokenError, "invalid iss"
        end

        it "raises an InvalidTokenError if the 'exp' is in the past" do
          body[:exp] = 1.hour.ago
          expect { access_token.validate! }.to raise_error InvalidTokenError, "token has expired"
        end

        it "raises an InvalidTokenError if the 'aud' is different than the passed in 'aud'" do
          body[:aud] = "invalid aud"
          expect { access_token.validate! }.to raise_error InvalidTokenError, "invalid aud"
        end

        it "handles an array for aud" do
          body[:aud] = [aud, "file_host"]
          expect { access_token.validate! }.to_not raise_error
        end

        it "raises an InvalidTokenError if the 'iat' is in the future" do
          body[:iat] = 1.hour.from_now
          expect { access_token.validate! }.to raise_error InvalidTokenError, "iat must be in the past"
        end

        it "raises an InvalidTokenError if the 'nbf' is in the future" do
          body[:nbf] = 1.hour.from_now
          expect { access_token.validate! }.to raise_error InvalidTokenError
        end
      end
    end
  end
end
