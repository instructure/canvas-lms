# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe DiscoveryPagesApiController do
  let_once(:account) { Account.default }

  describe "PUT 'upsert'" do
    let!(:auth_provider) { account.authentication_providers.create!(auth_type: "saml") }
    let!(:secondary_auth_provider) { account.authentication_providers.create!(auth_type: "cas") }

    let(:valid_discovery_page) do
      {
        primary: [
          { authentication_provider_id: auth_provider.id, label: "Test Provider" }
        ],
        secondary: [
          { authentication_provider_id: secondary_auth_provider.id, label: "Other Provider", icon_url: "https://example.com/icon.png" }
        ]
      }
    end

    context "when not logged in" do
      it "redirects to login" do
        put :upsert, params: { discovery_page: valid_discovery_page }
        expect(response).to redirect_to(login_url)
      end
    end

    context "when logged in without manage_account_settings permission" do
      before do
        user_factory(active_all: true)
        user_session(@user)
      end

      it "returns unauthorized" do
        put :upsert, params: { discovery_page: valid_discovery_page }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged in with manage_account_settings permission" do
      before do
        account_admin_user(account:, active_all: true)
        user_session(@admin)
      end

      it "stores discovery_page settings successfully" do
        put :upsert, params: { discovery_page: valid_discovery_page }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["discovery_page"]["primary"].length).to eq(1)
        expect(json["discovery_page"]["primary"][0]["authentication_provider_id"]).to eq(auth_provider.id.to_s)
        expect(json["discovery_page"]["primary"][0]["label"]).to eq("Test Provider")
        expect(json["discovery_page"]["secondary"].length).to eq(1)
        expect(json["discovery_page"]["secondary"][0]["icon_url"]).to eq("https://example.com/icon.png")
      end

      it "persists settings to the domain root account" do
        put :upsert, params: { discovery_page: valid_discovery_page }

        account.reload
        expect(account.settings[:discovery_page][:primary].length).to eq(1)
        expect(account.settings[:discovery_page][:secondary].length).to eq(1)
      end

      it "returns 422 when required fields are missing" do
        invalid_page = {
          primary: [
            { authentication_provider_id: auth_provider.id }
          ],
          secondary: []
        }

        put :upsert, params: { discovery_page: invalid_page }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 422 when icon_url is invalid" do
        invalid_page = {
          primary: [
            { authentication_provider_id: auth_provider.id, label: "Test", icon_url: "not-a-url" }
          ],
          secondary: []
        }

        put :upsert, params: { discovery_page: invalid_page }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "allows icon_url to be omitted" do
        page_without_icon = {
          primary: [
            { authentication_provider_id: auth_provider.id, label: "Test Provider" }
          ],
          secondary: [
            { authentication_provider_id: secondary_auth_provider.id, label: "Secondary" }
          ]
        }

        put :upsert, params: { discovery_page: page_without_icon }

        expect(response).to be_successful
      end

      it "updates existing discovery_page settings" do
        account.settings[:discovery_page] = { primary: [], secondary: [] }
        account.save!

        put :upsert, params: { discovery_page: valid_discovery_page }

        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary].length).to eq(1)
      end

      context "with invalid authentication providers" do
        it "returns 422 when authentication_provider_id does not exist" do
          invalid_page = {
            primary: [
              { authentication_provider_id: 999_999, label: "Test" }
            ],
            secondary: []
          }

          put :upsert, params: { discovery_page: invalid_page }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse(response.body)

          expect(json["errors"].any? { |e| e["message"].include?("authentication_provider_id is invalid or inactive") }).to be true
        end

        it "returns 422 when authentication_provider is soft deleted" do
          deleted_provider = account.authentication_providers.create!(auth_type: "ldap")
          deleted_provider.destroy

          invalid_page = {
            primary: [
              { authentication_provider_id: deleted_provider.id, label: "Test" }
            ],
            secondary: []
          }

          put :upsert, params: { discovery_page: invalid_page }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse(response.body)
          expect(json["errors"].any? { |e| e["message"].include?("authentication_provider_id is invalid or inactive") }).to be true
        end
      end
    end
  end

  describe "GET 'show'" do
    context "when not logged in" do
      it "redirects to login" do
        get :show
        expect(response).to redirect_to(login_url)
      end
    end

    context "when logged in without permission" do
      before do
        user_factory(active_all: true)
        user_session(@user)
      end

      it "returns unauthorized" do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged in with permission" do
      before do
        account_admin_user(account:, active_all: true)
        user_session(@admin)
      end

      context "when discovery_page is configured" do
        let!(:auth_provider) { account.authentication_providers.create!(auth_type: "saml") }

        before do
          account.settings[:discovery_page] = {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Test" }],
            secondary: []
          }
          account.save!
        end

        it "returns discovery_page settings" do
          get :show

          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]["primary"].length).to eq(1)
          expect(json["discovery_page"]["primary"][0]["label"]).to eq("Test")
        end
      end

      context "when discovery_page is not configured" do
        it "returns empty discovery_page object" do
          get :show

          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]).to eq({})
        end
      end
    end
  end
end
