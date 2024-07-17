# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require "yaml"
require_relative "openapi/openapi_spec_helper"

describe Lti::IMS::DynamicRegistrationController do
  let(:controller_routes) do
    dynamic_registration_routes = []
    CanvasRails::Application.routes.routes.each do |route|
      dynamic_registration_routes << route if route.defaults[:controller] == "lti/ims/dynamic_registration" && route.defaults[:action] != "dr_iframe"
    end

    dynamic_registration_routes
  end

  openapi_location = File.join(File.dirname(__FILE__), "openapi", "dynamic_registration.yml")
  openapi_spec = YAML.load_file(openapi_location)

  verifier = OpenApiSpecHelper::SchemaVerifier.new(openapi_spec)

  before do
    Account.default.root_account.enable_feature! :lti_dynamic_registration
  end

  after do
    verifier.verify(request, response) if response.sent?
  end

  it "has openapi documentation for each of our controller routes" do
    controller_routes.each do |route|
      route_path = route.path.spec.to_s.gsub("(.:format)", "")
      if openapi_spec.dig("paths", route_path, route.verb.downcase).nil?
        throw "No openapi documentation for #{route_path} #{route.verb.downcase}, please add it to #{openapi_location}"
      end
      expect(openapi_spec["paths"][route_path][route.verb.downcase]).not_to be_nil
    end
  end

  describe "#create" do
    let(:scopes) do
      [
        "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly",
        "https://purl.imsglobal.org/spec/lti-ags/scope/score"
      ]
    end

    let(:registration_params) do
      {
        "application_type" => "web",
        "grant_types" => ["client_credentials", "implicit"],
        "response_types" => ["id_token"],
        "redirect_uris" => ["https://example.com/launch"],
        "initiate_login_uri" => "https://example.com/login",
        "client_name" => "the client name",
        "jwks_uri" => "https://example.com/api/jwks",
        "token_endpoint_auth_method" => "private_key_jwt",
        "scope" => scopes.join(" "),
        "logo_uri" => "https://example.com/logo.jpg",
        "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
          "domain" => "example.com",
          "messages" => [{
            "type" => "LtiResourceLinkRequest",
            "label" => "deep link label",
            "placements" => ["course_navigation"],
            "target_link_uri" => "https://example.com/launch",
            "custom_parameters" => {
              "foo" => "bar"
            },
            "roles" => [
              "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
              "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"
            ],
            "icon_uri" => "https://example.com/icon.jpg"
          }],
          "custom_parameters" => {
            "global_foo" => "global_bar"
          },
          "claims" => ["iss", "sub"],
          "target_link_uri" => "https://example.com/launch",
          "https://canvas.instructure.com/lti/privacy_level" => "email_only",
        },
      }
    end

    context "with a valid token" do
      let(:token_hash) do
        {
          user_id: User.create!.id,
          initiated_at: 1.minute.ago,
          root_account_global_id: Account.default.global_id,
          uuid: SecureRandom.uuid,
          unified_tool_id: "asdf"
        }
      end
      let(:valid_token) do
        Canvas::Security.create_jwt(token_hash, 1.hour.from_now)
      end

      context "and with valid registration params" do
        subject do
          request.headers["Authorization"] = "Bearer #{valid_token}"
          post :create, params: { **registration_params }
        end

        it "accepts valid params and creates a registration model" do
          subject
          parsed_body = response.parsed_body
          expected_response_keys = {
            "application_type" => registration_params["application_type"],
            "grant_types" => registration_params["grant_types"],
            "initiate_login_uri" => registration_params["initiate_login_uri"],
            "redirect_uris" => registration_params["redirect_uris"],
            "logo_uri" => registration_params["logo_uri"],
            "response_types" => registration_params["response_types"],
            "client_name" => registration_params["client_name"],
            "jwks_uri" => registration_params["jwks_uri"],
            "token_endpoint_auth_method" => registration_params["token_endpoint_auth_method"],
            "scope" => registration_params["scope"],
          }

          expect(parsed_body).to include(expected_response_keys)
          expect(parsed_body["client_id"]).to eq DeveloperKey.last.global_id.to_s
          created_registration = Lti::IMS::Registration.last
          expect(created_registration.privacy_level).to eq("email_only")
          expect(created_registration).not_to be_nil
          expect(parsed_body["https://purl.imsglobal.org/spec/lti-tool-configuration"]["https://canvas.instructure.com/lti/registration_config_url"]).to eq "http://test.host/api/lti/registrations/#{created_registration.global_id}/view"
          expect(created_registration.canvas_configuration["custom_fields"]).to eq({ "global_foo" => "global_bar" })
          expect(created_registration.unified_tool_id).to eq("asdf")
        end

        it "fills in values on the developer key" do
          subject
          dk = DeveloperKey.last
          expect(dk.name).to eq(registration_params["client_name"])
          expect(dk.scopes).to eq(scopes)
          expect(dk.account.global_id).to eq(token_hash[:root_account_global_id])
          expect(dk.redirect_uris).to eq(registration_params["redirect_uris"])
          expect(dk.public_jwk_url).to eq(registration_params["jwks_uri"])
          expect(dk.is_lti_key).to be(true)
          expect(dk.icon_url).to eq("https://example.com/logo.jpg")
          expect(dk.oidc_initiation_url).to eq(registration_params["initiate_login_uri"])
        end
      end

      context "and with invalid registration params" do
        subject do
          request.headers["Authorization"] = "Bearer #{valid_token}"
          post :create, params: invalid_registration_params
        end

        context "with invalid grant types" do
          let(:invalid_registration_params) do
            wrong_grant_types = registration_params
            wrong_grant_types["grant_types"] = ["not_part_of_the_spec", "implicit"]
            wrong_grant_types
          end

          it "returns a 422 with validation errors" do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("Must include client_credentials, implicit")
          end

          it "doesn't create a stray developer key" do
            expect { subject }.not_to change { DeveloperKey.count }
          end
        end

        context "with invalid response types" do
          let(:invalid_registration_params) do
            wrong_response_types = registration_params
            wrong_response_types["response_types"] = ["not_part_of_the_spec"]
            wrong_response_types
          end

          it "returns a 422 with validation errors" do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("Must include id_token")
          end

          it "doesn't create a stray developer key" do
            expect { subject }.not_to change { DeveloperKey.count }
          end
        end

        context "with invalid token endpoint auth method" do
          let(:invalid_registration_params) do
            wrong_token_endpoint_auth_method = registration_params
            wrong_token_endpoint_auth_method["token_endpoint_auth_method"] = "not_part_of_the_spec"
            wrong_token_endpoint_auth_method
          end

          it "returns a 422 with validation errors" do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("Must be 'private_key_jwt'")
          end

          it "doesn't create a stray developer key" do
            expect { subject }.not_to change { DeveloperKey.count }
          end
        end
      end
    end

    context "with an invalid token" do
      subject do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        post :create, params: registration_params
      end

      context "that has no uuid" do
        let(:invalid_token) do
          initiation_time = 1.minute.ago
          token_hash = {
            user_id: User.create!.id,
            initiated_at: initiation_time,
            root_account_global_id: Account.first.root_account_id,
          }
          Canvas::Security.create_jwt(token_hash, initiation_time)
        end

        it "returns a 401" do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "from more than an hour ago" do
        let(:invalid_token) do
          initiation_time = 62.minutes.ago # this should be too long ago to be accepted
          token_hash = {
            user_id: User.create!.id,
            initiated_at: initiation_time,
            root_account_global_id: Account.first.root_account_id,
            uuid: SecureRandom.uuid,
          }
          Canvas::Security.create_jwt(token_hash, initiation_time)
        end

        it "returns a 401" do
          subject
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "#registration_token" do
    subject do
      get :registration_token, params: { account_id: Account.default.id }
    end

    let(:token) { JSON::JWT.decode(response.parsed_body["token"], :skip_verification) }

    before do
      account_admin_user(account: Account.default)
      user_session(@admin)
    end

    it "returns a 200" do
      subject
      expect(response).to have_http_status(:ok)
    end

    it "uses iss domain in config url" do
      subject
      expect(response.parsed_body["oidc_configuration_url"]).to include(Canvas::Security.config["lti_iss"])
    end

    it "does not include unified_tool_id in token" do
      subject
      expect(token[:unified_tool_id]).to be_nil
    end

    context "with unified_tool_id parameter" do
      subject { get :registration_token, params: { account_id: Account.default.id, unified_tool_id: } }

      let(:unified_tool_id) { "asdf" }

      it "includes unified_tool_id in token" do
        subject
        expect(token[:unified_tool_id]).to eq(unified_tool_id)
      end

      context "is empty string" do
        let(:unified_tool_id) { "" }

        it "includes nil in token" do
          subject
          expect(token[:unified_tool_id]).to be_nil
        end
      end
    end

    context "in local dev" do
      before do
        allow(Rails.env).to receive(:development?).and_return true
      end

      it "uses local domain instead of iss" do
        subject
        expect(response.parsed_body["oidc_configuration_url"]).to include("localhost")
      end

      context "when request scheme is http" do
        before do
          allow_any_instance_of(ActionController::TestRequest).to receive(:scheme).and_return("http")
        end

        it "uses http for config url" do
          subject
          expect(response.parsed_body["oidc_configuration_url"]).to include("http://")
        end
      end

      context "when request scheme is https" do
        before do
          allow_any_instance_of(ActionController::TestRequest).to receive(:scheme).and_return("https")
        end

        it "uses https for config url" do
          subject
          expect(response.parsed_body["oidc_configuration_url"]).to include("https://")
        end
      end
    end
  end

  describe "#dr_iframe" do
    before do
      account_admin_user(account: Account.default)
      Account.default.root_account.enable_feature! :javascript_csp
      Account.default.root_account.enable_csp!
      user_session(@admin)
    end

    it "must include the url parameter" do
      get :dr_iframe, params: { account_id: Account.default.id }
      expect(response).to be_bad_request
    end

    it "returns unauthorized if jwt is expired" do
      expired_jwt = Canvas::Security.create_jwt({
                                                  user_id: @admin.id,
                                                  root_account_global_id: Account.default.id
                                                },
                                                5.minutes.ago)
      get :dr_iframe, params: { account_id: Account.default.id, url: "http://testexample.com?registration_token=#{expired_jwt}" }
      expect(response).to be_unauthorized
    end

    it "returns unauthorized if jwt is issued for other account" do
      expired_jwt = Canvas::Security.create_jwt({
                                                  user_id: @admin.id,
                                                  root_account_global_id: 123
                                                },
                                                5.minutes.from_now)
      get :dr_iframe, params: { account_id: Account.default.id, url: "http://testexample.com?registration_token=#{expired_jwt}" }
      expect(response).to be_unauthorized
      expect(response.headers["Content-Security-Policy"]).not_to include("testexample.com")
    end

    it "returns unauthorized if jwt is issued for other user" do
      expired_jwt = Canvas::Security.create_jwt({
                                                  user_id: 123,
                                                  root_account_global_id: Account.default.id
                                                },
                                                5.minutes.from_now)
      get :dr_iframe, params: { account_id: Account.default.id, url: "http://testexample.com?registration_token=#{expired_jwt}" }
      expect(response).to be_unauthorized
      expect(response.headers["Content-Security-Policy"]).not_to include("testexample.com")
    end

    it "adds url to CSP whitelist if registration_token is valid" do
      valid_jwt = Canvas::Security.create_jwt({
                                                user_id: @admin.id,
                                                root_account_global_id: Account.default.global_id
                                              },
                                              5.minutes.from_now)
      get :dr_iframe, params: { account_id: Account.default.id, url: "http://testexample.com?registration_token=#{valid_jwt}" }
      expect(response).to be_successful
      expect(response.headers["Content-Security-Policy"]).to include("testexample.com")
    end
  end
end
