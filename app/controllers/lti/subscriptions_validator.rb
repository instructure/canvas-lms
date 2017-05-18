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

module Lti
  class SubscriptionsValidator
    class InvalidContextType < StandardError
    end
    class MissingCapability < StandardError
    end
    class ToolNotInContext < StandardError
    end

    CONTEXT_WHITELIST = {
      'root_account' => Account,
      'assignment' => Assignment
    }.freeze

    attr_reader :subscription, :tool_proxy

    def initialize(subscription, tool_proxy)
      @subscription = subscription.with_indifferent_access
      @tool_proxy = tool_proxy
    end

    def check_required_capabilities!
      capabilities_hash = ToolConsumerProfile.webhook_subscription_capabilities
      return if tool_proxy.enabled_capabilities.include?(ToolConsumerProfile.webhook_grant_all_capability)

      subscription[:EventTypes].each do |event_type|
        raise MissingCapability, "EventType #{event_type} is invalid" unless capabilities_hash.keys.include?(event_type.to_sym)
        if (tool_proxy.enabled_capabilities & capabilities_hash[event_type.to_sym]).blank?
          raise MissingCapability, 'Missing required capability'
        end
      end
    end

    def check_tool_context!
      requested_context = subscription_context
      requested_context = requested_context.course if requested_context.respond_to?(:course)
      raise ToolNotInContext, "Tool does not have access to requested context" unless tool_proxy.active_in_context?(requested_context)
    end

    def validate_subscription_request!
      check_required_capabilities!
      check_tool_context!
    end

    private

    def subscription_context
      @_subscription_context ||= begin
        model = CONTEXT_WHITELIST[subscription[:ContextType]]
        raise InvalidContextType unless model

        case subscription[:ContextType]
        when "root_account"
          model.find_by(uuid: subscription[:ContextId])
        else
          model.find(subscription[:ContextId])
        end
      end
    end
  end
end
