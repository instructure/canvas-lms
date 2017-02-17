require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/authorization_controller"
require 'json/jwt'

module Lti
  module Ims
    describe AuthorizationController, type: :request do

      let(:account) { Account.new }

      let (:developer_key) { DeveloperKey.create!(redirect_uri: 'http://example.com/redirect') }

      let(:product_family) do
        ProductFamily.create(
          vendor_code: '123',
          product_code: 'abc',
          vendor_name: 'acme',
          root_account: account,
          developer_key: developer_key
        )
      end
      let(:tool_proxy) do
        ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: 'abc',
          product_family: product_family,
          product_version: '1',
          workflow_state: 'active',
          raw_data: {'enabled_capability' => ['Security.splitSecret']},
          lti_version: '1'
        )
      end

      let(:raw_jwt) do
        raw_jwt = JSON::JWT.new(
          {
            iss: tool_proxy.guid,
            sub: tool_proxy.guid,
            aud: lti_oauth2_authorize_url,
            exp: 1.minute.from_now,
            iat: Time.zone.now.to_i,
            jti: SecureRandom.uuid
          }
        )
        raw_jwt.kid = tool_proxy.guid
        raw_jwt
      end

      describe "POST 'authorize'" do
        let(:auth_endpoint) { '/api/lti/authorize' }
        let(:assertion) do
          raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s
        end
        let(:params) do
          {
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: assertion
          }
        end

        it 'responds with 200' do
          post auth_endpoint, params
          expect(response.code).to eq '200'
        end

        it 'includes an expiration' do
          Setting.set('lti.oauth2.access_token.expiration', 1.hour.to_s)
          post auth_endpoint, params
          expect(JSON.parse(response.body)['expires_in']).to eq 1.hour.to_s
        end

        it 'has a token_type of bearer' do
          post auth_endpoint, params
          expect(JSON.parse(response.body)['token_type']).to eq 'bearer'
        end

        it 'returns an access_token' do
          post auth_endpoint, params
          access_token = Lti::Oauth2::AccessToken.create_jwt(aud: @request.host, sub: tool_proxy.guid)
          expect{access_token.validate!}.not_to raise_error
        end

        it "allows the use of the 'OAuth.splitSecret'" do
          tool_proxy.raw_data['enabled_capability'].delete('Security.splitSecret')
          tool_proxy.raw_data['enabled_capability'] << 'OAuth.splitSecret'
          tool_proxy.save!
          post auth_endpoint, params
          expect(response.code).to eq '200'
        end

        it "renders a 400 if the JWT format is invalid" do
          params[:assertion] = '12ad3.4fgs56'
          post auth_endpoint, params
          expect(response.code).to eq '400'
        end

        it "renders a the correct json if the grant_type is invalid" do
          params[:assertion] = '12ad3.4fgs56'
          post auth_endpoint, params
          expect(response.body).to eq({error: 'invalid_grant'}.to_json)
        end

      end
    end
  end
end
