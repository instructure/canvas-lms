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
  subject do
    described_class.new(account: Account.default, issuer: "issuer", client_id: "client", client_secret: "secret")
  end

  let(:keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwk) { JSON::JWK.new(keypair.public_key) }

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
          "issuer" => "me",
          "authorization_endpoint" => "http://auth/authorize",
          "token_endpoint" => "http://auth/token",
          "userinfo_endpoint" => "http://auth/userinfo",
          "end_session_endpoint" => "http://auth/logout"
        }
      )
      expect(subject.issuer).to eq "me"
      expect(subject.authorize_url).to eq "http://auth/authorize"
      expect(subject.token_url).to eq "http://auth/token"
      expect(subject.userinfo_endpoint).to eq "http://auth/userinfo"
      expect(subject.end_session_endpoint).to eq "http://auth/logout"
    end
  end

  describe "#download_discovery" do
    it "works" do
      subject.discovery_url = "https://somewhere/.well-known/openid-configuration"
      response = instance_double(Net::HTTPOK, value: 200, body: { issuer: "me" }.to_json)
      expect(CanvasHttp).to receive(:get).and_yield(response)
      subject.valid?
      expect(subject.issuer).to eql "me"
      expect(subject.discovery_url).to eql "https://somewhere/.well-known/openid-configuration"
    end

    it "ignores a (newly) blank issuer" do
      subject.issuer_will_change!
      subject.issuer = nil
      expect(CanvasHttp).not_to receive(:get)
      subject.valid?
      expect(subject.issuer).to be_nil
      expect(subject.discovery_url).to be_nil
    end

    it "doesn't try to download if nothing changed" do
      subject.discovery_url = "https://somewhere/.well-known/openid-configuration"
      allow(subject).to receive_messages(discovery_url_changed?: false, issuer_changed?: false)
      expect(CanvasHttp).not_to receive(:get)
      subject.valid?
    end

    context "when an authentication provider is restored" do
      let(:discovery_url) { "https://somewhere/.well-known/openid-configuration" }

      before do
        allow(subject.class).to receive(:restorable?).and_return true

        subject.discovery_url = discovery_url
        subject.workflow_state = "deleted"
        subject.save(validate: false)
      end

      it "fetches the discovery document" do
        expect(CanvasHttp).to receive(:get).with(discovery_url).and_return(
          instance_double(Net::HTTPOK, value: 200, body: { issuer: "me" }.to_json)
        )

        subject.update!(workflow_state: "active")
      end
    end

    context "when a restorable authentication provider is deleted" do
      let(:discovery_url) { "https://somewhere/.well-known/openid-configuration" }

      before do
        allow(subject.class).to receive(:restorable?).and_return true

        subject.discovery_url = discovery_url
        subject.save(validate: false)
      end

      it "fetches the discovery document" do
        expect(CanvasHttp).not_to receive(:get)

        subject.destroy!
      end
    end

    it "infers the discovery URL from the issuer" do
      subject.issuer = "https://somewhere"
      response = instance_double(Net::HTTPOK, value: 200, body: { issuer: "me" }.to_json)
      expect(CanvasHttp).to receive(:get).with("https://somewhere/.well-known/openid-configuration").and_yield(response)
      subject.valid?
      expect(subject.issuer).to eql "me"
      expect(subject.discovery_url).to eql "https://somewhere/.well-known/openid-configuration"
    end

    it "infers the discovery URL from a multi-tenant issuer" do
      subject.issuer = "https://somewhere/multitenant/"
      response = instance_double(Net::HTTPOK, value: 200, body: { issuer: "me" }.to_json)
      expect(CanvasHttp).to receive(:get).with("https://somewhere/multitenant/.well-known/openid-configuration").and_yield(response)
      subject.valid?
      expect(subject.issuer).to eql "me"
      expect(subject.discovery_url).to eql "https://somewhere/multitenant/.well-known/openid-configuration"
    end

    it "does not infer a discovery URL when the provider doesn't support discovery" do
      subject.issuer = "https://somewhere"
      response = instance_double(Net::HTTPOK, value: 404, body: "NOT FOUND")
      expect(CanvasHttp).to receive(:get).with("https://somewhere/.well-known/openid-configuration").and_yield(response)
      subject.valid?
      expect(subject.issuer).to eql "https://somewhere"
      expect(subject.discovery_url).to be_nil
    end

    it "does not infer a discovery URL when it's invalid" do
      subject.issuer = "not_a_url"
      subject.valid?
      expect(subject.issuer).to eql "not_a_url"
      expect(subject.discovery_url).to be_nil
    end

    it "does not modify an explicit discovery URL with a non-matching issuer" do
      subject.issuer = "https://somewhere"
      subject.discovery_url = "https://somewhere/openid-configuration"
      response = instance_double(Net::HTTPOK, value: 200, body: { issuer: "me" }.to_json)
      expect(CanvasHttp).to receive(:get).with("https://somewhere/openid-configuration").and_yield(response)
      subject.valid?
      expect(subject.issuer).to eql "me"
      expect(subject.discovery_url).to eql "https://somewhere/openid-configuration"
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
    let(:nonce) { SecureRandom.hex(12) }

    def id_token(claims)
      claims = claims.reverse_merge(
        iss: subject.issuer,
        aud: subject.client_id,
        iat: Time.zone.now.to_i,
        exp: Time.zone.now.to_i + 5,
        nonce:
      )
      jwt = JSON::JWT.new(claims)
      jwt.sign(subject.client_secret).to_s
    end

    it "decodes jwt and extracts subject attribute" do
      uid = subject.unique_id(double(params: { "id_token" => id_token({ sub: "some-login-attribute" }) }, options: { nonce: }))
      expect(uid).to eq("some-login-attribute")
    end

    it "requests more attributes if necessary" do
      subject.userinfo_endpoint = "moar"
      subject.login_attribute = "not_in_id_token"
      token = double(options: { nonce: }, params: { "id_token" => id_token({ sub: "1" }) })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "1" }))
      expect(subject.unique_id(token)).to eq "myid"
    end

    it "does not request more attributes if unnecessary, even if userinfo_endpoint is present" do
      subject.userinfo_endpoint = "moar"
      subject.login_attribute = "in_id_token"
      token = double(options: { nonce: }, params: { "id_token" => id_token({ sub: "1", in_id_token: "myid" }) })
      expect(token).not_to receive(:get)
      expect(subject.unique_id(token)).to eq "myid"
    end

    it "ignores userinfo that doesn't match" do
      subject.userinfo_endpoint = "moar"
      subject.login_attribute = "not_in_id_token"
      token = double(options: { nonce: }, params: { "id_token" => id_token({ sub: "1" }) })
      expect(token).to receive(:get).with("moar").and_return(double(parsed: { "not_in_id_token" => "myid", "sub" => "2" }))
      expect(subject.unique_id(token)).to be_nil
    end

    it "returns nil if the id_token is missing" do
      expect do
        subject.unique_id(instance_double(OAuth2::AccessToken, params: { "id_token" => nil }, token: nil, options: { nonce: }))
      end.to raise_error(OAuthValidationError)
    end

    describe "token validation" do
      base_payload = {
        sub: "some-login-attribute",
        aud: "client",
        iat: Time.now.to_i,
        exp: Time.now.to_i + 30,
        iss: "issuer",
        nonce: "nonce"
      }.freeze

      it "passes a valid token" do
        id_token = Canvas::Security.create_jwt(base_payload, nil, subject.client_secret)
        expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.not_to raise_error
      end

      it "validates a multi-valued audience" do
        id_token = Canvas::Security.create_jwt(base_payload.merge(aud: ["def", "client"]), nil, subject.client_secret)
        expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.not_to raise_error
      end

      def self.bad_token_spec(description, payload)
        it "validates #{description}" do
          id_token = Canvas::Security.create_jwt(payload, nil, subject.client_secret)
          expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.to raise_error(OAuthValidationError)
        end
      end

      bad_token_spec("the audience claim for self", base_payload.merge(aud: "someone_else"))
      bad_token_spec("the issuer claim", base_payload.merge(iss: "someone_else"))
      bad_token_spec("exp is provided", base_payload.except(:exp))
      bad_token_spec("exp is valid", base_payload.merge(exp: 10))
      bad_token_spec("nonce is provided", base_payload.except(:nonce))
      bad_token_spec("nonce is valid", base_payload.merge(nonce: "wrong"))

      it "validates the signature" do
        id_token = Canvas::Security.create_jwt(base_payload, nil, "wrong_key")
        expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.to raise_error(OAuthValidationError)
      end

      it "refreshes the keys if the kid is not found. once" do
        id_token = Canvas::Security.create_jwt(base_payload, nil, subject.client_secret)
        tries = 1
        parsed_token = Canvas::Security.decode_jwt(id_token, [:skip_verification])
        allow(parsed_token).to receive(:verify!) do
          tries += 1
          raise JSON::JWK::Set::KidNotFound if tries == 2

          true
        end
        allow(Canvas::Security).to receive(:decode_jwt).and_return(parsed_token)
        expect(subject).to receive(:download_jwks).with(force: true)
        expect(subject).to receive(:save!)
        expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.not_to raise_error
      end

      it "fails if the key is still wrong" do
        id_token = Canvas::Security.create_jwt(base_payload, nil, subject.client_secret)
        parsed_token = Canvas::Security.decode_jwt(id_token, [:skip_verification])
        allow(parsed_token).to receive(:verify!).and_raise(JSON::JWK::Set::KidNotFound)
        allow(Canvas::Security).to receive(:decode_jwt).and_return(parsed_token)
        expect(subject).to receive(:download_jwks).with(force: true)
        expect(subject).not_to receive(:save!)
        expect { subject.unique_id(double(params: { "id_token" => id_token }, options: { nonce: "nonce" })) }.to raise_error(OAuthValidationError)
      end
    end
  end

  describe "#user_logout_url" do
    let(:controller) { instance_double(ApplicationController, login_url: "http//www.example.com/login", session: {}) }

    before do
      subject.account = Account.default
      subject.end_session_endpoint = "http://somewhere/logout"
      subject.client_id = "abc"
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

  describe "#jwks" do
    it "downloads the jwks if jwks_uri is set" do
      subject.jwks_uri = "http://jwks"
      jwks = [jwk].to_json
      expect(CanvasHttp).to receive(:get).with("http://jwks").and_return(instance_double(Net::HTTPOK, body: jwks))
      expect(subject.settings["jwks"]).to be_nil
      expect(subject.jwks[jwk[:kid]]).to eq jwk.as_json
      expect(subject.settings["jwks"]).to eq jwks
    end

    it "does nothing if jwks_uri is not set" do
      expect(subject).not_to receive(:download_jwks)
      expect(subject.jwks).to be_nil
    end
  end

  describe "#jwks=" do
    it "validates the JWKS is well formed" do
      expect { subject.jwks = "abc" }.to raise_error(JSON::ParserError)
      expect { subject.jwks = [jwk].to_json }.not_to raise_error
    end
  end

  describe "#download_jwks" do
    it "clears the jwks if jwks_uri is no longer set" do
      subject.jwks = [jwk].to_json
      subject.send(:download_jwks)
      expect(subject.jwks).to be_nil
    end

    it "skips the update if nothing changed" do
      subject.jwks_uri = "http://jwks"
      subject.jwks = [jwk].to_json

      expect(CanvasHttp).not_to receive(:get)

      subject.save!(validate: false)
      expect(subject.jwks).not_to be_nil

      subject.save!
      expect(subject.jwks).not_to be_nil
    end

    it "updates if the jwks_uri changed" do
      subject.jwks_uri = "http://jwks"
      subject.jwks = [jwk].to_json
      subject.save!(validate: false)

      keypair2 = OpenSSL::PKey::RSA.new(2048)
      jwk2 = JSON::JWK.new(keypair2.public_key)

      expect(CanvasHttp).to receive(:get).with("http://new").and_return(instance_double(Net::HTTPOK, body: [jwk2].to_json))

      subject.jwks_uri = "http://new"
      subject.save!
      expect(subject.jwks[jwk2[:kid]]).to eq jwk2.as_json
    end

    it "updates if nothing changed, but was forced" do
      subject.issuer = nil
      subject.jwks_uri = "http://jwks"
      subject.jwks = [jwk].to_json

      keypair2 = OpenSSL::PKey::RSA.new(2048)
      jwk2 = JSON::JWK.new(keypair2.public_key)

      allow(CanvasHttp).to receive(:get).with("http://jwks").and_return(instance_double(Net::HTTPOK, body: [jwk2].to_json))

      subject.save!
      expect(subject.jwks[jwk2[:kid]]).to eq jwk2.as_json

      subject.settings["jwks"] = { keys: [] }.to_json
      expect(subject.jwks).to be_empty
      subject.send(:download_jwks, force: true)
      expect(subject.jwks[jwk2[:kid]]).to eq jwk2.as_json
    end
  end
end
