require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

module Lti
  module Oauth2
    describe AuthorizationValidator do

      let(:developer_key) do
        developer_key_mock = mock("developer_key")
        developer_key_mock.stubs(:active?).returns(true)
        developer_key_mock
      end

      let(:product_family) do
        product_family_mock = mock("product_family")
        product_family_mock.stubs(:developer_key).returns(developer_key)
        product_family_mock
      end

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
            iss: tool_proxy.guid,
            sub: tool_proxy.guid,
            aud: auth_url,
            exp: 1.minute.from_now,
            iat: Time.zone.now.to_i,
            jti: "6b7f5b02-b4e1-4fa3-d6b0-329dee85abff"
          }
        )
        raw_jwt.kid = tool_proxy.guid
        raw_jwt
      end

      let(:authValidator) do
        AuthorizationValidator.new(
          jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
          authorization_url: auth_url
        )
      end

      before do
        Lti::ToolProxy.stubs(:where).returns([])
        Lti::ToolProxy.stubs(:where).with(guid: tool_proxy.guid, workflow_state: 'active').returns([tool_proxy])
      end

      describe "#jwt" do

        it "returns the decoded JWT" do
          expect(authValidator.jwt.signature).to eq raw_jwt.sign(tool_proxy.shared_secret, :HS256).signature
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if any of the assertions are missing" do
          raw_jwt.delete 'exp'
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the following assertions are missing: exp"
        end

        it 'raises JSON::JWT:InvalidFormat if the JWT format is invalid' do
          validator = AuthorizationValidator.new(jwt: 'f3afae3', authorization_url: auth_url)
          expect { validator.jwt }.to raise_error(JSON::JWT::InvalidFormat)
        end

        it 'raises JSON::JWS::VerificationFailed if the signature is invalid' do
          bad_sig_jwt = raw_jwt.sign('invalid', :HS256).to_s
          validator = AuthorizationValidator.new(jwt: bad_sig_jwt, authorization_url: auth_url)
          expect { validator.jwt }.to raise_error(JSON::JWS::VerificationFailed)
        end

        it 'raises JSON::JWS::UnexpectedAlgorithm if the signature type is :none' do
          validator = AuthorizationValidator.new(jwt: raw_jwt.to_s, authorization_url: auth_url)
          expect { validator.jwt }.to raise_error(JSON::JWS::UnexpectedAlgorithm)
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'sub' doesn't equal the ToolProxy guid" do
          raw_jwt['sub'] = 'invalid'
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'sub' must be a valid ToolProxy guid"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'exp' is to far in the future" do
          raw_jwt['exp'] = 5.minutes.from_now.to_i
          Setting.set('lti.oauth2.authorize.max.expiration', 1.minute.to_i)
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'exp' must not be any further than #{60.seconds} seconds in the future"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'exp' is in the past" do
          raw_jwt['exp'] = 5.minutes.ago.to_i
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the JWT has expired"
        end


        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'iat' to old" do
          raw_jwt['iat'] = 10.minutes.ago.to_i
          Setting.set('lti.oauth2.authorize.max_iat_age', 5.minutes.to_s)
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'iat' must be less than #{5.minutes} seconds old"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'iat' is in the future" do
          raw_jwt['iat'] = 10.minutes.from_now.to_i
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'iat' must not be in the future"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'jti' has already been used" do
          enable_cache do
            authValidator.jwt
            duplicate_jwt = AuthorizationValidator.new(
              jwt: raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s,
              authorization_url: auth_url
            )
            expect { duplicate_jwt.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'jti' is invalid"
          end
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'iss' is not the Tool Proxy guid" do
          raw_jwt['iss'] = 'invalid'
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'iss' must be a valid ToolProxy guid"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'aud' is not the authorization endpoint" do
          raw_jwt['aud'] = 'http://google.com/invalid'
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the 'aud' must be the LTI Authorization endpoint"
        end

      end

      describe "#tool_proxy" do

        it 'returns the tool_proxy from the uuid specified in the kid' do
          expect(authValidator.tool_proxy).to eq tool_proxy
        end

        it "raises Lti::Oauth2::AuthorizationValidator::ToolProxyNotFound if it can't find a ToolProxy" do
          raw_jwt.kid = 'invalid'
          expect { authValidator.tool_proxy }.to raise_error Lti::Oauth2::AuthorizationValidator::ToolProxyNotFound
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the 'kid' is missing" do
          raw_jwt.kid = nil
          expect { authValidator.tool_proxy }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'kid' header is required"
        end

        it "raises Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt if the Tool Proxy is not using a split secret" do
          tool_proxy.stubs(:raw_data).returns({'enabled_capability' => []})
          expect { authValidator.jwt }.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                "the Tool Proxy must be using a split secret"
        end

        it "accepts OAuth.splitSecret capability for backwards compatability" do
          tool_proxy.stubs(:raw_data).returns({'enabled_capability' => ['OAuth.splitSecret']})
          expect(authValidator.tool_proxy).to eq tool_proxy
        end

        it "requires an associated developer_key on the product_family" do
          product_family.stubs(:developer_key).returns nil
          expect{authValidator.tool_proxy}.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                    "the Tool Proxy must be associated to a developer key"
        end

        it "requires an associated developer_key on the product_family" do
          developer_key.stubs(:active?).returns false
          expect{authValidator.tool_proxy}.to raise_error Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt,
                                                    "the Developer Key is not active"
        end

      end

    end
  end
end
