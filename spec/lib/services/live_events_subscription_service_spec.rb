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

require_relative "../../spec_helper"
require_dependency "services/live_events_subscription_service"

module Services
  describe LiveEventsSubscriptionService do
    include WebMock::API

    context 'service unavailable' do
      before do
        allow(Canvas::DynamicSettings).to receive(:find)
          .with('live-events-subscription-service', {use_env: false})
          .and_return(nil)
      end

      describe '.available?' do
        it 'returns false if the service is not configured' do
          expect(LiveEventsSubscriptionService.available?).to eq false
        end
      end
    end

    context 'service available' do
      before do
        allow(Canvas::DynamicSettings).to receive(:find)
          .with('live-events-subscription-service', {use_env: false})
          .and_return({
            'app-host' => 'http://example.com',
          })
        allow(Canvas::DynamicSettings).to receive(:find)
          .with('canvas', {use_env: false})
          .and_return({
            'signing-secret' => 'astringthatisactually32byteslong',
            'encryption-secret' => 'astringthatisactually32byteslong'
          })
      end

      after do
        Canvas::DynamicSettings.unstub(:find)
      end

      let(:developer_key) do
        developer_key = mock
        developer_key.stubs(:global_id).returns(10000000000003)
        developer_key
      end

      let(:non_root_account_context) do
        non_root_account = mock()
        non_root_account.stubs(:global_root_account_id).returns(10000000000007)
        non_root_account
      end

      let(:root_account_context) do
        root_account = mock()
        root_account.stubs(:global_root_account_id).returns(nil)
        root_account.stubs(:global_id).returns(10000000000004)
        root_account
      end

      let(:root_account_object) do
        root_account_object = mock()
        root_account_object.stubs(:uuid).returns('random-account-uuid')
        root_account_object
      end

      let(:product_family) do
        product_family = mock()
        product_family.stubs(:developer_key).returns(developer_key)
        product_family
      end

      let(:tool_proxy) do
        tool_proxy = mock()
        tool_proxy.stubs(:guid).returns('151b52cd-d670-49fb-bf65-6a327e3aaca0')
        tool_proxy.stubs(:product_family).returns(product_family)
        tool_proxy
      end

      describe '.available?' do
        it 'returns true if the service is configured' do
          expect(LiveEventsSubscriptionService.available?).to eq true
        end
      end

      describe '.destroy_all_tool_proxy_subscriptions' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(root_account_context)
          root_account_context.stubs(:root_account).returns(root_account_object)
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:delete)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["DeveloperKey"]).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000004')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.destroy_all_tool_proxy_subscriptions(tool_proxy)
        end
      end

      describe '.destroy_tool_proxy_subscription' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(root_account_context)
          root_account_context.stubs(:root_account).returns(root_account_object)
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:delete)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["DeveloperKey"]).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000004')
            expect(jwt["RootAccountUUID"]).to eq('random-account-uuid')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.destroy_tool_proxy_subscription(tool_proxy, 'subscription_id')
        end
      end

      describe '.tool_proxy_subscription' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(non_root_account_context)
          non_root_account_context.stubs(:root_account).returns(root_account_object)
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:get)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["DeveloperKey"]).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000007')
            expect(jwt["RootAccountUUID"]).to eq('random-account-uuid')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.tool_proxy_subscription(tool_proxy, 'subscription_id')
        end
      end

      describe '.tool_proxy_subscriptions' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(non_root_account_context)
          non_root_account_context.stubs(:root_account).returns(root_account_object)
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:get)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["DeveloperKey"]).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000007')
            expect(jwt["RootAccountUUID"]).to eq('random-account-uuid')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.tool_proxy_subscriptions(tool_proxy)
        end
      end

      describe '.create_tool_proxy_subscription' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(root_account_context)
          root_account_context.stubs(:root_account).returns(root_account_object)
          subscription = { 'my' => 'subscription' }

          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:post)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            expect(options[:headers]['Content-Type']).to eq('application/json')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt['DeveloperKey']).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000004')
            expect(jwt["RootAccountUUID"]).to eq('random-account-uuid')
            expect(jwt['sub']).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
            expect(JSON.parse(options[:body])).to eq(subscription)
          end

          LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription)
        end
      end

      describe '.update_tool_proxy_subscription' do
        it 'makes the expected request' do
          tool_proxy.stubs(:context).returns(root_account_context)
          root_account_context.stubs(:root_account).returns(root_account_object)
          subscription = { 'my' => 'subscription' }

          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:put)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            expect(options[:headers]['Content-Type']).to eq('application/json')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt['DeveloperKey']).to eq('10000000000003')
            expect(jwt["RootAccountId"]).to eq('10000000000004')
            expect(jwt["RootAccountUUID"]).to eq('random-account-uuid')
            expect(jwt['sub']).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
            expect(JSON.parse(options[:body])).to eq(subscription)
          end

          LiveEventsSubscriptionService.update_tool_proxy_subscription(tool_proxy, 'subscription_id', subscription)
        end
      end

      context 'timeout protection' do
        it 'throws an exception for .tool_proxy_subscriptions' do
          tool_proxy.stubs(:context).returns(root_account_context)
          root_account_context.stubs(:root_account).returns(root_account_object)
          Timeout.expects(:timeout).raises(Timeout::Error)
          expect { LiveEventsSubscriptionService.tool_proxy_subscriptions(tool_proxy) }.to raise_error(Timeout::Error)
        end
      end
    end
  end
end
