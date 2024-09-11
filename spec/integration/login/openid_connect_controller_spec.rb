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
  let_once(:oidc_ap) do
    AuthenticationProvider::OpenIDConnect.create!(jit_provisioning: true,
                                                  account: Account.default,
                                                  authorize_url: "http://somewhere/oidc",
                                                  client_id: "audience")
  end
  let(:id_token) { Canvas::Security.create_jwt({ sub: "uid", iss: "issuer", aud: "audience", sid: "session" }, nil, :unsigned) }

  before do
    allow_any_instantiation_of(Account.default).to receive(:terms_required?).and_return(false)
  end

  describe "#create" do
    it "persists id token details in session" do
      get login_openid_connect_url, params: { auth_type: "openid_connect" }
      expect(response).to be_redirect
      uri = URI.parse(response.location)
      state_jwt = Rack::Utils.parse_nested_query(uri.query)["state"]
      uri.query = nil
      expect(uri.to_s).to eql oidc_ap.authorize_url

      token = instance_double(OAuth2::AccessToken, params: { "id_token" => id_token }, token: nil, options: {})
      allow_any_instantiation_of(oidc_ap).to receive(:get_token).and_return(token)
      get oauth2_login_callback_url, params: { code: "code", state: state_jwt }
      expect(response).to redirect_to dashboard_url(login_success: 1)
      expect(session[:oidc_id_token]).to eql id_token
    end
  end
end
