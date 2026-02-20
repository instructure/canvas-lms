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
          { authentication_provider_id: secondary_auth_provider.id, label: "Other Provider", icon: "google" }
        ],
        active: false
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
        expect(json["discovery_page"]["secondary"][0]["icon"]).to eq("google")
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

      it "returns 422 when icon is not a valid enum value" do
        invalid_page = {
          primary: [
            { authentication_provider_id: auth_provider.id, label: "Test", icon: "invalid-icon" }
          ],
          secondary: []
        }

        put :upsert, params: { discovery_page: invalid_page }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "allows icon to be omitted" do
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

      it "stores active flag when provided as true" do
        put :upsert, params: { discovery_page: valid_discovery_page.merge(active: true) }
        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["discovery_page"]["active"]).to be true
        account.reload
        expect(account.settings[:discovery_page][:active]).to be true
      end

      it "replaces entire discovery_page on subsequent updates (PUT semantics)" do
        put :upsert, params: { discovery_page: valid_discovery_page.merge(active: true) }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary].length).to eq(1)
        expect(account.settings[:discovery_page][:active]).to be true
        put :upsert, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: secondary_auth_provider.id, label: "NewPrimary" }],
            secondary: []
          }
        }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary].length).to eq(1)
        expect(account.settings[:discovery_page][:primary][0][:label]).to eq("NewPrimary")
        expect(account.settings[:discovery_page][:secondary]).to be_empty
        expect(account.settings[:discovery_page][:active]).to be false
      end

      it "clears primary array when provided empty" do
        put :upsert, params: { discovery_page: valid_discovery_page }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary]).to be_present
        put :upsert, params: {
          discovery_page: {
            primary: [],
            secondary: [{ authentication_provider_id: secondary_auth_provider.id, label: "Secondary" }]
          }
        }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary]).to be_empty
        expect(account.settings[:discovery_page][:secondary].length).to eq(1)
      end

      it "clears secondary array when provided empty" do
        put :upsert, params: { discovery_page: valid_discovery_page }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:secondary]).to be_present
        put :upsert, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Primary" }],
            secondary: []
          }
        }
        expect(response).to be_successful
        account.reload
        expect(account.settings[:discovery_page][:primary].length).to eq(1)
        expect(account.settings[:discovery_page][:secondary]).to be_empty
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

        it "returns configured discovery_page with active defaulted to false" do
          get :show

          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]["primary"].length).to eq(1)
          expect(json["discovery_page"]["primary"][0]["label"]).to eq("Test")
          expect(json["discovery_page"]["secondary"].length).to eq(0)
          expect(json["discovery_page"]["active"]).to be false
        end

        it "returns active flag when set to true" do
          account.settings[:discovery_page][:active] = true
          account.save!
          get :show
          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]["active"]).to be true
        end

        it "returns active flag when set to false" do
          account.settings[:discovery_page][:active] = false
          account.save!
          get :show
          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]["active"]).to be false
        end
      end

      context "when discovery_page is not configured" do
        it "returns discovery_page with defaults for all fields" do
          get :show

          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["discovery_page"]).to eq({ "primary" => [], "secondary" => [], "active" => false })
        end
      end
    end
  end

  describe "POST 'token'" do
    let(:past_key) { CanvasSecurity::KeyStorage.new_key }
    let(:present_key) { CanvasSecurity::KeyStorage.new_key }
    let(:future_key) { CanvasSecurity::KeyStorage.new_key }
    let(:fallback_proxy) do
      DynamicSettings::FallbackProxy.new({
                                           CanvasSecurity::KeyStorage::PAST => past_key,
                                           CanvasSecurity::KeyStorage::PRESENT => present_key,
                                           CanvasSecurity::KeyStorage::FUTURE => future_key
                                         })
    end

    before do
      allow(DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
    end

    context "when not logged in" do
      it "redirects to login" do
        post :token
        expect(response).to redirect_to(login_url)
      end
    end

    context "when logged in without permission" do
      before do
        user_factory(active_all: true)
        user_session(@user)
      end

      it "returns unauthorized" do
        post :token
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged in with permission" do
      let(:auth_provider) { account.authentication_providers.create!(auth_type: "saml") }
      let(:secondary_auth_provider) { account.authentication_providers.create!(auth_type: "cas") }

      before do
        account_admin_user(account:, active_all: true)
        user_session(@admin)
      end

      it "returns a JWT token" do
        post :token, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Students", icon: "google" }],
            secondary: []
          }
        }
        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["token"]).to be_present
      end

      it "returns a valid RS256-signed JWT" do
        post :token, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Students" }],
            secondary: []
          }
        }
        token = json_parse(response.body)["token"]
        decoded = CanvasSecurity.decode_jwt(token, [CanvasSecurity::ServicesJwt::KeyStorage.present_key])
        expect(decoded["sub"]).to eq(@admin.global_id.to_s)
      end

      it "includes all required claims" do
        post :token, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Students", icon: "google" }],
            secondary: [{ authentication_provider_id: secondary_auth_provider.id, label: "Admins" }]
          }
        }
        token = json_parse(response.body)["token"]
        decoded = CanvasSecurity.decode_jwt(token, [CanvasSecurity::ServicesJwt::KeyStorage.present_key])
        expect(decoded["sub"]).to eq(@admin.global_id.to_s)
        expect(decoded["iat"]).to be_a(Integer)
        expect(decoded["exp"]).to eq(decoded["iat"] + 30)
        expect(decoded["org"]).to eq(account.uuid)
        expect(decoded["scope"]).to eq("discovery.preview")
        expect(decoded).to have_key("aud")
        expect(decoded["primary"]).to be_an(Array)
        expect(decoded["primary"].length).to eq(1)
        expect(decoded["secondary"]).to be_an(Array)
        expect(decoded["secondary"].length).to eq(1)
      end

      it "serializes button links in identity service format" do
        post :token, params: {
          discovery_page: {
            primary: [{ authentication_provider_id: auth_provider.id, label: "Students", icon: "google" }],
            secondary: []
          }
        }
        token = json_parse(response.body)["token"]
        decoded = CanvasSecurity.decode_jwt(token, [CanvasSecurity::ServicesJwt::KeyStorage.present_key])
        link = decoded["primary"].first
        expect(link["label"]).to eq("Students")
        expect(link["icon"]).to eq("google")
        expect(link["path"]).to eq(auth_provider.login_authentication_provider_path)
      end

      it "omits entries for non-existent providers" do
        post :token, params: {
          discovery_page: {
            primary: [
              { authentication_provider_id: auth_provider.id, label: "Valid" },
              { authentication_provider_id: 999_999, label: "Invalid" }
            ],
            secondary: []
          }
        }
        token = json_parse(response.body)["token"]
        decoded = CanvasSecurity.decode_jwt(token, [CanvasSecurity::ServicesJwt::KeyStorage.present_key])
        expect(decoded["primary"].length).to eq(1)
        expect(decoded["primary"].first["label"]).to eq("Valid")
      end

      it "returns 400 when no body is provided" do
        post :token
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
