#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')
require_dependency "lti/ims/access_token_helper"
module Lti
  describe 'Webhook Subscription API', type: :request do
    specs_require_sharding
    include_context 'lti2_api_spec_helper'

    let(:controller) { double(lti2_service_name: 'vnd.Canvas.webhooksSubscription') }
    let(:subscription_id) { 'ab342-c444-29392-e222' }
    let(:test_subscription) { {'RootAccountId' => '1', 'Id' => subscription_id} }

    let(:show_endpoint) { "/api/lti/subscriptions/#{subscription_id}" }
    let(:delete_endpoint) { "/api/lti/subscriptions/#{subscription_id}" }
    let(:update_endpoint) { "/api/lti/subscriptions/#{subscription_id}" }
    let(:create_endpoint) { "/api/lti/subscriptions" }
    let(:index_endpoint) { "/api/lti/subscriptions" }

    let(:ok_response) { double(body: subscription.to_json, code: 200) }
    let(:not_found_response) { double(body: "{}", code: 404) }
    let(:delete_response) { double(body: "{}", code: 200) }

    let(:subscription_service) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
    let(:subscription) do
      {
        EventTypes:["attachment_created"],
        ContextType: "root_account",
        ContextId: account.uuid,
        Format: "live-event",
        TransportType: "sqs",
        TransportMetadata: { Url: "http://sqs.docker" }
      }
    end

    before(:each){allow(subscription_service).to receive_messages(available?: true)}

    describe '#create' do
      let(:test_subscription){ {'RootAccountId' => '1', 'foo' => 'bar'} }
      let(:stub_response){ double(code: 200, body: test_subscription.to_json) }

      before(:each) do
        allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
      end

      it 'creates subscriptions' do
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response).to be_success
      end

      it 'checks that the tool proxy has the correct enabled capabilities' do
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response).to be_unauthorized
      end

      it 'gives error message when missing capabilities' do
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Unauthorized subscription'
      end

      it 'renders 401 if Lti::ToolProxy#active_in_context? does not return true' do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).with(an_instance_of(Account)).and_return(false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response).to be_unauthorized
      end

      it 'gives error message if Lti::ToolProxy#active_in_context? does not return true' do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).with(an_instance_of(Account)).and_return(false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Unauthorized subscription'
      end

      it 'requires JWT Access token' do
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }
        expect(response).to be_unauthorized
      end

      it 'gives 500 if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response.status).to eq 500
      end

      it 'gives useful message if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        post create_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Subscription service not configured'
      end
    end

    describe '#destroy' do
      before(:each) do
        allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: delete_response)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
      end

      it 'deletes subscriptions' do
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        delete delete_endpoint, headers: request_headers
        expect(response).to be_success
      end

      it 'gives 404 if subscription does not exist' do
        allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: not_found_response)
        delete delete_endpoint, headers: request_headers
        expect(response).not_to be_success
      end

      it 'requires JWT Access token' do
        delete delete_endpoint, params: {}
        expect(response).to be_unauthorized
      end

      it 'gives 500 if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        delete delete_endpoint, headers: request_headers
        expect(response.status).to eq 500
      end

      it 'gives useful message if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        delete delete_endpoint, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Subscription service not configured'
      end
    end

    describe '#show' do
      before(:each) do
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
      end

      it 'shows subscriptions' do
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        get show_endpoint, headers: request_headers
        expect(response).to be_success
      end

      it 'gives gives 404 if subscription does not exist' do
        allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: not_found_response)
        get show_endpoint, headers: request_headers
        expect(response).not_to be_success
      end

      it 'requires JWT Access token' do
        get show_endpoint, params: {}
        expect(response).to be_unauthorized
      end

      it 'gives 500 if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        get show_endpoint, headers: request_headers
        expect(response.status).to eq 500
      end

      it 'gives useful message if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscription: ok_response)
        get show_endpoint, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Subscription service not configured'
      end
    end

    describe '#update' do
      before(:each) do
        allow(subscription_service).to receive_messages(update_tool_proxy_subscription: ok_response)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
      end

      it 'updates subscriptions' do
        put update_endpoint, params: {subscription: subscription}, headers: request_headers
        expect(response).to be_success
      end

      it 'gives gives 404 if subscription does not exist' do
        allow(subscription_service).to receive_messages(update_tool_proxy_subscription: not_found_response)
        put update_endpoint, params: {subscription: subscription}, headers: request_headers
        expect(response).to be_not_found
      end

      it 'checks that the tool proxy has the correct enabled capabilities' do
        tool_proxy[:raw_data]['enabled_capability'] = []
        tool_proxy.save!
        put update_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response).to be_unauthorized
      end

      it 'gives error message when missing capabilities' do
        tool_proxy[:raw_data]['enabled_capability'] = []
        tool_proxy.save!
        put update_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Unauthorized subscription'
      end

      it 'renders 401 if Lti::ToolProxy#active_in_context? does not return true' do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).with(an_instance_of(Account)).and_return(false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        put update_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(response).to be_unauthorized
      end

      it 'gives error message if Lti::ToolProxy#active_in_context? does not return true' do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).with(an_instance_of(Account)).and_return(false)
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
        put update_endpoint, params: { subscription: subscription }, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Unauthorized subscription'
      end

      it 'requires JWT Access token' do
        put update_endpoint, params: {subscription: subscription}
        expect(response).to be_unauthorized
      end

      it 'gives 500 if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        put update_endpoint, params: {subscription: subscription}, headers: request_headers
        expect(response.status).to eq 500
      end

      it 'gives useful message if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        put update_endpoint, params: {subscription: subscription}, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Subscription service not configured'
      end

    end

    describe '#index' do
      before(:each) do
        tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
        tool_proxy.save!
      end

      let(:pagination_key) { { Id: "71d6dfba-0547-477d-b41d-db8cb528c6d1", DeveloperKey: "10000000000001" } }
      let(:pagination_request_headers) { { StartKey: pagination_key.to_json, Authorization: "Bearer #{access_token}" } }
      let(:ok_pagination_response) do
        double(
          body: [subscription].to_json,
          code: 200,
          headers: { 'endkey' => pagination_key.to_json }
        )
      end
      let(:ok_unpaginated_response) do
        double(
          body: [subscription].to_json,
          code: 200,
          headers: {}
        )
      end

      it 'shows subscriptions for a tool proxy' do
        allow(subscription_service).to receive(:tool_proxy_subscriptions) { ok_unpaginated_response }
        get index_endpoint, headers: request_headers
        expect(JSON.parse(response.body).first['ContextId']).to eq account.uuid
      end

      it 'shows subscriptions for a tool proxy from a pagination response' do
        allow(subscription_service).to receive(:tool_proxy_subscriptions) { ok_pagination_response }
        get index_endpoint, headers: request_headers
        expect(response).to be_success
      end

      it 'includes pagination headers' do
        allow(subscription_service).to receive(:tool_proxy_subscriptions) { ok_pagination_response }
        get index_endpoint, headers: request_headers
        expect(JSON.parse(response.headers['EndKey'])).to eq pagination_key.with_indifferent_access
      end

      it 'shows subscriptions for a tool proxy with optional pagination header' do
        allow(subscription_service).to receive(:tool_proxy_subscriptions) { ok_pagination_response }
        get index_endpoint, headers: pagination_request_headers
        expect(response).to be_success
      end

      it 'requires JWT Access token' do
        get index_endpoint, params: {}
        expect(response).to be_unauthorized
      end

      it 'gives 500 if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscriptions: ok_response)
        get index_endpoint, headers: request_headers
        expect(response.status).to eq 500
      end

      it 'gives useful message if the subscription service is not configured' do
        allow(subscription_service).to receive_messages(available?: false)
        allow(subscription_service).to receive_messages(tool_proxy_subscriptions: ok_response)
        get index_endpoint, headers: request_headers
        expect(JSON.parse(response.body)['error']).to eq 'Subscription service not configured'
      end

    end

  end
end
