module Services
  class LiveEventsSubscriptionService
    class << self
      def available?
        settings.present?
      end

      def tool_proxy_subscription(tool_proxy, subscription_id)
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy)) }
        request(:get, "/api/subscriptions/#{subscription_id}", options)
      end

      def tool_proxy_subscriptions(tool_proxy)
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy)) }
        request(:get, '/api/subscriptions', options)
      end

      def create_tool_proxy_subscription(tool_proxy, subscription)
        options = {
          headers: headers(tool_proxy_jwt_body(tool_proxy), { 'Content-Type' => 'application/json' }),
          body: subscription.to_json
        }
        request(:post, '/api/subscriptions', options)
      end

      def update_tool_proxy_subscription(tool_proxy, subscription_id, subscription)
        options = {
          headers: headers(tool_proxy_jwt_body(tool_proxy), { 'Content-Type' => 'application/json' }),
          body: subscription.to_json
        }
        request(:put, "/api/subscriptions/#{subscription_id}", options)
      end

      def destroy_tool_proxy_subscription(tool_proxy, subscription_id)
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy)) }
        request(:delete, "/api/subscriptions/#{subscription_id}", options)
      end

      private
      def request(method, endpoint, options = {})
        Canvas.timeout_protection("live-events-subscription-service-session", raise_on_timeout: true) do
          HTTParty.send(method, "#{settings['app-host']}#{endpoint}", options.merge(timeout: 10))
        end
      end

      def headers(jwt_body, headers = {})
        token = Canvas::Security::ServicesJwt.generate(jwt_body)
        headers['Authorization'] = "Bearer #{token}"
        headers
      end

      def settings
        Canvas::DynamicSettings.from_cache("live-events-subscription-service", expires_in: 5.minutes)
      rescue Faraday::ConnectionFailed,
             Faraday::ClientError,
             Canvas::DynamicSettings::ConsulError,
             Diplomat::KeyNotFound => e
        Canvas::Errors.capture_exception(:live_events_subscription, e)
        nil
      end

      def tool_proxy_jwt_body(tool_proxy, options = {})
        options.merge({
          sub: "ltiToolProxy:#{tool_proxy.guid}",
          DeveloperKey: tool_proxy.product_family.developer_key.global_id.to_s,
          RootAccountId: (tool_proxy.context.global_root_account_id || tool_proxy.context.global_id).to_s
        })
      end
    end
  end
end
