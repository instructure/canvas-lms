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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Lti
  module Oauth2
    describe AuthorizationValidator do

      let(:product_family) do
        product_family_mock = mock("product_family")
        product_family_mock.stubs(:developer_key).returns(dev_key)
        product_family_mock
      end

      let(:account) { Account.create! }

      let(:tool_proxy) do
        tool_proxy_mock = mock("tool_proxy")
        tool_proxy_mock.stubs(:guid).returns("3b7f3b02-b481-4f63-a6b0-129dee85abee")
        tool_proxy_mock.stubs(:shared_secret).returns('42')
        tool_proxy_mock.stubs(:raw_data).returns({'enabled_capability' => ['Security.splitSecret']})
        tool_proxy_mock.stubs(:workflow_state).returns('active')
        tool_proxy_mock.stubs(:product_family).returns(product_family)
        tool_proxy_mock
      end

      let(:auth_url) { 'http://example.com/api/lti/authorize' }

      let(:raw_jwt) do
        raw_jwt = JSON::JWT.new(
          {
            sub: tool_proxy.guid,
            aud: auth_url,
            exp: 1.minute.from_now,
            iat: Time.zone.now.to_i,
            jti: "6b7f5b02-b4e1-4fa3-d6b0-329dee85abff"
          }
        )
        raw_jwt
      end
      let(:dev_key) { DeveloperKey.create! }
      let(:raw_jwt_dev_key) do
        raw_jwt = JSON::JWT.new(
          {
            sub: dev_key.global_id,
            aud: auth_url,
            exp: 1.minute.from_now,
            iat: Time.zone.now.to_i,
            jti: SecureRandom.uuid
          }
        )
        raw_jwt
      end

      let(:auth_validator) do
        AuthorizationValidator.new(
          jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
          authorization_url: auth_url,
          context: account
        )
      end

      before do
        Lti::ToolProxy.stubs(:where).returns([])
        Lti::ToolProxy.stubs(:where).with(guid: tool_proxy.guid, workflow_state: 'active').returns([tool_proxy])
      end

      describe "#jwt" do

        it "returns the decoded JWT" do
          expect(auth_validator.jwt.signature).to eq raw_jwt.sign(tool_proxy.shared_secret, :HS256).signature
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if any of the assertions are missing" do
          raw_jwt.delete 'exp'
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the following assertions are missing: exp"
        end

        it 'raises JSON::JWT:InvalidFormat if the JWT format is invalid' do
          validator = AuthorizationValidator.new(jwt: 'f3afae3', authorization_url: auth_url, context: account)
          expect { validator.jwt }.to raise_error(JSON::JWT::InvalidFormat)
        end

        it 'raises JSON::JWS::VerificationFailed if the signature is invalid' do
          bad_sig_jwt = raw_jwt.sign('invalid', :HS256).to_s
          validator = AuthorizationValidator.new(jwt: bad_sig_jwt, authorization_url: auth_url, context: account)
          expect { validator.jwt }.to raise_error(JSON::JWS::VerificationFailed)
        end

        it 'raises JSON::JWS::UnexpectedAlgorithm if the signature type is :none' do
          validator = AuthorizationValidator.new(jwt: raw_jwt.to_s, authorization_url: auth_url, context: account)
          expect { validator.jwt }.to raise_error(JSON::JWS::UnexpectedAlgorithm)
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'exp' is to far in the future" do
          raw_jwt['exp'] = 5.minutes.from_now.to_i
          Setting.set('lti.oauth2.authorize.max.expiration', 1.minute.to_i)
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the 'exp' must not be any further than #{60.seconds} seconds in the future"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'exp' is in the past" do
          raw_jwt['exp'] = 5.minutes.ago.to_i
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the JWT has expired"
        end


        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'iat' to old" do
          raw_jwt['iat'] = 10.minutes.ago.to_i
          Setting.set('lti.oauth2.authorize.max_iat_age', 5.minutes.to_s)
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the 'iat' must be less than #{5.minutes} seconds old"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'iat' is in the future" do
          raw_jwt['iat'] = 10.minutes.from_now.to_i
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the 'iat' must not be in the future"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'jti' has already been used" do
          enable_cache do
            auth_validator.jwt
            duplicate_jwt = AuthorizationValidator.new(
              jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
              authorization_url: auth_url,
              context: account
            )
            expect { duplicate_jwt.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'jti' is invalid"
          end
        end


        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'aud' is not the authorization endpoint" do
          raw_jwt['aud'] = 'http://google.com/invalid'
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the 'aud' must be the LTI Authorization endpoint"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::SecretNotFound if no ToolProxy or developer key" do
          raw_jwt[:sub] = 'invalid'
          validator = AuthorizationValidator.new(
            jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
            authorization_url: auth_url,
            context: account
          )
          expect { validator.validate! }.to raise_error Lti::Oauth2::AuthorizationValidator::SecretNotFound
        end

        context "JWT signed with dev key" do
            let(:auth_validator) do
              AuthorizationValidator.new(
                jwt: raw_jwt_dev_key.sign(dev_key.api_key, :HS256).to_s,
                authorization_url: auth_url,
                code: 'reg_key',
                context: account
              )
            end

            it 'throws an exception if no code is provided' do
              auth_validator = AuthorizationValidator.new(
                jwt: raw_jwt_dev_key.sign(dev_key.api_key, :HS256).to_s,
                authorization_url: auth_url,
                context: account
              )
              expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::MissingAuthorizationCode
            end

            it "returns the decoded JWT" do
              expect(auth_validator.jwt.signature).to eq raw_jwt_dev_key.sign(dev_key.api_key, :HS256).signature
            end
        end
      end

      describe "#developer_key" do
        let(:auth_validator) do
          AuthorizationValidator.new(
            jwt: raw_jwt_dev_key.sign(dev_key.api_key, :HS256).to_s,
            authorization_url: auth_url,
            code: '123',
            context: account
          )
        end

        it 'gets the correct developer key' do
          expect(auth_validator.developer_key).to eq dev_key
        end

        it 'returns nil if developer key not found' do
          validator = AuthorizationValidator.new(
            jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
            authorization_url: auth_url,
            context: account
          )
          expect(validator.developer_key).to be_nil
        end
      end

      describe "#sub" do
        it 'returns the tool proxy guid if tool proxy is present' do
          validator = AuthorizationValidator.new(
            jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
            authorization_url: auth_url,
            context: account
          )
          expect(validator.sub).to eq tool_proxy.guid
        end

        it 'returns the developer key global id if dev key is present' do
          validator = AuthorizationValidator.new(
            jwt: raw_jwt_dev_key.sign(dev_key.api_key, :HS256).to_s,
            authorization_url: auth_url,
            code: '123',
            context: account
          )
          expect(validator.sub).to eq dev_key.global_id
        end
      end

      describe "#tool_proxy" do

        it 'returns the tool_proxy from the uuid specified in the sub' do
          expect(auth_validator.tool_proxy).to eq tool_proxy
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the Tool Proxy is not using a split secret" do
          tool_proxy.stubs(:raw_data).returns({'enabled_capability' => []})
          expect { auth_validator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                       "the Tool Proxy must be using a split secret"
        end

        it "accepts OAuth.splitSecret capability for backwards compatability" do
          tool_proxy.stubs(:raw_data).returns({'enabled_capability' => ['OAuth.splitSecret']})
          expect(auth_validator.tool_proxy).to eq tool_proxy
        end

        it "requires an associated developer_key on the product_family" do
          product_family.stubs(:developer_key).returns nil
          expect { auth_validator.tool_proxy }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                              "the Tool Proxy must be associated to a developer key"
        end

        it "requires an active developer_key" do
          dev_key.stubs(:active?).returns false
          expect { auth_validator.tool_proxy }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                              "the Developer Key is not active"
        end

      end

    end
  end
end
