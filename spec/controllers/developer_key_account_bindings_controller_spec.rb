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

  shared_examples 'the developer key account binding create endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:created_binding) { DeveloperKeyAccountBinding.find(json_parse['id']) }
    let(:expected_account) { raise 'set in example' }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      post :create_or_update, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'succeeds if the user has "manage_developer_keys"' do
      user_session(authorized_admin)
      post :create_or_update, params: params
      expect(response).to be_successful
    end

    it 'creates the binding' do
      user_session(authorized_admin)
      post :create_or_update, params: params
      expect(created_binding.account).to eq expected_account
      expect(created_binding.developer_key_id).to eq params[:developer_key_id]
      expect(created_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it 'renders a properly formatted developer key account binding' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state', 'account_owns_binding']
      user_session(authorized_admin)
      post :create_or_update, params: params
      expect(json_parse.keys).to match_array(expected_keys)
    end

    it 'updates the binding if it already exists' do
      user_session(authorized_admin)
      post :create_or_update, params: params

      params[:developer_key_account_binding][:workflow_state] = 'allow'
      post :create_or_update, params: params
      expect(created_binding.workflow_state).to eq 'allow'
    end
  end

  shared_examples 'the developer key update endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:updated_binding) { DeveloperKeyAccountBinding.find(json_parse['id']) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
      user_session(unauthorized_admin)
      post :create_or_update, params: params, format: :json
      expect(response).to be_unauthorized
    end

    it 'allows updating the workflow_state' do
      user_session(authorized_admin)
      post :create_or_update, params: params
      expect(updated_binding.workflow_state).to eq params.dig(:developer_key_account_binding, :workflow_state)
    end

    it 'renders a properly formatted developer key account binding' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state', 'account_owns_binding']
      user_session(authorized_admin)
      post :create_or_update, params: params
      expect(json_parse.keys).to match_array(expected_keys)
    end
  end

  shared_examples 'the developer key index endpoint' do
    let(:authorized_admin) { raise 'set in example' }
    let(:unauthorized_admin) { raise 'set in example' }
    let(:params) { raise 'set in example' }
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }
    let(:binding_index) { DeveloperKeyAccountBinding.where(id: json_parse.map{ |b| b['id'] }) }
    let(:expected_binding_index) { DeveloperKeyAccountBinding.where(account_id: account.account_chain_ids.concat([Account.site_admin.id])) }

    it 'renders unauthorized if the user does not have "manage_developer_keys"' do
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
      site_admin_binding = site_admin_key.developer_key_account_bindings.find_by(
        account: Account.site_admin
      )

      user_session(authorized_admin)
      get :index, params: params, format: :json
      expect(binding_index).to include site_admin_binding
    end

    it 'renders properly formatted developer key account bindings' do
      expected_keys = ['id', 'account_id', 'developer_key_id', 'workflow_state', 'account_owns_binding']
      user_session(authorized_admin)
      get :index, params: params, format: :json
      expect(json_parse.first.keys).to match_array(expected_keys)
    end
  end

  context 'when the account is a parent account' do
    describe "POST #create_or_edit" do
      let(:binding_to_edit) do
        DeveloperKeyAccountBinding.create!(
          account: root_account,
          developer_key: root_account_developer_key,
          workflow_state: 'off'
        )
      end

      it_behaves_like 'the developer key account binding create endpoint' do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters }
        let(:expected_account) { root_account }
      end

      it_behaves_like 'the developer key update endpoint' do
        let(:authorized_admin) { root_account_admin }
        let(:unauthorized_admin) { sub_account_admin }
        let(:params) { valid_parameters }
      end

      it 'succeeds when account is site admin and developer key has no bindings' do
        site_admin_key = DeveloperKey.create!
        site_admin_key.developer_key_account_bindings.destroy_all
        site_admin_params = {
          account_id: 'site_admin',
          developer_key_id: site_admin_key.global_id,
          developer_key_account_binding: {
            workflow_state: 'on'
          }
        }

        user_session(account_admin_user(account: Account.site_admin))
        post :create_or_update, params: site_admin_params
        expect(response).to be_successful
      end
    end

    describe "GET #index" do
      let(:on_binding) do
        b = root_account_developer_key.developer_key_account_bindings.find_by(
          account: root_account
        )
        b.update!(workflow_state: 'on')
        b
      end

      let(:off_binding) do
        off_dev_key = DeveloperKey.create!(account: root_account)
        b = off_dev_key.developer_key_account_bindings.find_by(
          account: root_account
        )
        b.update!(workflow_state: 'off')
        b
      end

      let(:allow_binding) do
        allow_dev_key = DeveloperKey.create!(account: root_account)
        allow_dev_key.developer_key_account_bindings.find_by(
          account: root_account
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
        let(:account) { root_account }
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

    describe "POST #create_or_edit" do
      let(:binding_to_edit) do
        DeveloperKeyAccountBinding.create!(
          account: sub_account,
          developer_key: root_account_developer_key,
          workflow_state: 'off'
        )
      end

      it_behaves_like 'the developer key account binding create endpoint' do
        let(:authorized_admin) { sub_account_admin }
        let(:unauthorized_admin) { invalid_admin }
        let(:params) { sub_account_params }
        let(:expected_account) { sub_account }
      end

      # test when the account id is 'self'
      it_behaves_like 'the developer key account binding create endpoint' do
        let(:authorized_admin) { account_admin_user(account: Account.default) }
        let(:unauthorized_admin) { invalid_admin }
        let(:expected_account) { Account.default }
        let(:params) do
          sub_account_params.merge({
            account_id: 'self',
            developer_key_id: DeveloperKey.create!(account: Account.default).id,
          })
        end
      end

      it 'only allows creating bindings for keys in the context account chain' do
        sub_account.update!(parent_account: account_model)
        user_session(sub_account_admin)
        post :create_or_update, params: sub_account_params
        expect(response).to be_not_found
      end

      it_behaves_like 'the developer key update endpoint' do
        let(:authorized_admin) { sub_account_admin }
        let(:unauthorized_admin) { invalid_admin }
        let(:params) { sub_account_params }
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
        let(:account) { sub_account }
      end

      it 'includes bindings from the parent account' do
        root_account_binding = root_account_developer_key.developer_key_account_bindings.find_by(
          account: root_account
        )

        user_session(sub_account_admin)
        get :index, params: sub_account_params.except(:developer_key_account_binding)
        expect(json_parse.map{ |b| DeveloperKeyAccountBinding.find(b['id']) }).to include root_account_binding
      end
    end
  end
end
