require_relative "../../spec_helper"
require_dependency "services/live_events_subscription_service"

module Services
  describe LiveEventsSubscriptionService do
    include WebMock::API

    context 'service unavailable' do
      before do
        Canvas::DynamicSettings.stubs(:find).with('live-events-subscription-service').returns(nil)
      end

      after do
        Canvas::DynamicSettings.unstub(:find)
      end

      describe '.available?' do
        it 'returns false if the service is not configured' do
          expect(LiveEventsSubscriptionService.available?).to eq false
        end
      end
    end

    context 'service available' do
      before do
        Canvas::DynamicSettings.stubs(:find).with('live-events-subscription-service').returns({
          "app-host" => "http://example.com",
          "sad-panda" => nil
        })
        Canvas::DynamicSettings.stubs(:find).with('canvas').returns({
          "signing-secret" => "astringthatisactually32byteslong",
          "encryption-secret" => "astringthatisactually32byteslong"
        })
      end

      after do
        Canvas::DynamicSettings.unstub(:find)
      end

      let(:product_family) do
        product_family = mock()
        product_family.stubs(:developer_key).returns(10000000000003)
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

      describe '.destroy_tool_proxy_subscription' do
        it 'makes the expected request' do
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:delete)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["developerKey"]).to eq('10000000000003')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.destroy_tool_proxy_subscription(tool_proxy, 'subscription_id')
        end
      end

      describe '.tool_proxy_subscription' do
        it 'makes the expected request' do
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:get)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["developerKey"]).to eq('10000000000003')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.tool_proxy_subscription(tool_proxy, 'subscription_id')
        end
      end

      describe '.tool_proxy_subscriptions' do
        it 'makes the expected request' do
          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:get)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["developerKey"]).to eq('10000000000003')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.tool_proxy_subscriptions(tool_proxy)
        end
      end

      describe '.create_tool_proxy_subscription' do
        it 'makes the expected request' do
          subscription = { 'my' => 'subscription' }

          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:post)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            expect(options[:headers]['Content-Type']).to eq('application/json')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt['developerKey']).to eq('10000000000003')
            expect(jwt['sub']).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
            expect(JSON.parse(options[:body])).to eq(subscription)
          end

          LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription)
        end
      end

      describe '.update_tool_proxy_subscription' do
        it 'makes the expected request' do
          subscription = { 'my' => 'subscription' }

          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:put)
            expect(endpoint).to eq('http://example.com/api/subscriptions/subscription_id')
            expect(options[:headers]['Content-Type']).to eq('application/json')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt['developerKey']).to eq('10000000000003')
            expect(jwt['sub']).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
            expect(JSON.parse(options[:body])).to eq(subscription)
          end

          LiveEventsSubscriptionService.update_tool_proxy_subscription(tool_proxy, 'subscription_id', subscription)
        end
      end

      context 'timeout protection' do
        it 'throws an exception for .tool_proxy_subscriptions' do
          Timeout.expects(:timeout).raises(Timeout::Error)
          expect { LiveEventsSubscriptionService.tool_proxy_subscriptions(tool_proxy) }.to raise_error(Timeout::Error)
        end
      end
    end
  end
end
