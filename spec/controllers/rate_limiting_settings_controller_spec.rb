# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe RateLimitingSettingsController do
  let(:account) { Account.create! }
  let(:admin_user) { account_admin_user(account:) }

  before do
    user_session(admin_user)

    # Grant manage_rate_limiting permission via Site Admin (since it's only assignable there)
    # First make the user a site admin
    Account.site_admin.account_users.find_or_create_by(user: admin_user) do |au|
      au.role = Role.get_built_in_role("AccountAdmin", root_account_id: Account.site_admin.id)
    end

    # Then grant the permission in Site Admin context
    RoleOverride.find_or_create_by!(
      context: Account.site_admin,
      role: Role.get_built_in_role("AccountAdmin", root_account_id: Account.site_admin.id),
      permission: :manage_rate_limiting
    ) do |override|
      override.enabled = true
    end
  end

  describe "permissions" do
    context "when user has manage_rate_limiting permission via Site Admin" do
      let(:target_account) { Account.create! }
      let(:site_admin_user) { user_factory }

      before do
        # Make user a site admin
        Account.site_admin.account_users.create!(
          user: site_admin_user,
          role: Role.get_built_in_role("AccountAdmin", root_account_id: Account.site_admin.id)
        )

        # Grant manage_rate_limiting permission in Site Admin context
        RoleOverride.find_or_create_by!(
          context: Account.site_admin,
          role: Role.get_built_in_role("AccountAdmin", root_account_id: Account.site_admin.id),
          permission: :manage_rate_limiting
        ) do |override|
          override.enabled = true
        end

        # Enable the feature flag for the target account
        target_account.enable_feature!(:api_rate_limits)

        user_session(site_admin_user)
      end

      it "allows access to manage rate limits in any account" do
        get :index, params: { account_id: target_account.id }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "when feature flag is disabled" do
      before { account.disable_feature!(:api_rate_limits) }

      it "denies access" do
        get :index, params: { account_id: account.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user lacks manage_rate_limiting permission" do
      let(:regular_account) { Account.create! }
      let(:regular_admin) { account_admin_user(account: regular_account) }

      before do
        # Enable feature flag but don't grant Site Admin permission
        regular_account.enable_feature!(:api_rate_limits)
        user_session(regular_admin)
      end

      it "denies access since permission is only grantable via Site Admin" do
        get :index, params: { account_id: regular_account.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #index" do
    let!(:oauth_client_config) do
      account.oauth_client_configs.create!(
        type: "product",
        identifier: "test-partner-product",
        throttle_high_water_mark: 1000,
        comment: "Test setting",
        updated_by: admin_user
      )
    end

    it "returns rate limit settings" do
      account.enable_feature!(:api_rate_limits)

      get :index, params: { account_id: account.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to be_an(Array)
      expect(json.first["id"]).to eq(oauth_client_config.id.to_s)
    end

    it "includes pagination metadata in headers" do
      account.enable_feature!(:api_rate_limits)

      get :index, params: { account_id: account.id }, format: :json

      expect(response).to have_http_status(:ok)
      # BookmarkedCollection pagination uses HTTP Link headers instead of response body metadata
      expect(response.headers).to have_key("Link")
    end

    it "excludes deleted records from results" do
      account.enable_feature!(:api_rate_limits)

      # Create a deleted record
      deleted_config = account.oauth_client_configs.create!(
        type: "product",
        identifier: "deleted-partner-product",
        throttle_high_water_mark: 500,
        comment: "This will be deleted",
        updated_by: admin_user
      )
      deleted_config.destroy

      get :index, params: { account_id: account.id }, format: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      returned_ids = json.pluck("id")
      expect(returned_ids).not_to include(deleted_config.id.to_s)
      expect(returned_ids).to include(oauth_client_config.id.to_s)
    end
  end

  describe "sorting functionality" do
    let(:user2) { account_admin_user(account:) }
    let!(:config1) do
      account.oauth_client_configs.create!(
        type: "product",
        identifier: "aaa-first-product",
        client_name: "Alpha Client",
        throttle_high_water_mark: 500,
        throttle_outflow: 10,
        comment: "First comment",
        updated_by: admin_user
      )
    end
    let!(:config2) do
      account.oauth_client_configs.create!(
        type: "custom",
        identifier: "zzz-last-custom",
        client_name: "Zulu Client",
        throttle_high_water_mark: 1500,
        throttle_outflow: 25,
        comment: "Second comment",
        updated_by: user2
      )
    end

    before do
      account.enable_feature!(:api_rate_limits)
      # Update timestamps to ensure predictable ordering
      config1.update_column(:created_at, 1.day.ago)
      config2.update_column(:created_at, Time.current)
    end

    context "sorting by type" do
      it "sorts by type ascending" do
        get :index, params: { account_id: account.id, order_by: :type, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("identifier_type")).to eq(["custom", "product"])
      end

      it "sorts by type descending" do
        get :index, params: { account_id: account.id, order_by: :type, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("identifier_type")).to eq(["product", "custom"])
      end
    end

    context "sorting by identifier" do
      it "sorts by identifier ascending" do
        get :index, params: { account_id: account.id, order_by: :identifier, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("identifier_value")).to eq(["aaa-first-product", "zzz-last-custom"])
      end

      it "sorts by identifier descending" do
        get :index, params: { account_id: account.id, order_by: :identifier, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("identifier_value")).to eq(["zzz-last-custom", "aaa-first-product"])
      end
    end

    context "sorting by name (client_name)" do
      it "sorts by name ascending" do
        get :index, params: { account_id: account.id, order_by: :name, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        # Null client_name should come first in ascending order
        client_names = json.pluck("client_name")
        expect(client_names).to eq(["Alpha Client", "Zulu Client"])
      end

      it "sorts by name descending" do
        get :index, params: { account_id: account.id, order_by: :name, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        client_names = json.pluck("client_name")
        expect(client_names).to eq(["Zulu Client", "Alpha Client"])
      end
    end

    context "sorting by rate_limit (throttle_high_water_mark)" do
      it "sorts by rate_limit ascending" do
        get :index, params: { account_id: account.id, order_by: :rate_limit, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("rate_limit")).to eq([500, 1500])
      end

      it "sorts by rate_limit descending" do
        get :index, params: { account_id: account.id, order_by: :rate_limit, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("rate_limit")).to eq([1500, 500])
      end
    end

    context "sorting by outflow_rate" do
      it "sorts by outflow_rate ascending" do
        get :index, params: { account_id: account.id, order_by: :outflow_rate, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        # Null outflow_rate should come first in ascending order
        outflow_rates = json.pluck("outflow_rate")
        expect(outflow_rates).to eq([10, 25])
      end

      it "sorts by outflow_rate descending" do
        get :index, params: { account_id: account.id, order_by: :outflow_rate, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        outflow_rates = json.pluck("outflow_rate")
        expect(outflow_rates).to eq([25, 10])
      end
    end

    context "sorting by comments" do
      it "sorts by comments ascending" do
        get :index, params: { account_id: account.id, order_by: :comments, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("comment")).to eq(["First comment", "Second comment"])
      end

      it "sorts by comments descending" do
        get :index, params: { account_id: account.id, order_by: :comments, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.pluck("comment")).to eq(["Second comment", "First comment"])
      end
    end

    context "sorting by updated (updated_at)" do
      it "sorts by updated ascending" do
        get :index, params: { account_id: account.id, order_by: :updated, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        updated_times = json.map { |item| Time.zone.parse(item["updated_at"]) }
        expect(updated_times).to eq(updated_times.sort)
      end

      it "sorts by updated descending" do
        get :index, params: { account_id: account.id, order_by: :updated, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        updated_times = json.map { |item| Time.zone.parse(item["updated_at"]) }
        expect(updated_times).to eq(updated_times.sort.reverse)
      end
    end

    context "sorting by updated_by" do
      it "sorts by updated_by ascending" do
        get :index, params: { account_id: account.id, order_by: :updated_by, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        updated_by_names = json.pluck("updated_by")
        expect(updated_by_names).to eq(updated_by_names.sort)
      end

      it "sorts by updated_by descending" do
        get :index, params: { account_id: account.id, order_by: :updated_by, direction: :desc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        updated_by_names = json.pluck("updated_by")
        expect(updated_by_names).to eq(updated_by_names.sort.reverse)
      end
    end

    context "default sorting by created_at" do
      it "sorts by created_at descending by default" do
        get :index, params: { account_id: account.id }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        created_times = json.map { |item| Time.zone.parse(item["created_at"]) }

        # Default should be descending (newest first)
        expect(created_times.first).to be > created_times.last
      end

      it "sorts by created_at ascending when specified" do
        get :index, params: { account_id: account.id, direction: :asc }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        created_times = json.map { |item| Time.zone.parse(item["created_at"]) }
        expect(created_times).to eq(created_times.sort)
      end
    end

    context "invalid sort parameters" do
      it "falls back to default sorting for invalid order_by" do
        get :index, params: { account_id: account.id, order_by: :invalid_field }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        # Should fall back to created_at sorting
        created_times = json.map { |item| Time.zone.parse(item["created_at"]) }
        expect(created_times.first).to be >= created_times.last
      end

      it "handles invalid direction gracefully" do
        get :index, params: { account_id: account.id, direction: :invalid }, format: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to be_an(Array)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        account_id: account.id,
        rate_limit_setting: {
          type: "product",
          identifier: "new-partner-product",
          throttle_high_water_mark: 500,
          client_name: "Test Client",
          comment: "New test setting"
        }
      }
    end

    it "creates a new rate limit setting" do
      account.enable_feature!(:api_rate_limits)

      expect do
        post :create, params: valid_params, format: :json
      end.to change(OAuthClientConfig, :count).by(1)

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["identifier_value"]).to eq("new-partner-product")

      # Verify the automatic throttle_maximum calculation
      created_config = OAuthClientConfig.find(json["id"])
      expect(created_config.throttle_high_water_mark).to eq(500)
      expect(created_config.throttle_maximum).to eq(700) # 500 + 200
    end

    it "returns validation errors for invalid data" do
      account.enable_feature!(:api_rate_limits)

      invalid_params = valid_params.deep_dup
      invalid_params[:rate_limit_setting][:type] = "invalid"

      post :create, params: invalid_params, format: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json["errors"]).to be_present
    end
  end

  describe "PUT #update" do
    let!(:oauth_client_config) do
      account.oauth_client_configs.create!(
        type: "product",
        identifier: "existing-partner-product",
        throttle_high_water_mark: 1000,
        comment: "Original comment",
        updated_by: admin_user
      )
    end

    let(:update_params) do
      {
        account_id: account.id,
        id: oauth_client_config.id,
        rate_limit_setting: {
          throttle_high_water_mark: 2000,
          comment: "Updated comment"
        }
      }
    end

    it "updates the rate limit setting" do
      account.enable_feature!(:api_rate_limits)

      put :update, params: update_params, format: :json

      expect(response).to have_http_status(:ok)
      oauth_client_config.reload
      expect(oauth_client_config.throttle_high_water_mark).to eq(2000)
      expect(oauth_client_config.throttle_maximum).to eq(2200) # 2000 + 200
      expect(oauth_client_config.comment).to eq("Updated comment")
    end

    it "does not allow updating identifier fields" do
      account.enable_feature!(:api_rate_limits)

      update_params[:rate_limit_setting][:identifier] = "changed-identifier"

      put :update, params: update_params, format: :json

      oauth_client_config.reload
      expect(oauth_client_config.identifier).to eq("existing-partner-product")
    end
  end

  describe "DELETE #destroy" do
    let!(:oauth_client_config) do
      account.oauth_client_configs.create!(
        type: "product",
        identifier: "to-be-deleted",
        throttle_high_water_mark: 1000,
        updated_by: admin_user
      )
    end

    it "deletes the rate limit setting" do
      account.enable_feature!(:api_rate_limits)

      expect do
        delete :destroy, params: { account_id: account.id, id: oauth_client_config.id }, format: :json
      end.to change { OAuthClientConfig.active.count }.by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent setting" do
      account.enable_feature!(:api_rate_limits)

      delete :destroy, params: { account_id: account.id, id: 99_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
