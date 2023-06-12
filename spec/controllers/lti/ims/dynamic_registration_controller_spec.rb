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

  describe "#create" do
    subject { get :create, params: { registration_url: "https://example.com" } }

    before do
      account_admin_user
      @admin.account.enable_feature! :lti_dynamic_registration
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
        expect(oidc_url).to eq("https://canvas.instructure.com/api/lti/ims/security/openid-configuration")
      end

      it "sets user id, root account id, and date in the JWT" do
        subject
        parsed_redirect_uri = Addressable::URI.parse(response.headers["Location"])
        jwt = parsed_redirect_uri.query_values["registration_token"]
        jwt_hash = Canvas::Security.decode_jwt(jwt)

        expect(Time.parse(jwt_hash["initiated_at"])).to be_within(1.minute).of(Time.now)
        expect(jwt_hash["user_id"]).to eq(@admin.id)
        expect(jwt_hash["root_account_uuid"]).to eq(@admin.account.root_account.uuid)
      end
    end
  end
end
