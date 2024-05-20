# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe OAuth2ProviderController do
  describe "GET auth" do
    let_once(:key) do
      d = DeveloperKey.create! redirect_uri: "https://example.com"
      enable_developer_key_account_binding!(d)
      d
    end

    it "renders a 401 when there is no client_id" do
      get :auth
      assert_status(401)
      expect(response.body).to match(/unknown client/)
      expect(response["WWW-Authenticate"]).to_not be_blank
    end

    it "renders 400 on a bad redirect_uri" do
      get :auth, params: { client_id: key.id }
      assert_status(400)
      expect(response.body).to match(/redirect_uri does not match/)
    end

    context "with invalid scopes" do
      let(:dev_key) { DeveloperKey.create! redirect_uri: "https://example.com", require_scopes: true, scopes: [] }

      it "renders 302" do
        get :auth, params: {
          client_id: dev_key.id,
          redirect_uri: dev_key.redirect_uri,
          response_type: "code",
          scope: "not|valid"
        }
        expect(response).to redirect_to(/invalid_scope/)
      end

      it "renders 302 when scopes empty" do
        get :auth, params: {
          client_id: dev_key.id,
          redirect_uri: dev_key.redirect_uri,
          response_type: "code"
        }
        expect(response).to redirect_to(/invalid_scope/)
      end
    end

    it "redirects back with an error for invalid response_type" do
      get :auth,
          params: { client_id: key.id,
                    redirect_uri: "https://example.com/oauth/callback",
                    state: "value" }
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://example.com/oauth/callback\?error=unsupported_response_type})
      expect(response.location).to match("&state=value")
    end

    it "redirects to the login url" do
      get :auth,
          params: { client_id: key.id,
                    redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI,
                    response_type: "code" }
      expect(response).to redirect_to(login_url)
    end

    it "passes on canvas_login if provided" do
      get :auth, params: { client_id: key.id,
                           redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI,
                           canvas_login: 1,
                           response_type: "code" }
      expect(response).to redirect_to(login_url(canvas_login: 1))
    end

    it "passes pseudonym_session[unique_id] to login to populate username textbox" do
      get :auth, params: { :client_id => key.id,
                           :redirect_uri => Canvas::OAuth::Provider::OAUTH2_OOB_URI,
                           "unique_id" => "test",
                           :force_login => true,
                           :response_type => "code" }
      expect(response).to redirect_to(login_url + "?force_login=true&pseudonym_session%5Bunique_id%5D=test")
    end

    it 'redirects with "login_required" if prompt=none' do
      get :auth,
          params: { client_id: key.id,
                    redirect_uri: "https://example.com/oauth/callback",
                    prompt: "none",
                    response_type: "code",
                    state: "value" }
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://example.com/oauth/callback})
      redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(redirect_query_params["error"]).to eq "login_required"
      expect(redirect_query_params["state"]).to eq "value"
    end

    it 'redirects with "unsupported_prompt_type" if prompt is not recognized' do
      get :auth,
          params: { client_id: key.id,
                    redirect_uri: "https://example.com/oauth/callback",
                    prompt: "yesplz",
                    response_type: "code",
                    state: "value" }
      expect(response).to be_redirect
      expect(response.location).to match(%r{^https://example.com/oauth/callback})
      redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(redirect_query_params["error"]).to eq "unsupported_prompt_type"
      expect(redirect_query_params["state"]).to eq "value"
    end

    context "with a user logged in" do
      before :once do
        user_with_pseudonym(active_all: 1, password: "qwertyuiop")
      end

      before do
        user_session(@user)

        redis = double("Redis")
        allow(redis).to receive(:setex)
        allow(Canvas).to receive_messages(redis:)
      end

      it "redirects to the confirm url if the user has no token" do
        get :auth,
            params: { client_id: key.id,
                      redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI,
                      response_type: "code" }
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it "redirects to login_url with ?force_login=1" do
        get :auth,
            params: { client_id: key.id,
                      redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI,
                      response_type: "code",
                      force_login: 1 }
        expect(response).to redirect_to(login_url(force_login: 1))
      end

      it "redirects to login_url when oauth2 session is nil" do
        get :confirm
        expect(flash[:error]).to eq "Must submit new OAuth2 request"
        expect(response).to redirect_to(login_url)
      end

      it "redirects to the redirect uri if the user already has remember-me token" do
        @user.access_tokens.create!({ developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil })
        get :auth,
            params: { client_id: key.id,
                      redirect_uri: "https://example.com",
                      response_type: "code",
                      scope: "/auth/userinfo" }
        expect(response).to be_redirect
        expect(response.location).to match(%r{https://example.com})
      end

      it "does not reuse userinfo tokens for other scopes" do
        @user.access_tokens.create!({ developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil })
        get :auth, params: { client_id: key.id,
                             redirect_uri: "https://example.com",
                             response_type: "code" }
        expect(response).to redirect_to(oauth2_auth_confirm_url)
      end

      it "redirects to the redirect uri if the developer key is trusted" do
        key.trusted = true
        key.save!
        get :auth, params: { client_id: key.id,
                             redirect_uri: "https://example.com",
                             response_type: "code",
                             scope: "/auth/userinfo" }
        expect(response).to be_redirect
        expect(response.location).to match(%r{https://example.com})
      end

      context 'when "prompt=none"' do
        let(:params) do
          {
            client_id: key.id,
            redirect_uri: "https://example.com",
            response_type: "code",
            scope: "/auth/userinfo",
            prompt: "none",
            state: "value"
          }
        end

        it "redirects to the redirect uri if the user already has remember-me token" do
          @user.access_tokens.create!({ developer_key: key, remember_access: true, scopes: ["/auth/userinfo"], purpose: nil })
          get(:auth, params:)
          expect(response).to be_redirect
          expect(response.location).to match(%r{https://example.com})
        end

        it "redirects to the redirect uri if the developer key is trusted" do
          key.trusted = true
          key.save!
          get(:auth, params:)
          expect(response).to be_redirect
          expect(response.location).to match(%r{https://example.com})
        end

        it 'redirects with "interaction_required" if the current session cannot be used without a prompt' do
          get(:auth, params:)
          expect(response).to be_redirect
          expect(response.location).to match(%r{https://example.com})
          redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          expect(redirect_query_params["error"]).to eq "interaction_required"
          expect(redirect_query_params["state"]).to eq "value"
        end
      end

      shared_examples_for "the authorization endpoint" do
        let(:account_developer_key) { raise "set in examples" }
        let(:account) { account_developer_key.account || Account.site_admin }

        it 'redirects with "unauthorized_client" if binding does not exist for the account' do
          get :auth, params: { client_id: account_developer_key.id, redirect_uri: "https://example.com", response_type: "code", state: "value" }
          redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          expect(redirect_query_params["error"]).to eq "unauthorized_client"
          expect(redirect_query_params["state"]).to eq "value"
        end

        it 'redirects with "unauthorized_client" if binding for the account is set to "allow"' do
          binding = account_developer_key.developer_key_account_bindings.find_or_create_by(account:)
          binding.update!(workflow_state: "allow")
          get :auth, params: { client_id: account_developer_key.id, redirect_uri: "https://example.com", response_type: "code", state: "value" }
          redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          expect(redirect_query_params["error"]).to eq "unauthorized_client"
          expect(redirect_query_params["state"]).to eq "value"
        end

        it 'redirects with "unauthorized_client" if binding for the account is set to "off"' do
          binding = account_developer_key.developer_key_account_bindings.find_or_create_by(account:)
          binding.update!(workflow_state: "off")
          get :auth, params: { client_id: account_developer_key.id, redirect_uri: "https://example.com", response_type: "code", state: "value" }
          redirect_query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          expect(redirect_query_params["error"]).to eq "unauthorized_client"
          expect(redirect_query_params["state"]).to eq "value"
        end

        it 'redirects to confirmation page when the binding for the account is set to "on"' do
          binding = account_developer_key.developer_key_account_bindings.find_or_create_by(account:)
          binding.update!(workflow_state: "on")
          get :auth, params: { client_id: account_developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
          expect(response.location).to eq "http://test.host/login/oauth2/confirm"
        end
      end

      context "when key is a site admin key" do
        let(:root_account) { Account.default }
        let(:developer_key) { DeveloperKey.create!(redirect_uri: "https://example.com") }
        let(:root_account_binding) { developer_key.developer_key_account_bindings.find_by(account: root_account) }
        let(:sa_account_binding) { developer_key.developer_key_account_bindings.find_by(account: Account.site_admin) }
        let(:redirect_query_params) { Rack::Utils.parse_query(URI.parse(response.location).query) }

        it_behaves_like "the authorization endpoint" do
          let(:account_developer_key) { developer_key }
        end

        context "when root account binding exists" do
          before do
            developer_key.developer_key_account_bindings.create!(account: root_account)
          end

          it 'redirects with "unauthorized_client" if binding for SA is "off" and root account binding is "on"' do
            root_account_binding.update!(workflow_state: "on")
            sa_account_binding.update!(workflow_state: "off")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(redirect_query_params["error"]).to eq "unauthorized_client"
          end

          it 'redirects with "unauthorized_client" if binding for SA is "allow" and binding for root account is "allow"' do
            root_account_binding.update!(workflow_state: "allow")
            sa_account_binding.update!(workflow_state: "allow")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(redirect_query_params["error"]).to eq "unauthorized_client"
          end

          it 'redirects with "unauthorized_client" if binding for SA is "allow" and binding for root account is "off"' do
            root_account_binding.update!(workflow_state: "off")
            sa_account_binding.update!(workflow_state: "allow")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(redirect_query_params["error"]).to eq "unauthorized_client"
          end

          it 'redirects with "unauthorized_client" if binding for SA is "off" and binding for root account is "off"' do
            root_account_binding.update!(workflow_state: "off")
            sa_account_binding.update!(workflow_state: "off")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(redirect_query_params["error"]).to eq "unauthorized_client"
          end

          it 'redirects to confirmation page if binding for SA is "allow" and binding for root account is "on"' do
            root_account_binding.update!(workflow_state: "on")
            sa_account_binding.update!(workflow_state: "allow")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(response.location).to eq "http://test.host/login/oauth2/confirm"
          end

          it 'redirects to confirmation page if binding for SA is "on" and binding for root account is "off"' do
            root_account_binding.update!(workflow_state: "off")
            sa_account_binding.update!(workflow_state: "on")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(response.location).to eq "http://test.host/login/oauth2/confirm"
          end

          it 'redirects to confirmation page if binding for SA is "on" and binding for root account is "allow"' do
            root_account_binding.update!(workflow_state: "allow")
            sa_account_binding.update!(workflow_state: "on")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(response.location).to eq "http://test.host/login/oauth2/confirm"
          end

          it 'redirects to confirmation page if binding for SA is "on" and binding for root account is "on"' do
            root_account_binding.update!(workflow_state: "on")
            sa_account_binding.update!(workflow_state: "on")
            get :auth, params: { client_id: developer_key.id, redirect_uri: "https://example.com", response_type: "code" }
            expect(response.location).to eq "http://test.host/login/oauth2/confirm"
          end
        end
      end

      context "when key is a root account key" do
        let(:root_account) { Account.default }

        it_behaves_like "the authorization endpoint" do
          let(:account_developer_key) { DeveloperKey.create!(redirect_uri: "https://example.com", account: root_account) }
        end
      end
    end
  end

  describe "POST token" do
    subject { response }

    let_once(:key) { DeveloperKey.create! scopes: [TokenScopes::USER_INFO_SCOPE[:scope]] }
    let_once(:other_key) { DeveloperKey.create! }
    let_once(:inactive_key) { DeveloperKey.create! workflow_state: "inactive" }
    let_once(:user) { User.create!(locale: "zh-Hant") }
    let(:old_token) { user.access_tokens.create!(developer_key: key) }
    let(:client_id) { key.id }
    let(:client_secret) { key.api_key }
    let(:base_params) do
      {
        client_id:,
        client_secret:,
        grant_type:,
        redirect_uri: "https://example.com"
      }
    end

    shared_examples_for "common oauth2 token checks" do
      let(:success_params) { raise "Override in spec" }
      let(:success_setup) { nil }
      let(:success_token_keys) { raise "Override in spec" }
      let(:before_post) { nil }
      let(:overrides) { {} }

      before do
        before_post
        parameters = base_params.merge(overrides)
        post :token, params: parameters
      end

      context "invalid key" do
        context "key is inactive" do
          let(:client_id) { inactive_key.id }

          it "validate that invalid_client is in response" do
            expect(subject).to have_http_status(:unauthorized)
            expect(response.body).to match(/invalid_client/)
          end
        end

        context "key is missing" do
          let(:client_id) { nil }

          it { is_expected.to have_http_status(:unauthorized) }
        end

        context "key is not found" do
          let(:client_id) { 0 }

          it { is_expected.to have_http_status(:unauthorized) }
        end

        context "key is not an integer" do
          let(:client_id) { "a" }

          it { is_expected.to have_http_status(:unauthorized) }
        end
      end

      context "secret and key combo invalid" do
        context "key secret and provided secret do not match" do
          let(:client_secret) { other_key.api_key }

          it do
            if grant_type == "client_credentials" && !key.site_admin_service_auth?
              skip "not valid for this grant_type"
            end

            expect(subject).to have_http_status(:unauthorized)
          end
        end

        context "key secret is not provided" do
          let(:client_secret) { nil }

          it do
            if grant_type == "client_credentials" && !key.site_admin_service_auth?
              skip "not valid for this grant_type"
            end

            expect(subject).to have_http_status(:unauthorized)
          end
        end
      end

      context "valid request" do
        let(:before_post) { success_setup }
        let(:overrides) { success_params }

        it { is_expected.to have_http_status(:ok) }

        it "outputs the token json if everything checks out" do
          json = response.parsed_body
          expect(json.keys.sort).to match_array(success_token_keys)
          expect(json["token_type"]).to eq "Bearer"
        end

        context "with global_id as client_id" do
          let(:client_id) { key.global_id }

          it { is_expected.to have_http_status(:ok) }
        end
      end

      context "invalid grant_type provided" do
        context "unsupported grant_type" do
          let(:grant_type) { "urn:unsupported" }

          it "expect redirect with error in query" do
            expect(subject).to have_http_status(:bad_request)
            expect(response.body).to match(/unsupported_grant_type/)
          end
        end

        context "missing grant_type" do
          let(:grant_type) { nil }

          it { is_expected.to have_http_status(:bad_request) }
        end
      end
    end

    context "authorization_code" do
      let(:grant_type) { "authorization_code" }
      let(:valid_code) { "thecode" }
      let(:valid_code_redis_key) { "#{Canvas::OAuth::Token::REDIS_PREFIX}#{valid_code}" }
      let(:redis) do
        redis = double("Redis")
        allow(redis).to receive(:get)
        allow(redis).to receive(:get).with(valid_code_redis_key).and_return(%({"client_id": #{key.id}, "user": #{user.id}}))
        allow(redis).to receive(:del).with(valid_code_redis_key).and_return(%({"client_id": #{key.id}, "user": #{user.id}}))
        redis
      end

      before { allow(Canvas).to receive_messages(redis:) }

      it_behaves_like "common oauth2 token checks" do
        let(:success_params) { { code: valid_code } }
        let(:success_setup) do
          expect(redis).to receive(:del).with(valid_code_redis_key).at_least(:once)
        end
        let(:success_token_keys) { %w[access_token refresh_token user expires_in token_type canvas_region] }
      end

      it "renders a 400 if a code is not provided for an authorization_code grant" do
        post :token, params: base_params

        assert_status(400)
      end

      it "renders a 400 if the provided code does not match a token" do
        post :token, params: base_params.merge(code: "NotALegitCode")
        assert_status(400)
        expect(response.body).to match(/authorization_code not found/)
      end

      it "renders a 400 if the provided code is for the wrong key" do
        post :token, params: base_params.merge(client_id: other_key.id.to_s, client_secret: other_key.api_key, code: valid_code)
        assert_status(400)
        expect(response.body).to match(/incorrect client/)
      end

      it "default grant_type to authorization_code if none is supplied and code is present" do
        expect(redis).to receive(:del).with(valid_code_redis_key).at_least(:once)
        post :token, params: base_params.merge(code: valid_code)
        expect(response).to be_successful
        json = response.parsed_body
        expect(json.keys.sort).to match_array %w[access_token refresh_token user expires_in token_type canvas_region]
        expect(json.dig("user", "effective_locale")).to eq "zh-Hant"
      end

      it "deletes existing tokens for the same key when replace_tokens=1" do
        old_token
        post :token, params: base_params.merge(code: valid_code, replace_tokens: "1")
        expect(response).to be_successful
        expect(AccessToken.not_deleted.exists?(old_token.id)).to be(false)
      end

      it "does not delete existing tokens without replace_tokens" do
        old_token
        post :token, params: base_params.merge(code: valid_code)
        expect(response).to be_successful
        expect(AccessToken.not_deleted.exists?(old_token.id)).to be(true)
      end
    end

    context "grant_type refresh_token" do
      let(:grant_type) { "refresh_token" }
      let(:refresh_token) { old_token.plaintext_refresh_token }

      it_behaves_like "common oauth2 token checks" do
        let(:success_params) { { refresh_token: } }
        let(:success_token_keys) { %w[access_token user expires_in token_type canvas_region] }
      end

      it "does not generate a new access_token with an invalid refresh_token" do
        post :token, params: base_params.merge(refresh_token: refresh_token + "ASDF")
        assert_status(400)
      end

      it "generates a new access_token" do
        post :token, params: base_params.merge(refresh_token:)
        json = response.parsed_body
        expect(json["access_token"]).to_not eq old_token.full_token
      end

      it "errors with a mismatched client id and refresh_token" do
        post :token, params: base_params.merge(client_id: other_key.id, client_secret: other_key.api_key, refresh_token:)
        assert_status(400)
        expect(response.body).to include "invalid_grant"
      end

      it "is able to regenerate access_token multiple times" do
        post :token, params: base_params.merge(refresh_token:)
        expect(response).to be_successful
        json = response.parsed_body
        expect(json["access_token"]).to_not eq old_token.full_token

        access_token = json["access_token"]
        post :token, params: base_params.merge(refresh_token:)
        expect(response).to be_successful
        json = response.parsed_body
        expect(json["access_token"]).to_not eq access_token
      end
    end

    context "with client_credentials grant type and service key" do
      include_context "InstAccess setup"

      let(:grant_type) { "client_credentials" }
      let(:service_user) { user_model }

      before do
        Account.site_admin.enable_feature!(:site_admin_service_auth)
        key.update!(service_user:, internal_service: true)
      end

      context "with valid parameters" do
        before { post :token, params: base_params }

        it { is_expected.to be_successful }

        it "returns a token for the service user" do
          token = AuthenticationMethods::InstAccessToken.parse(
            subject.parsed_body["access_token"]
          )

          expect(token.user_uuid).to eq service_user.uuid
        end
      end

      it_behaves_like "common oauth2 token checks" do
        let(:success_params) { { grant_type: } }
        let(:success_token_keys) { %w[access_token token_type expires_in] }

        let(:success_setup) { key.update!(service_user:) }
        let(:before_post) { key.update!(service_user:) }
      end

      context "when the service user is not present" do
        before do
          key.update!(service_user: nil)
          post :token, params: base_params
        end

        it { is_expected.to be_bad_request }
      end

      context "whent the service user is not active" do
        before do
          service_user.destroy!
          post :token, params: base_params
        end

        it { is_expected.to be_bad_request }

        it "includes the error and description in the response" do
          expect(subject.parsed_body).to eq(
            {
              "error" => "invalid_request",
              "error_description" => "No active service"
            }
          )
        end
      end

      context "when the developer key is not active" do
        before do
          key.destroy!
          post :token, params: base_params
        end

        it { is_expected.to be_unauthorized }

        it "includes the error and description in the response" do
          expect(subject.parsed_body).to eq(
            {
              "error" => "invalid_client",
              "error_description" => "unknown client"
            }
          )
        end
      end
    end

    context "client_credentials" do
      let(:grant_type) { "client_credentials" }
      let(:aud) { Rails.application.routes.url_helpers.oauth2_token_url(host: "test.host") }
      let(:iat) { 1.minute.ago.to_i }
      let(:exp) { 10.minutes.from_now.to_i }
      let(:signing_key) { JSON::JWK.new(key.private_jwk) }
      let(:jwt) do
        {
          iss: "someiss",
          sub: client_id,
          aud:,
          iat:,
          exp:,
          jti: SecureRandom.uuid
        }
      end
      let(:jws) { JSON::JWT.new(jwt).sign(signing_key, :RS256).to_s }
      let(:client_credentials_params) do
        {
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          client_assertion: jws,
          redirect_uri: "https://example.com",
          scope: TokenScopes::USER_INFO_SCOPE[:scope]
        }
      end

      before do
        key.generate_rsa_keypair! overwrite: true
        key.save!
      end

      it_behaves_like "common oauth2 token checks" do
        let(:success_params) { client_credentials_params }
        let(:overrides) { client_credentials_params }
        let(:success_token_keys) { %w[access_token token_type expires_in scope] }
      end

      describe "additional client_credentials checks" do
        subject do
          parameters = { grant_type: "client_credentials" }.merge(client_credentials_params)
          post :token, params: parameters
          response
        end

        context "with bad aud" do
          let(:aud) { "doesnotexist" }

          it "validate that invalid_request is in response" do
            expect(subject).to have_http_status :bad_request
            expect(response.body).to match(/invalid_request/)
          end
        end

        context "with aud as an array" do
          let(:aud) { [Rails.application.routes.url_helpers.oauth2_token_url(host: "test.host"), "doesnotexist"] }

          it { is_expected.to have_http_status :ok }
        end

        context "with a port in the aud" do
          let(:aud) { Rails.application.routes.url_helpers.oauth2_token_url(host: "test.host", port: 3000) }

          before { request.host = "test.host:3000" }

          it { is_expected.to have_http_status :ok }
        end

        context "with bad exp" do
          let(:exp) { 1.minute.ago.to_i }

          it { is_expected.to have_http_status :bad_request }
        end

        context "with iat in the future by a small amount" do
          let(:future_iat_time) { 5.seconds.from_now }
          let(:iat) { future_iat_time.to_i }

          it "returns an access token" do
            Timecop.freeze(future_iat_time - 5.seconds) do
              expect(subject).to have_http_status :ok
            end
          end
        end

        context "with bad iat" do
          let(:iat) { 1.minute.from_now.to_i }

          it { is_expected.to have_http_status :bad_request }

          context "with iat too far in future" do
            let(:iat) { 6.minutes.from_now.to_i }

            it { is_expected.to have_http_status :bad_request }
          end
        end

        context "with bad signing key" do
          let(:signing_key) { JSON::JWK.new(other_key.private_jwk) }

          before do
            other_key.generate_rsa_keypair! overwrite: true
            other_key.save!
          end

          it { is_expected.to have_http_status :bad_request }
        end

        context "with missing assertion" do
          Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS.each do |assertion|
            it "returns 400 when #{assertion} missing" do
              jwt.delete assertion.to_sym
              expected = (assertion == "sub") ? :unauthorized : :bad_request
              expect(subject).to have_http_status expected
            end
          end
        end

        context "with same token" do
          it "returns 200" do
            enable_cache do
              expect(subject).to have_http_status :ok
              Setting.set("oauth.allowed_timestamp_future_skew", 0.seconds)

              parameters = { grant_type: "client_credentials" }.merge(client_credentials_params)
              post :token, params: parameters
              expect(response).to have_http_status :ok
            end
          end
        end

        context "with symmetric client identification" do
          let(:client_credentials_params) do
            {
              client_id:,
              client_secret:,
              redirect_uri: "https://example.com",
              scope: TokenScopes::USER_INFO_SCOPE[:scope]
            }
          end

          it "rejects by default" do
            expect(subject).to have_http_status :bad_request
            expect(response.body).to match(/assertion method not supported for this grant_type/)
          end

          context "with external audience key" do
            before do
              key.client_credentials_audience = "external"
              key.save!
            end

            it { is_expected.to have_http_status :ok }
          end
        end
      end
    end
  end

  describe "POST accept" do
    let_once(:user) { User.create! }
    let_once(:key) { DeveloperKey.create! }
    let(:session_hash) { { oauth2: { client_id: key.id, redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI } } }
    let(:oauth_accept) { post :accept, session: session_hash }

    before { user_session user }

    it "uses the global id of the user for generating the code" do
      expect(Canvas::OAuth::Token).to receive(:generate_code_for).with(user.global_id, user.global_id, key.id, { scopes: nil, remember_access: nil, purpose: nil }).and_return("code")
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(code: "code"))
    end

    it "saves the requested scopes with the code" do
      scopes = "userinfo"
      session_hash[:oauth2][:scopes] = scopes
      expect(Canvas::OAuth::Token).to receive(:generate_code_for).with(user.global_id, user.global_id, key.id, { scopes:, remember_access: nil, purpose: nil }).and_return("code")
      oauth_accept
    end

    it "remembers the users access preference with the code" do
      expect(Canvas::OAuth::Token).to receive(:generate_code_for).with(user.global_id, user.global_id, key.id, { scopes: nil, remember_access: "1", purpose: nil }).and_return("code")
      post :accept, params: { remember_access: "1" }, session: session_hash
    end

    it "removes oauth session info after code generation" do
      allow(Canvas::OAuth::Token).to receive_messages(generate_code_for: "code")
      oauth_accept
      expect(controller.session[:oauth2]).to be_nil
    end

    it "forwards the oauth state if it was provided" do
      session_hash[:oauth2][:state] = "1234567890"
      allow(Canvas::OAuth::Token).to receive_messages(generate_code_for: "code")
      oauth_accept
      expect(response).to redirect_to(oauth2_auth_url(code: "code", state: "1234567890"))
    end

    it "gracefully errors if the session has been destroyed" do
      post :accept, session: {}
      expect(response.code.to_i).to eq(400)
    end
  end

  describe "GET deny" do
    let_once(:key) { DeveloperKey.create! }
    let(:session_hash) { { oauth2: { client_id: key.id, redirect_uri: Canvas::OAuth::Provider::OAUTH2_OOB_URI } } }

    it "forwards the oauth state if it was provided" do
      session_hash[:oauth2][:state] = "1234567890"
      get "deny", session: session_hash
      expect(response).to be_redirect
      expect(response.location).to match(/state=1234567890/)
    end

    it "does not provide state if there wasn't one provided" do
      get "deny", session: session_hash
      expect(response).to be_redirect
      expect(response.location).not_to match(/state=/)
    end

    it "doesn't error on an empty session" do
      get "deny", session: {}
      expect(response).to be_bad_request
    end
  end

  describe "DELETE token" do
    let_once(:key) do
      d = DeveloperKey.create! redirect_uri: "https://example.com"
      enable_developer_key_account_binding!(d)
      d
    end
    let_once(:user) { user_with_pseudonym(active_all: 1, password: "qwertyuiop") }
    let(:token) { user.access_tokens.create!(developer_key: key) }

    it "deletes the token" do
      delete :destroy, params: { access_token: token.full_token }
      expect(response.parsed_body).to eq({})
      expect(AccessToken.not_deleted.exists?(token.id)).to be(false)
    end

    it "doesn't need a scope to delete the token" do
      key.require_scopes = true
      key.save!
      delete :destroy, params: { access_token: token.full_token }
      expect(AccessToken.not_deleted.exists?(token.id)).to be(false)
    end

    context "with a web session" do
      let_once(:ap) { Account.default.canvas_authentication_provider }

      before do
        allow_any_instantiation_of(ap).to receive(:user_logout_redirect).and_return("somewhere")
      end

      let(:session) { { login_aac: ap.global_id } }

      it "includes forward URL when possible" do
        delete(:destroy, params: { access_token: token.full_token, expire_sessions: true }, session:)
        expect(response.parsed_body).to eq({ "forward_url" => "somewhere" })
      end

      it "does not include forward URL when not ending sessions" do
        delete(:destroy, params: { access_token: token.full_token }, session:)
        expect(response.parsed_body).to eq({})
      end
    end
  end
end
