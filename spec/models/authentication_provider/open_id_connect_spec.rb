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

require_relative "../../spec_helper"

describe AuthenticationProvider::OpenIDConnect do
  describe "#token_endpoint_auth_method" do
    it "defaults to client_secret_post" do
      expect(subject.token_endpoint_auth_method).to eq "client_secret_post"
    end

    it "sets the auth schema for client_secret_basic" do
      subject.token_endpoint_auth_method = "client_secret_basic"
      expect(subject.client.options[:auth_scheme]).to eq :basic_auth
    end

    it "sets the auth schema for client_secret_post" do
      subject.token_endpoint_auth_method = "client_secret_post"
      expect(subject.client.options[:auth_scheme]).to eq :request_body
      expect(subject.client.options[:token_method]).to eq :post
    end

    it "raises an error for an invalid auth method" do
      subject.token_endpoint_auth_method = "invalid"
      expect(subject).not_to be_valid
      expect(subject.errors).to have_key(:token_endpoint_auth_method)
    end
  end

  describe "#populate_from_discovery" do
    it "sets fields" do
      subject.populate_from_discovery(
        {
          "authorization_endpoint" => "http://auth/authorize",
          "token_endpoint" => "http://auth/token",
          "userinfo_endpoint" => "http://auth/userinfo",
          "end_session_endpoint" => "http://auth/logout"
        }
      )
      expect(subject.authorize_url).to eq "http://auth/authorize"
      expect(subject.token_url).to eq "http://auth/token"
      expect(subject.userinfo_endpoint).to eq "http://auth/userinfo"
      expect(subject.end_session_endpoint).to eq "http://auth/logout"
    end
  end

  describe "#scope_for_options" do
    it "automatically infers according to requested claims" do
      subject.federated_attributes = { "email" => { "attribute" => "email" } }
      subject.login_attribute = "preferred_username"
      expect(subject.send(:scope_for_options)).to eq "openid profile email"
    end
  end

  describe "#unique_id" do
    it "decodes jwt and extracts subject attribute" do
      payload = { sub: "some-login-attribute" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      uid = subject.unique_id(double(params: { "id_token" => id_token }, options: {}))
      expect(uid).to eq("some-login-attribute")
    end

    it "requests more attributes if necessary" do
      subject.userinfo_endpoint = "moar"
      subject.login_attribute = "not_in_id_token"
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = double(options: {}, params: { "id_token" => id_token })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "1" }))
      expect(subject.unique_id(token)).to eq "myid"
    end

    it "ignores userinfo that doesn't match" do
      subject.userinfo_endpoint = "moar"
      subject.login_attribute = "not_in_id_token"
      payload = { sub: "1" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      token = double(options: {}, params: { "id_token" => id_token })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "2" }))
      expect(subject.unique_id(token)).to be_nil
    end

    it "returns nil if the id_token is missing" do
      uid = subject.unique_id(instance_double(OAuth2::AccessToken, params: { "id_token" => nil }, token: nil, options: {}))
      expect(uid).to be_nil
    end

    it "validates the audience claim for subclasses" do
      subject = AuthenticationProvider::Microsoft.new(client_id: "abc", tenant: "microsoft", account: Account.default)
      payload = { sub: "some-login-attribute", aud: "someone_else", tid: AuthenticationProvider::Microsoft::MICROSOFT_TENANT }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      expect { subject.unique_id(double(params: { "id_token" => id_token }, options: {})) }.to raise_error(OAuthValidationError)
      subject.client_id = "someone_else"
      expect { subject.unique_id(double(params: { "id_token" => id_token }, options: {})) }.not_to raise_error
    end

    it "does not validate the audience claim for self" do
      subject.client_id = "abc"
      payload = { sub: "some-login-attribute", aud: "someone_else" }
      id_token = Canvas::Security.create_jwt(payload, nil, :unsigned)
      expect { subject.unique_id(double(params: { "id_token" => id_token }, options: {})) }.not_to raise_error
    end
  end

  describe "#user_logout_url" do
    let(:controller) { instance_double("ApplicationController", login_url: "http//www.example.com/login", session: {}) }

    before do
      subject.account = Account.default
      subject.end_session_endpoint = "http://somewhere/logout"
      subject.client_id = "abc"
    end

    context "with the feature flag on" do
      before do
        Account.default.enable_feature!(:oidc_rp_initiated_logout_params)
      end

      it "returns the end_session_endpoint" do
        expect(subject.user_logout_redirect(controller, nil)).to eql "http://somewhere/logout?client_id=abc&post_logout_redirect_uri=http%2F%2Fwww.example.com%2Flogin"
      end

      it "preserves other query parameters" do
        subject.end_session_endpoint = "http://somewhere/logout?foo=bar"
        expect(subject.user_logout_redirect(controller, nil)).to eql "http://somewhere/logout?client_id=abc&post_logout_redirect_uri=http%2F%2Fwww.example.com%2Flogin&foo=bar"
      end

      it "does not overwrite conflicting parameters" do
        subject.end_session_endpoint = "http://somewhere/logout?post_logout_redirect_uri=elsewhere"
        expect(subject.user_logout_redirect(controller, nil)).to eql "http://somewhere/logout?client_id=abc&post_logout_redirect_uri=elsewhere"
      end

      it "includes the full id_token" do
        id_token = Canvas::Security.create_jwt({ sub: "1" }, nil, :unsigned)
        session = { oidc_id_token: id_token }
        allow(controller).to receive(:session).and_return(session)
        expect(subject.user_logout_redirect(controller, nil)).to eql "http://somewhere/logout?client_id=abc&post_logout_redirect_uri=http%2F%2Fwww.example.com%2Flogin&id_token_hint=#{id_token}"
      end
    end

    it "doesn't add anything with the feature flag off" do
      expect(subject.user_logout_redirect(controller, nil)).to eql "http://somewhere/logout"
    end
  end
end
