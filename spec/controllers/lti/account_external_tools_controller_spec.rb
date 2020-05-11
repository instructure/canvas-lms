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

describe Lti::AccountExternalToolsController do
  include WebMock::API

  include_context 'advantage services context'

  before do
    root_account.lti_context_id = SecureRandom.uuid
    root_account.save
  end

  describe '#show' do
    it_behaves_like 'lti services' do
      let(:action) { :show }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/show"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, external_tool_id: tool.id }
      end
    end
  end

  describe '#index' do
    it_behaves_like 'lti services' do
      let(:action) { :index }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/list"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id }
      end
    end

    let(:action) { :index }

    context 'when given just an account id' do
      let(:params_overrides) do
        { account_id: root_account.lti_context_id }
      end

      it 'returns id, domain, and other fields on account' do
        send_request
        body = JSON.parse(response.body).first
        expect(body).to include(
          'id' => tool.id,
          'domain' => tool.domain,
          'url' => tool.url,
          'consumer_key' => tool.consumer_key,
          'name' => tool.name,
          'description' => tool.description
        )
        expect(body['id']).to be_a(Integer)
        expect(body['name']).to be_a(String)
      end
    end

    context 'when an invalid account ID is given' do
      let(:params_overrides) do
        { account_id: 991234 }
      end

      it 'returns a 401' do
        send_request
        expect(response.code).to eq('401')
      end
    end
  end

  describe '#destroy' do
    it_behaves_like 'lti services' do
      let(:action) { :destroy }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/destroy"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, external_tool_id: tool.id }
      end
    end
  end

end
