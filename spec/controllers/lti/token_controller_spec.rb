# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe Lti::TokenController do

  let_once(:developer_key) do
    key = DeveloperKey.create!(
      account: root_account,
      is_lti_key: true,
      public_jwk_url: 'http://test.host/jwks'
    )
    enable_developer_key_account_binding!(key)
    key
  end
  let_once(:tool) do
    ContextExternalTool.create!(
      context: root_account,
      consumer_key: 'key',
      shared_secret: 'secret',
      name: 'test tool',
      url: 'http://www.tool.com/launch',
      developer_key: developer_key,
      settings: { use_1_3: true },
      workflow_state: 'public'
    )
  end
  let(:root_account) { Account.create!(name: 'root account') }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:decoded_jwt) {JSON::JWT.decode parsed_body['access_token'], :skip_verification }
  let(:params) { {} }

  def send_request
    get :advantage_access_token, params: params, as: :json
  end

  context 'when user is not logged in' do
    it 'returns unauthorized' do
      send_request

      expect(response).to be_unauthorized
    end
  end

  context 'when user is not site admin' do
    before :each do
      user_session(account_admin_user(account: root_account))
    end
    
    it 'returns unauthorized' do
      send_request

      expect(response).to be_unauthorized
    end
  end

  context 'when user is site admin' do
    let(:user) { site_admin_user }

    before :each do
      user_session(user)
    end

    shared_examples_for 'a normal LTI access token' do
      it 'uses all LTI scopes' do
        send_request
  
        expect(decoded_jwt[:scopes]).to eq TokenScopes::LTI_SCOPES.keys.join(' ')
        expect(parsed_body['scope']).to eq TokenScopes::LTI_SCOPES.keys.join(' ')
      end

      it 'uses request host for aud claim' do
        send_request

        expect(decoded_jwt[:aud]).to eq 'http://test.host/login/oauth2/token'
      end

      it 'returns 200' do
        send_request

        expect(response).to be_successful
      end

      it 'includes user id in custom claim for tracking purposes' do
        send_request

        expect(decoded_jwt['canvas.instructure.com']['token_generated_by']).to eq user.global_id
      end

      it 'includes site admin custom claim for tracking purposes' do
        send_request

        expect(decoded_jwt['canvas.instructure.com']['token_generated_for']).to eq 'site_admin'
      end
    end

    context 'when client_id is provided' do
      let(:params) { {client_id: developer_key.global_id} }

      it 'uses client_id as sub claim' do
        send_request
  
        expect(decoded_jwt[:sub]).to eq developer_key.global_id
      end

      it_behaves_like 'a normal LTI access token'
    end

    context 'when tool_id is provided' do
      let(:params) { {tool_id: tool.global_id} }

      it "uses tool's developer key id as sub claim" do
        send_request

        expect(decoded_jwt[:sub]).to eq developer_key.global_id
      end

      it_behaves_like 'a normal LTI access token'
    end

    context 'when non-LTI key is provided' do
      let(:other_key) do
        key = DeveloperKey.create!(account: root_account)
        enable_developer_key_account_binding!(key)
        key
      end
      let(:params) { {client_id: other_key.global_id} }

      it 'returns 400' do
        send_request

        expect(response).to be_bad_request
      end
    end

    context 'when non-LTI-1.3 tool is provided' do
      let(:other_key) do
        key = DeveloperKey.create!(account: root_account)
        enable_developer_key_account_binding!(key)
        key
      end
      let(:other_tool) do
        ContextExternalTool.create!(
          context: root_account,
          consumer_key: 'key',
          shared_secret: 'secret',
          name: 'test tool',
          url: 'http://www.tool.com/launch',
          developer_key: other_key,
          settings: { use_1_3: false },
          workflow_state: 'public'
        )
      end
      let(:params) { {tool_id: other_tool.global_id} }

      it 'returns 400' do
        send_request

        expect(response).to be_bad_request
      end
    end
  end
end