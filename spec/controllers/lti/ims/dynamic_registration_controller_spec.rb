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

describe Lti::IMS::DynamicRegistrationController do
  before do
    Account.default.root_account.enable_feature! :lti_dynamic_registration
  end

  let(:controller_routes) do
    dynamic_registration_routes = []
    CanvasRails::Application.routes.routes.each do |route|
      dynamic_registration_routes << route if route.defaults[:controller] == "lti/ims/dynamic_registration"
    end

    dynamic_registration_routes
  end

  let(:openapi_spec) do
    openapi_location = File.join(File.dirname(__FILE__), "openapi", "dynamic_registration.yml")
    YAML.load_file(openapi_location)
  end

  it "has openapi documentation for each of our controller routes" do
    controller_routes.each do |route|
      route_path = route.path.spec.to_s.gsub("(.:format)", "")
      expect(openapi_spec["paths"][route_path][route.verb.downcase]).not_to be_nil
    end
  end

  describe "#redirect_to_tool_registration" do
    subject { get :redirect_to_tool_registration, params: { registration_url: "https://example.com" } }

    before do
      account_admin_user
      user_session(@admin)
    end

    context "with the lti_dynamic_registration flag disabled" do
      it "returns a 404" do
        @admin.account.disable_feature! :lti_dynamic_registration
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a valid registration url" do
      it "redirects to the registration_url" do
        subject
        parsed_redirect_uri = Addressable::URI.parse(response.headers["Location"])
        expect(parsed_redirect_uri.omit(:query).to_s).to eq("https://example.com")
        expect(response).to have_http_status(:found)
      end

      it "gives the oidc url in the response" do
        subject
        parsed_redirect_uri = Addressable::URI.parse(response.headers["Location"])
        oidc_url = parsed_redirect_uri.query_values["openid_configuration"]
        expect(oidc_url).to eq("https://canvas.instructure.com/api/lti/security/openid-configuration")
      end

      it "supports multiple subdomains in the oidc url" do
        @request.host = "sub.test.host"
        allow(Canvas::Security).to receive(:config).and_return({ "lti_iss" => "https://sub.test.host" })
        subject
        parsed_redirect_uri = Addressable::URI.parse(response.headers["Location"])
        oidc_url = parsed_redirect_uri.query_values["openid_configuration"]
        expect(oidc_url).to eq("https://sub.test.host/api/lti/security/openid-configuration")
      end

      it "sets user id, root account id, and date in the JWT" do
        subject
        parsed_redirect_uri = Addressable::URI.parse(response.headers["Location"])
        jwt = parsed_redirect_uri.query_values["registration_token"]
        jwt_hash = Canvas::Security.decode_jwt(jwt)

        expect(Time.parse(jwt_hash["initiated_at"])).to be_within(1.minute).of(Time.now)
        expect(jwt_hash["user_id"]).to eq(@admin.id)
        expect(jwt_hash["root_account_global_id"]).to eq(@admin.account.root_account.global_id)
      end
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
          "claims" => ["iss", "sub"],
          "target_link_uri" => "https://example.com/launch",
        },
      }
    end

    context "with a valid token" do
      let(:token_hash) do
        {
          user_id: User.create!.id,
          initiated_at: 1.minute.ago,
          root_account_global_id: Account.first.root_account_id,
        }
      end
      let(:valid_token) do
        Canvas::Security.create_jwt(token_hash, 1.hour.from_now)
      end

      context "and with valid registration params" do
        subject { post :create, params: { registration_token: valid_token, **registration_params } }

        it "accepts valid params and creates a registration model" do
          subject
          parsed_body = response.parsed_body
          expected_response_keys = {
            "application_type" => registration_params["application_type"],
            "grant_types" => registration_params["grant_types"],
            "initiate_login_uri" => registration_params["initiate_login_uri"],
            "redirect_uris" => registration_params["redirect_uris"],
            "response_types" => registration_params["response_types"],
            "client_name" => registration_params["client_name"],
            "jwks_uri" => registration_params["jwks_uri"],
            "token_endpoint_auth_method" => registration_params["token_endpoint_auth_method"],
            "scope" => registration_params["scope"],
          }

          expect(parsed_body).to include(expected_response_keys)
          expect(parsed_body["client_id"]).to eq DeveloperKey.last.global_id.to_s
          created_registration = Lti::IMS::Registration.last
          expect(created_registration).not_to be_nil
        end

        it "fills in values on the developer key" do
          subject
          dk = DeveloperKey.last
          expect(dk.name).to eq(registration_params["client_name"])
          expect(dk.scopes).to eq(scopes)
          expect(dk.account.id).to eq(token_hash[:root_account_global_id])
          expect(dk.redirect_uris).to eq(registration_params["redirect_uris"])
          expect(dk.public_jwk_url).to eq(registration_params["jwks_uri"])
          expect(dk.is_lti_key).to be(true)
          expect(dk.oidc_initiation_url).to eq(registration_params["initiate_login_uri"])
        end
      end

      context "and with invalid registration params" do
        subject { post :create, params: { registration_token: valid_token, **invalid_registration_params } }

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
          previous_key_count = DeveloperKey.count
          subject
          expect(DeveloperKey.count).to eq(previous_key_count)
        end
      end
    end

    context "with an invalid token" do
      subject { post :create, params: { registration_token: invalid_token, **registration_params } }

      context "from more than an hour ago" do
        let(:invalid_token) do
          initiation_time = 62.minutes.ago # this should be too long ago to be accepted
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
    end
  end
end
