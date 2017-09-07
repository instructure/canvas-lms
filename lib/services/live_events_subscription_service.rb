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

      def tool_proxy_subscriptions(tool_proxy, optional_headers = {})
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy), optional_headers) }
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

      def destroy_all_tool_proxy_subscriptions(tool_proxy)
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy)) }
        request(:delete, "/api/subscriptions", options)
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
        Canvas::DynamicSettings.find("live-events-subscription-service", default_ttl: 5.minutes)
      rescue Imperium::TimeoutError => e
        Canvas::Errors.capture_exception(:live_events_subscription, e)
        nil
      end

      def tool_proxy_jwt_body(tool_proxy, options = {})
        options.merge({
          sub: "ltiToolProxy:#{tool_proxy.guid}",
          DeveloperKey: tool_proxy.product_family.developer_key.global_id.to_s,
          RootAccountId: (tool_proxy.context.global_root_account_id || tool_proxy.context.global_id).to_s,
          RootAccountUUID: tool_proxy.context.root_account.uuid
        })
      end
    end
  end
end
