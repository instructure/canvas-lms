# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

RSpec.describe DeveloperKeyAccountBindingsController do
  let(:root_account) { account_model }
  let(:root_account_admin) { account_admin_user(account: root_account) }
  let(:sub_account) { account_model(parent_account: root_account) }
  let(:sub_account_admin) { account_admin_user(account: sub_account) }
  let(:root_account_developer_key) do
    lti_developer_key_model(account: root_account, lti_registration: root_account_lti_registration)
  end
  let(:root_account_lti_registration) do
    lti_registration_model(account: root_account)
  end

  let(:valid_parameters) do
    {
      account_id: root_account.id,
      developer_key_id: root_account_developer_key.global_id,
      developer_key_account_binding: {
        workflow_state: "on"
      }
    }
  end

  shared_examples "the developer key account binding create endpoint" do
    let(:authorized_admin) { raise "set in example" }
    let(:unauthorized_admin) { raise "set in example" }
    let(:params) { raise "set in example" }
    let(:created_binding) { DeveloperKeyAccountBinding.find(json_parse["id"]) }
    let(:expected_account) { raise "set in example" }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      post :create_or_update, params:, format: :json
      expect(response).to be_forbidden
    end

    it 'succeeds if the user has "manage_developer_keys"' do
      user_session(authorized_admin)
      post(:create_or_update, params:)
      expect(response).to be_successful
    end

    it "creates the binding" do
      user_session(authorized_admin)
      post(:create_or_update, params:)
      expect(created_binding.account).to eq expected_account
      expect(created_binding.developer_key.global_id).to eq params[:developer_key_id]
      expect(created_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it "creates a corresponding Lti::RegistrationAccountBinding" do
      user_session(authorized_admin)
      post(:create_or_update, params:)

      new_lrab = Lti::RegistrationAccountBinding.last
      expect(new_lrab.updated_by).to eq(authorized_admin)
    end

    it "renders a properly formatted developer key account binding" do
      expected_keys = %w[id account_id developer_key_id workflow_state account_owns_binding]
      user_session(authorized_admin)
      post(:create_or_update, params:)
      expect(json_parse.keys).to match_array(expected_keys)
    end

    it "updates the binding if it already exists" do
      user_session(authorized_admin)
      post(:create_or_update, params:)

      params[:developer_key_account_binding][:workflow_state] = "on"
      post(:create_or_update, params:)
      expect(created_binding.workflow_state).to eq "on"
    end
  end

  shared_examples "the developer key update endpoint" do
    let(:authorized_admin) { raise "set in example" }
    let(:unauthorized_admin) { raise "set in example" }
    let(:params) { raise "set in example" }
    let(:updated_binding) { DeveloperKeyAccountBinding.find(json_parse["id"]) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      post :create_or_update, params:, format: :json
      expect(response).to be_forbidden
    end

    it "allows updating the workflow_state" do
      user_session(authorized_admin)
      post(:create_or_update, params:)
      expect(updated_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it "renders a properly formatted developer key account binding" do
      expected_keys = %w[id account_id developer_key_id workflow_state account_owns_binding]
      user_session(authorized_admin)
      post(:create_or_update, params:)
      expect(json_parse.keys).to match_array(expected_keys)
    end

    it "updates the corresponding Lti::RegistrationAccountBinding" do
      user_session(authorized_admin)

      params[:developer_key_account_binding][:workflow_state] = "on"
      post(:create_or_update, params:)

      updated_binding.lti_registration_account_binding.reload
      expect(updated_binding.lti_registration_account_binding.workflow_state).to eq("on")
      expect(updated_binding.lti_registration_account_binding.updated_by).to eq(authorized_admin)
    end
  end

  context "when the account is a parent account" do
    describe "POST #create_or_edit" do
      it_behaves_like "the developer key account binding create endpoint" do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters }
        let(:expected_account) { root_account }
      end

      it_behaves_like "the developer key update endpoint" do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters }
      end

      it "succeeds when account is site admin and developer key has no bindings" do
        site_admin_key = DeveloperKey.create!
        site_admin_key.developer_key_account_bindings.destroy_all
        site_admin_params = {
          account_id: "site_admin",
          developer_key_id: site_admin_key.global_id,
          developer_key_account_binding: {
            workflow_state: "on"
          }
        }

        user_session(account_admin_user(account: Account.site_admin))
        post :create_or_update, params: site_admin_params
        expect(response).to be_successful
      end
    end
  end

  context "when the account is a subaccount" do
    let(:sub_account_params) do
      {
        account_id: sub_account.id,
        developer_key_id: root_account_developer_key.id,
        developer_key_account_binding: {
          workflow_state: "off"
        }
      }
    end

    # There were tests here before describing some behavior, if we ever want to revive work on
    # sub-account dev keys we can restore them
    it "returns a 404 when trying to create a binding" do
      user_session(sub_account_admin)
      post :create_or_update, params: sub_account_params
      expect(response).to be_not_found
    end
  end

  describe "modify_site_admin_developer_keys permission" do
    let(:site_admin) { Account.site_admin }
    let(:site_admin_admin) { account_admin_user(account: site_admin) }
    let(:site_admin_without_permission) do
      user = user_model
      role = custom_account_role("limited_admin", account: site_admin)
      # Grant manage_developer_keys but not modify_site_admin_developer_keys
      site_admin.role_overrides.create!(
        permission: :manage_developer_keys,
        role:,
        enabled: true
      )
      site_admin.account_users.create!(user:, role:)
      user
    end
    let(:site_admin_key) { DeveloperKey.create!(name: "Site Admin Key") }
    let(:site_admin_binding_params) do
      {
        account_id: site_admin.id,
        developer_key_id: site_admin_key.global_id,
        developer_key_account_binding: {
          workflow_state: "on"
        }
      }
    end

    before do
      site_admin.enable_feature!(:modify_site_admin_developer_keys_permission)
    end

    context "when user has modify_site_admin_developer_keys permission" do
      before { user_session(site_admin_admin) }

      it "allows creating/updating site admin developer key bindings" do
        post :create_or_update, params: site_admin_binding_params, format: :json
        expect(response).to be_successful

        binding = DeveloperKeyAccountBinding.find(json_parse["id"])
        expect(binding.account).to eq(site_admin)
        expect(binding.workflow_state).to eq("on")
      end
    end

    context "when user lacks modify_site_admin_developer_keys permission" do
      before { user_session(site_admin_without_permission) }

      it "returns forbidden for site admin developer key bindings" do
        post :create_or_update, params: site_admin_binding_params, format: :json
        expect(response).to be_forbidden
      end
    end

    context "when feature flag is disabled" do
      before do
        site_admin.disable_feature!(:modify_site_admin_developer_keys_permission)
        user_session(site_admin_without_permission)
      end

      it "allows access when feature flag is off" do
        post :create_or_update, params: site_admin_binding_params, format: :json
        expect(response).to be_successful
      end
    end

    context "for regular account developer keys" do
      let(:regular_account) { account_model }
      let(:regular_account_admin) do
        user = user_model
        role = custom_account_role("limited_admin", account: regular_account)
        regular_account.role_overrides.create!(
          permission: :manage_developer_keys,
          role:,
          enabled: true
        )
        regular_account.account_users.create!(user:, role:)
        user
      end
      let(:regular_account_key) { DeveloperKey.create!(name: "Regular Key", account: regular_account) }
      let(:regular_binding_params) do
        {
          account_id: regular_account.id,
          developer_key_id: regular_account_key.global_id,
          developer_key_account_binding: {
            workflow_state: "on"
          }
        }
      end

      before { user_session(regular_account_admin) }

      it "does not require modify_site_admin_developer_keys for regular account keys" do
        post :create_or_update, params: regular_binding_params, format: :json
        expect(response).to be_successful
      end
    end
  end
end
