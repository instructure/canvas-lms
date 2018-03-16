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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe DeveloperKeyAccountBindingsController, type: :controller do
  let(:root_account) { account_model }
  let(:root_account_admin) { account_admin_user(account: root_account) }
  let(:sub_account) do
    account = account_model
    account.update!(parent_account: root_account)
    account
  end
  let(:sub_account_admin) { account_admin_user(account: sub_account) }
  let(:root_account_developer_key) { DeveloperKey.create!(account: root_account) }

  let(:valid_parameters) do
    {
      account_id: root_account.id,
      developer_key_id: root_account_developer_key.id,
      developer_key_account_binding: {
        workflow_state: 'on'
      }
    }
  end

  before do
    allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(true)
    allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(true)
  end

  shared_examples 'the developer key account binding create endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:created_binding) { DeveloperKeyAccountBinding.find(json_parse['id']) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      post :create, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'succeeds if the user has "manage_developer_keys"' do
      user_session(authorized_admin)
      post :create, params: params
      expect(response).to be_success
    end

    it 'renders unauthorized if the flag is not enabled in site admin' do
      allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(authorized_admin)
      post :create, params: params
      expect(response).to be_unauthorized
    end

    it 'renders unauthorized if the flag is not enabled in the root account' do
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(authorized_admin)
      post :create, params: params
      expect(response).to be_unauthorized
    end

    it 'creates the binding' do
      user_session(authorized_admin)
      post :create, params: params
      expect(created_binding.account_id).to eq params[:account_id]
      expect(created_binding.developer_key_id).to eq params[:developer_key_id]
      expect(created_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it 'renders a properly formatted developer key account binding' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state']
      user_session(authorized_admin)
      post :create, params: params
      expect(json_parse.keys).to match_array(expected_keys)
    end
  end

  shared_examples 'the developer key update endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:updated_binding) { DeveloperKeyAccountBinding.find(json_parse['id']) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      put :update, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'renders unauthorized if the flag is not enabled in site admin' do
      allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(unauthorized_admin)
      put :update, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'renders unauthorized if the flag is not enabled in the root account' do
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(unauthorized_admin)
      put :update, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'allows updating the workflow_state' do
      user_session(authorized_admin)
      put :update, params: params
      expect(updated_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it 'renders a properly formatted developer key account binding' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state']
      user_session(authorized_admin)
      put :update, params: params
      expect(json_parse.keys).to match_array(expected_keys)
    end
  end

  shared_examples 'the developer key index endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }
    let(:binding_index) { DeveloperKeyAccountBinding.where(id: json_parse.map{ |b| b['id'] }) }
    let(:expected_binding_index) { DeveloperKeyAccountBinding.where(account_id: [Account.site_admin, params[:account_id]]) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      get :index, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'renders unauthorized if the flag is not enabled in site admin' do
      allow_any_instance_of(Account).to receive(:feature_allowed?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(unauthorized_admin)
      get :index, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'renders unauthorized if the flag is not enabled in the root account' do
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:developer_key_management_ui_rewrite).and_return(false)
      user_session(unauthorized_admin)
      get :index, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'renders all developer key account bindings in the specified account' do
      user_session(authorized_admin)
      get :index, params: params, format: :json
      expect(binding_index).to match_array(expected_binding_index)
    end

    it 'includes bindings from the site admin account' do
      site_admin_binding = DeveloperKeyAccountBinding.create!(
        account: Account.site_admin,
        developer_key: site_admin_key
      )

      user_session(authorized_admin)
      get :index, params: params, format: :json
      expect(binding_index).to include site_admin_binding
    end

    it 'renders properly formatted developer key account bindings' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state']
      user_session(authorized_admin)
      get :index, params: params, format: :json
      expect(json_parse.first.keys).to match_array(expected_keys)
    end
  end

  context 'when the account is a parent account' do
    describe "POST #create" do
      it_behaves_like 'the developer key account binding create endpoint' do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters }
      end
    end

    describe "PUT #update" do
      let(:binding_to_edit) do
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: root_account_developer_key,
          workflow_state: 'off'
        )
      end

      it_behaves_like 'the developer key update endpoint' do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters.merge(id: binding_to_edit) }
      end
    end

    describe "GET #index" do
      let(:on_binding) do
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: root_account_developer_key,
          workflow_state: 'on'
        )
      end

      let(:off_binding) do
        off_dev_key = DeveloperKey.create!(account: root_account)
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: off_dev_key,
          workflow_state: 'off'
        )
      end

      let(:allow_binding) do
        allow_dev_key = DeveloperKey.create!(account: root_account)
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: allow_dev_key
        )
      end

      before do
        off_binding
        allow_binding
        on_binding
      end

      it_behaves_like 'the developer key index endpoint' do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters.except(:developer_key_account_binding) }
      end
    end
  end

  context 'when the account is a child account' do
    let(:invalid_admin) { account_admin_user(account: account_model) }
    let(:sub_account_params) do
      {
        account_id: sub_account.id,
        developer_key_id: root_account_developer_key.id,
        developer_key_account_binding: {
          workflow_state: 'off'
        }
      }
    end

    describe "POST #create" do
      it_behaves_like 'the developer key account binding create endpoint' do
        let(:authorized_admin) { sub_account_admin }
        let(:unauthorized_admin) { invalid_admin }
        let(:params) { sub_account_params }
      end

      it 'only allows creating bindings for keys in the context account chain' do
        sub_account.update!(parent_account: account_model)
        user_session(sub_account_admin)
        post :create, params: sub_account_params
        expect(response).to be_unauthorized
      end
    end

    describe "PUT #update" do
      let(:binding_to_edit) do
        DeveloperKeyAccountBinding.create!(
          account: sub_account,
          developer_key: root_account_developer_key,
          workflow_state: 'off'
        )
      end

      it_behaves_like 'the developer key update endpoint' do
        let(:authorized_admin) { sub_account_admin }
        let(:unauthorized_admin) { invalid_admin }
        let(:params) { sub_account_params.merge(id: binding_to_edit) }
      end

      it 'only allows updating bindings for keys in the context account chain' do
        sub_account.update!(parent_account: account_model)
        user_session(sub_account_admin)
        put :update, params: sub_account_params.merge(id: sub_account_params)
        expect(response).to be_unauthorized
      end
    end

    describe "GET #index" do
      let(:allow_binding) do
        allow_dev_key = DeveloperKey.create!(account: root_account)
        DeveloperKeyAccountBinding.create!(
          account: sub_account,
          developer_key: allow_dev_key
        )
      end

      before do
        allow_binding
      end

      it_behaves_like 'the developer key index endpoint' do
        let(:authorized_admin) { sub_account_admin }
        let(:unauthorized_admin) { invalid_admin }
        let(:params) { sub_account_params.except(:developer_key_account_binding) }
      end

      it 'includes bindings from the parent account' do
        root_account_binding = DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: root_account_developer_key,
          workflow_state: 'on'
        )

        user_session(sub_account_admin)
        get :index, params: sub_account_params.except(:developer_key_account_binding)
        expect(json_parse.map{ |b| b['id'] }).to include root_account_binding.id
      end
    end
  end
end