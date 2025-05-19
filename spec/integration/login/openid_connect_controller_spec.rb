# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Login::OpenidConnectController do
  keypair = OpenSSL::PKey::RSA.new(2048).freeze
  jwk = JSON::JWK.new(keypair.public_key).freeze
  let(:keypair) { keypair }
  let(:jwk) { jwk }
  let!(:oidc_ap) do
    ap = AuthenticationProvider::OpenIDConnect.new(jit_provisioning: true,
                                                   account: Account.default,
                                                   authorize_url: "http://somewhere/oidc",
                                                   issuer: "issuer",
                                                   client_id: "audience",
                                                   client_secret: "secret",
                                                   jwks_uri: "http://somewhere/jwks",
                                                   jwks: [jwk].to_json)
    allow(ap).to receive(:download_jwks)
    ap.save!
    ap
  end
  let(:sid_id_token) { JSON::JWT.new({ sub: "uid", iss: "issuer", aud: "audience", sid: "session" }) }
  let(:sub_id_token) { JSON::JWT.new({ sub: "uid", iss: "issuer", aud: "audience" }) }

  before do
    allow_any_instantiation_of(Account.default).to receive(:terms_required?).and_return(false)
  end

  def do_login(id_token = sid_id_token, include_sid: true, final_redirect: nil)
    get login_openid_connect_url
    expect(response).to be_redirect
    uri = URI.parse(response.location)
    state_jwt = Rack::Utils.parse_nested_query(uri.query)["state"]
    uri.query = nil
    expect(uri.to_s).to eql oidc_ap.authorize_url
    state_jwt_decoded = JSON::JWT.decode(state_jwt, :skip_verification)
    id_token["iat"] = Time.zone.now.to_i
    id_token["exp"] = Time.zone.now.to_i + 5
    id_token["nonce"] = state_jwt_decoded["nonce"]
    id_token = id_token.sign(oidc_ap.client_secret).to_s

    id_token = id_token.to_s
    token = instance_double(OAuth2::AccessToken, params: { "id_token" => id_token }, token: nil, options: {})
    allow_any_instantiation_of(oidc_ap).to receive(:get_token).and_return(token)
    get oauth2_login_callback_url, params: { code: "code", state: state_jwt }

    expect(response).to redirect_to(final_redirect || dashboard_url(login_success: 1))
    expect(session[:oidc_id_token]).to eql id_token
    expect(session[:oidc_id_token_iss]).to eql "issuer"
    if include_sid
      expect(session[:oidc_id_token_sid]).to eql "session"
    end
    expect(session[:oidc_id_token_sub]).to eql "uid"
  end

  describe "#new" do
    it "forwards token_hint param" do
      get login_openid_connect_url, params: { login_hint: "cody" }
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      login_hint = Rack::Utils.parse_nested_query(uri.query)["login_hint"]
      expect(login_hint).to eql "cody"
    end

    it "can be POSTed to" do
      post login_openid_connect_url, params: { login_hint: "cody" }
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      login_hint = Rack::Utils.parse_nested_query(uri.query)["login_hint"]
      expect(login_hint).to eql "cody"
    end

    it "accepts target_link_uri" do
      get login_openid_connect_url, params: { target_link_uri: "/courses" }
      expect(response).to be_redirect
      expect(session[:return_to]).to eql "/courses"
    end

    it "ignores untrusted target_link_uris" do
      get login_openid_connect_url, params: { target_link_uri: "http://google.com" }
      expect(response).to be_redirect
      expect(session[:return_to]).to be_nil
    end

    it "can lookup the auth provider by iss" do
      ap = AuthenticationProvider::OpenIDConnect.new(jit_provisioning: true,
                                                     account: Account.default,
                                                     authorize_url: "http://secondprovider/oidc",
                                                     issuer: "https://secondprovider",
                                                     client_id: "audience",
                                                     client_secret: "secret",
                                                     jwks_uri: "http://somewhere/jwks",
                                                     jwks: [jwk].to_json)
      allow(ap).to receive(:download_jwks)
      ap.save!
      get login_openid_connect_url, params: { iss: "https://secondprovider" }
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      expect(uri.host).to eql "secondprovider"
    end

    it "forwards force_login param" do
      get login_openid_connect_url, params: { force_login: "1" }
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      prompt = Rack::Utils.parse_nested_query(uri.query)["prompt"]
      expect(prompt).to eql "login"
    end

    it "sets prompt if just_logged_out is set" do
      allow_any_instance_of(Login::OpenidConnectController).to receive(:session).and_return({ just_logged_out: Time.now.utc })
      get login_openid_connect_url
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      prompt = Rack::Utils.parse_nested_query(uri.query)["prompt"]
      expect(prompt).to eql "login"
    end

    it "does not set prompt otherwise" do
      get login_openid_connect_url
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      query = Rack::Utils.parse_nested_query(uri.query)
      expect(query).not_to have_key("prompt")
    end
  end

  describe "#create" do
    it "persists id token details in session" do
      do_login
    end

    it "redirects to a specified URI" do
      id_token = sid_id_token
      id_token[AuthenticationProvider::OpenIDConnect::POST_LOGIN_REDIRECT_CLAIM] = "/courses"
      do_login(id_token, final_redirect: courses_url)
    end
  end

  describe "#destroy" do
    logout_token_base = {
      iss: "issuer",
      aud: "audience",
      jti: 1,
      events: { Login::OpenidConnectController::OIDC_BACKCHANNEL_LOGOUT_EVENT_URN => {} },
      sub: "uid",
      sid: "session",
      iat: Time.now.to_i,
      exp: 10.minutes.from_now.to_i
    }.freeze

    before do
      skip unless Canvas.redis_enabled?
    end

    it "destroys a valid session when called with sub+sid" do
      do_login

      # session is good
      get dashboard_url
      expect(response).to be_successful

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.dup)
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response).to be_successful

      # session is bad
      get dashboard_url
      expect(response).to redirect_to login_url
    end

    it "destroys a valid session when called with just sub" do
      do_login

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.except(:sid))
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response).to be_successful

      # session is bad
      get dashboard_url
      expect(response).to redirect_to login_url
    end

    it "destroys a valid session when it only ever had sub" do
      do_login(sub_id_token, include_sid: false)

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.except(:sid))
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response).to be_successful

      # session is bad
      get dashboard_url
      expect(response).to redirect_to login_url
    end

    it "destroys a valid session when called with just sid" do
      do_login

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.except(:sub))
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response).to be_successful

      # session is bad
      get dashboard_url
      expect(response).to redirect_to login_url
    end

    def self.bad_token_spec(description, logout_token, message, status: 400)
      it "doesn't destroy the session when #{description}" do
        do_login

        back_channel = open_session
        if logout_token.is_a?(Hash)
          logout_token = JSON::JWT.new(logout_token)
          logout_token.kid = jwk[:kid]
          logout_token = logout_token.sign(keypair).to_s
        end
        back_channel.post openid_connect_logout_url, params: { logout_token: }
        expect(back_channel.response.status).to be status
        expect(back_channel.response.body).to eql message

        # session is still good
        get dashboard_url
        expect(response).to be_successful
      end
    end

    bad_token_spec "the logout token is missing",
                   nil,
                   "Invalid logout token"
    bad_token_spec "the logout token is invalid",
                   "invalid",
                   "Invalid logout token"
    bad_token_spec "the iat is missing",
                   logout_token_base.except(:iat),
                   "Missing claim iat"
    bad_token_spec "the exp is missing",
                   logout_token_base.except(:exp),
                   "Missing claim exp"
    bad_token_spec "the audience is missing",
                   logout_token_base.except(:aud),
                   "Missing claim aud"
    bad_token_spec "the audience is wrong",
                   logout_token_base.merge(aud: "someone else"),
                   "Invalid audience/issuer pair",
                   status: 404
    bad_token_spec "the issuer is missing",
                   logout_token_base.except(:iss),
                   "Missing claim iss"
    bad_token_spec "the issuer is wrong",
                   logout_token_base.merge(iss: "someone else"),
                   "Invalid audience/issuer pair",
                   status: 404
    bad_token_spec "the events are missing",
                   logout_token_base.except(:events),
                   "Missing claim events"
    bad_token_spec "the events are the wrong data type",
                   logout_token_base.merge(events: 1),
                   "Invalid events"
    bad_token_spec "the correct event is the wrong data type",
                   logout_token_base.merge(events: { Login::OpenidConnectController::OIDC_BACKCHANNEL_LOGOUT_EVENT_URN => 1 }),
                   "Invalid events"
    bad_token_spec "the wrong event is sent",
                   logout_token_base.merge(events: { "somethingelse" => {} }),
                   "Invalid events"
    bad_token_spec "neither sub or sid are sent",
                   logout_token_base.except(:sub, :sid),
                   "Missing session information"
    bad_token_spec "the jti is missing",
                   logout_token_base.except(:jti),
                   "Missing claim jti"
    bad_token_spec "a nonce is sent",
                   logout_token_base.merge(nonce: "nonce"),
                   "Nonce must not be provided"
    bad_token_spec "the wrong information is sent",
                   logout_token_base.merge(sub: "someone else", sid: "someone else"),
                   "OK",
                   status: 200
    bad_token_spec "the logout_token is unsigned",
                   JSON::JWT.new(logout_token_base.dup).to_s,
                   "Invalid signature: Token is not signed"
    bad_token_spec "the logout_token is signed with a different key",
                   JSON::JWT.new(logout_token_base.dup).tap { |jwt| jwt.kid = jwk[:kid] }.sign(OpenSSL::PKey::RSA.new(2048)).to_s,
                   "Invalid signature: JSON::JWS::VerificationFailed"

    it "doesn't destroy the session when the jti is duplicated" do
      do_login

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.merge(sub: "someone else", sid: "someone else"))
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response).to be_successful

      logout_token = JSON::JWT.new(logout_token_base.dup)
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response.status).to be 400
      expect(back_channel.response.body).to eql "Received duplicate logout token"

      # session is still good
      get dashboard_url
      expect(response).to be_successful
    end

    it "doesn't destroy the session when the provider doesn't have a JWKS" do
      oidc_ap.update!(jwks: nil)
      do_login

      back_channel = open_session
      logout_token = JSON::JWT.new(logout_token_base.merge(sub: "someone else", sid: "someone else"))
      logout_token.kid = jwk[:kid]
      back_channel.post openid_connect_logout_url, params: { logout_token: logout_token.sign(keypair).to_s }
      expect(back_channel.response.status).to be 400
      expect(back_channel.response.body).to eql "Invalid signature: No JWKS available to validate signature"

      # session is still good
      get dashboard_url
      expect(response).to be_successful
    end
  end
end
