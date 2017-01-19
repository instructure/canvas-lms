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

      describe '.available?' do
        it 'returns true if the service is configured' do
          expect(LiveEventsSubscriptionService.available?).to eq true
        end
      end

      describe '.tool_proxy_subscriptions' do
        it 'makes the expected request' do
          product_family = mock()
          product_family.stubs(:developer_key).returns('10000000001')
          Lti::ProductFamily.stubs(:new).returns(product_family)

          proxy = mock()
          proxy.stubs(:guid).returns('151b52cd-d670-49fb-bf65-6a327e3aaca0')
          proxy.stubs(:product_family).returns(product_family)
          Lti::ToolProxy.stubs(:new).returns(proxy)

          HTTParty.expects(:send).with do |method, endpoint, options|
            expect(method).to eq(:get)
            expect(endpoint).to eq('http://example.com/api/subscriptions')
            jwt = Canvas::Security::ServicesJwt.new(options[:headers]['Authorization'].gsub('Bearer ',''), false).original_token
            expect(jwt["developerKey"]).to eq('10000000001')
            expect(jwt["sub"]).to eq('ltiToolProxy:151b52cd-d670-49fb-bf65-6a327e3aaca0')
          end
          LiveEventsSubscriptionService.tool_proxy_subscriptions(proxy)
        end
      end
    end
  end
end
