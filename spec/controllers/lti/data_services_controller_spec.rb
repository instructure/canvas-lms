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

describe Lti::DataServicesController do
  include WebMock::API

  include_context 'advantage services context'

  let(:subscription) do
    {
      ContextId: root_account.uuid,
      ContextType: 'root_account',
      EventTypes: ['discussion_topic_created'],
      Format: 'live-event',
      TransportMetadata: { Url: 'sqs.example' },
      TransportType: 'sqs'
    }
  end

  before do
    allow(Canvas::Security::ServicesJwt).to receive(:encryption_secret).and_return('setecastronomy92' * 2)
    allow(Canvas::Security::ServicesJwt).to receive(:signing_secret).and_return('donttell' * 10)
    allow(HTTParty).to receive(:send).and_return(double(body: subscription, code: 200))

    root_account.lti_context_id = SecureRandom.uuid
    root_account.save
  end

  describe '#create' do
    it_behaves_like 'lti services' do
      let(:action) { :create }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/create"}
      let(:params_overrides) do
        { subscription: subscription, account_id: root_account.lti_context_id }
      end
    end

    let(:action) { :create }

    context do
      let(:params_overrides) do
        { subscription: subscription, account_id: root_account.lti_context_id }
      end
      it 'adds OwnerId and OwnerType if passed in for a tool' do
        expect(Services::LiveEventsSubscriptionService).to receive(:create).with(any_args,
          hash_including(subscription.merge(OwnerId: tool.global_id.to_s, OwnerType: 'external_tool'))
        )
        send_request
      end
    end

    context do
      let(:params_overrides) do
        { subscription: subscription.merge(OwnerId: user.global_id), account_id: root_account.lti_context_id }
      end
      let(:user) { account_admin_user(account: root_account) }

      it 'adds OwnerId and OwnerType if passed in for a person' do
        expect(Services::LiveEventsSubscriptionService).to receive(:create).with(any_args,
          hash_including(subscription.merge(OwnerId: user.global_id.to_s, OwnerType: 'person'))
        )
        send_request
      end

      context 'with non admin user' do
        let(:user) { user_model }

        it 'raises an unprocessable_entity' do
          send_request
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with not found user' do
        let(:user) { OpenStruct.new(global_id: 'notfound') }

        it 'raises a 404' do
          send_request
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#show' do
    it_behaves_like 'lti services' do
      let(:action) { :show }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/show"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, id: 'testid' }
      end
    end
  end

  describe '#update' do
    it_behaves_like 'lti services' do
      let(:action) { :update }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/update"}
      let(:params_overrides) do
        { subscription: subscription, account_id: root_account.lti_context_id, id: 'testid' }
      end
    end

    let(:action) { :update }
    let(:subId) { 'myid' }

    context do
      let(:params_overrides) do
        { subscription: subscription, account_id: root_account.lti_context_id, id: subId }
      end

      it 'adds UpdatedBy and UpdatedByType if passed in for a tool' do
        expect(Services::LiveEventsSubscriptionService).to receive(:update).with(any_args,
          hash_including(UpdatedBy: tool.global_id.to_s, UpdatedByType: 'external_tool', Id: subId)
        )
        send_request
      end
    end

    context do
      let(:params_overrides) do
        { subscription: subscription.merge(UpdatedBy: user.global_id), account_id: root_account.lti_context_id, id: subId }
      end
      let(:user) { account_admin_user(account: root_account) }

      it 'adds UpdatedBy and UpdatedByType if passed in for a person' do
        expect(Services::LiveEventsSubscriptionService).to receive(:update).with(any_args,
          hash_including('UpdatedBy' => user.global_id.to_s, UpdatedByType: 'person', Id: subId)
        )
        send_request
      end

      context 'with non admin user' do
        let(:user) { user_model }

        it 'raises an unprocessable_entity' do
          send_request
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with not found user' do
        let(:user) { OpenStruct.new(global_id: 'notfound') }

        it 'raises a 404' do
          send_request
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#index' do
    it_behaves_like 'lti services' do
      let(:action) { :index }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/list"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id }
      end
    end
  end

  describe '#destroy' do
    it_behaves_like 'lti services' do
      let(:action) { :destroy }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/data_services/scope/destroy"}
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, id: 'testid' }
      end
    end
  end

  describe '#event_types_index' do
    it_behaves_like 'lti services' do
      let(:action) { :event_types_index }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { 'https://canvas.instructure.com/lti/data_services/scope/list_event_types' }
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, id: 'testid' }
      end
    end
  end
end
