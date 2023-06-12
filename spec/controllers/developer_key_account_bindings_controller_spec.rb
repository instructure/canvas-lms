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
  let(:root_account_developer_key) { DeveloperKey.create!(account: root_account) }

  let(:valid_parameters) do
    {
      account_id: root_account.id,
      developer_key_id: root_account_developer_key.id,
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
      expect(response).to be_unauthorized
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
      expect(created_binding.developer_key_id).to eq params[:developer_key_id]
      expect(created_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
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

      params[:developer_key_account_binding][:workflow_state] = "allow"
      post(:create_or_update, params:)
      expect(created_binding.workflow_state).to eq "allow"
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
      expect(response).to be_unauthorized
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
  end

  context "when the account is a parent account" do
    describe "POST #create_or_edit" do
      let(:binding_to_edit) do
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: root_account_developer_key,
          workflow_state: "off"
        )
      end

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
end
