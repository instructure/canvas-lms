# frozen_string_literal: true

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
        settings.present? && settings["app-host"].present?
      end

      def disabled?
        settings&.[]("disabled")
      end

      def tool_proxy_subscription(tool_proxy, subscription_id)
        show(tool_proxy_jwt_body(tool_proxy), subscription_id)
      end

      def tool_proxy_subscriptions(tool_proxy, optional_headers = {})
        index(tool_proxy_jwt_body(tool_proxy), optional_headers)
      end

      def create_tool_proxy_subscription(tool_proxy, subscription)
        Rails.logger.info do
          "in: LiveEventsSubscriptionService::create_tool_proxy_subscription, " \
            "tool_proxy_id: #{tool_proxy.id}, subscription: #{subscription}"
        end
        create(tool_proxy_jwt_body(tool_proxy), subscription)
      end

      def update_tool_proxy_subscription(tool_proxy, _subscription_id, subscription)
        update(tool_proxy_jwt_body(tool_proxy), subscription)
      end

      def destroy_tool_proxy_subscription(tool_proxy, subscription_id)
        Rails.logger.info do
          "in: LiveEventsSubscriptionService::destroy_tool_proxy_subscription, " \
            "tool_proxy_id: #{tool_proxy.id}, subscription_id: #{subscription_id}"
        end
        destroy(tool_proxy_jwt_body(tool_proxy), subscription_id)
      end

      def destroy_all_tool_proxy_subscriptions(tool_proxy)
        options = { headers: headers(tool_proxy_jwt_body(tool_proxy)) }
        request(:delete, "/api/subscriptions", options)
      end

      def create(jwt_body, subscription)
        options = {
          headers: headers(jwt_body, { "Content-Type" => "application/json" }),
          body: subscription.to_json
        }
        request(:post, "/api/subscriptions", options)
      end

      def show(jwt_body, subscription_id)
        options = { headers: headers(jwt_body) }
        request(:get, "/api/subscriptions/#{subscription_id}", options)
      end

      def update(jwt_body, subscription)
        options = {
          headers: headers(jwt_body, { "Content-Type" => "application/json" }),
          body: subscription.to_json
        }
        request(:put, "/api/subscriptions/#{subscription["Id"]}", options)
      end

      def destroy(jwt_body, subscription_id)
        options = { headers: headers(jwt_body) }
        request(:delete, "/api/subscriptions/#{subscription_id}", options)
      end

      def index(jwt_body, opts = {}, query: {})
        options = { headers: headers(jwt_body, opts), query: }
        request(:get, "/api/root_account_subscriptions", options)
      end

      def event_types_index(jwt_body, message_type, opts = {})
        options = { headers: headers(jwt_body, opts) }
        request(:get, "/api/event_types?message_type=#{message_type}", options)
      end

      private

      def request(method, endpoint, options = {})
        Canvas.timeout_protection("live-events-subscription-service-session", raise_on_timeout: true) do
          HTTParty.send(method, "#{settings["app-host"]}#{endpoint}", options.merge(timeout: 10))
        end
      end

      def headers(jwt_body, headers = {})
        token = CanvasSecurity::ServicesJwt.generate(jwt_body, symmetric: true)
        headers["Authorization"] = "Bearer #{token}"
        headers
      end

      def settings
        DynamicSettings.find("live-events-subscription-service", default_ttl: 5.minutes)
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
