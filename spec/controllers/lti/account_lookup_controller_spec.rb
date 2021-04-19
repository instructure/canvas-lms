# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/ims/concerns/advantage_services_shared_context')
require File.expand_path(File.dirname(__FILE__) + '/ims/concerns/lti_services_shared_examples')
require_dependency "lti/public_jwk_controller"

describe Lti::AccountLookupController do
  include WebMock::API

  include_context 'advantage services context'

  describe '#show' do
    it_behaves_like 'lti services' do
      let(:action) { :show }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_lookup/scope/show"}
      let(:params_overrides) do
        { account_id: Account.root_accounts.first.id }
      end
    end

    let(:action) { :show }

    context 'when given just an account it' do
      let(:params_overrides) do
        { account_id: Account.root_accounts.first.id }
      end

      it 'returns id, uuid, and other fields on account' do
        send_request
        acct = Account.root_accounts.first
        body = JSON.parse(response.body)
        expect(body).to include(
          'id' => acct.id,
          'uuid' => acct.uuid,
          'name' => acct.name,
          'workflow_state' => acct.workflow_state,
          'parent_account_id' => acct.parent_account_id,
          'root_account_id' => acct.root_account_id
        )
        expect(body['id']).to be_a(Integer)
        expect(body['uuid']).to be_a(String)
      end
    end

    context 'when an invalid account ID is given' do
      let(:params_overrides) do
        { account_id: 991234 }
      end

      it 'returns a 404' do
        send_request
        expect(response.code).to eq('404')
      end
    end

    context 'when an ID on an invalid shard given' do
      let(:params_overrides) do
        { account_id: 1987650000000000000 + Account.root_accounts.first.local_id }
      end

      it 'returns a 404' do
        expect(Shard.find_by(id: 198765)).to eq(nil)
        send_request
        expect(response.code).to eq('404')
      end
    end

    context 'when given a global ID' do
      let(:params_overrides) do
        { account_id: Account.root_accounts.first.global_id }
      end

      it 'returns id, uuid, and other fields on account' do
        send_request
        acct = Account.root_accounts.first
        body = JSON.parse(response.body)
        expect(body).to include(
          'id' => acct.id,
          'uuid' => acct.uuid,
          'name' => acct.name,
          'workflow_state' => acct.workflow_state,
          'parent_account_id' => acct.parent_account_id,
          'root_account_id' => acct.root_account_id
        )
        expect(body['id']).to be_a(Integer)
      end
    end
  end

end
