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
#

module Lti
  class ToolProxyValidator
    attr_accessor :validator, :tool_proxy

    def initialize(tool_proxy:, tool_consumer_profile:)
      @tool_proxy = tool_proxy
      @validator = ::IMS::LTI::Services::ToolProxyValidator.new(tool_proxy)
      @validator.tool_consumer_profile = tool_consumer_profile
    end

    def errors
      @errors ||= begin
        hash = {}
        hash.merge!(invalid_capability_errors)
        hash.merge!(invalid_service_errors)
        hash.merge!(invalid_security_contract_errors)
        hash.merge!(invalid_security_profile_errors)
        hash.merge!(restricted_security_profile_errors)
      end
    end

    def validate!
      if errors.present?
        messages = []
        messages << "Invalid Capabilities" if errors[:invalid_capabilities].present?
        messages << "Invalid Services" if errors[:invalid_services].present?
        messages << "Invalid SecurityContract" if errors[:invalid_security_contract].present?
        messages << "Invalid SecurityProfiles" if errors[:invalid_security_profiles].present?
        messages << "Restricted SecurityProfiles" if errors[:restricted_security_profiles].present?
        last_message = messages.pop if messages.size > 1
        message = messages.join(", ")
        message + " and #{last_message}" if last_message
        raise Lti::Errors::InvalidToolProxyError.new message, errors
      end
    end

    private

    def invalid_capability_errors
      messages = {}
      if validator.errors[:invalid_message_handlers]
        messages[:invalid_capabilities] = validator.errors[:invalid_message_handlers][:resource_handlers].map do |rh|
          rh[:messages].map do |message|
            message[:invalid_capabilities] || message[:invalid_parameters].pluck(:variable)
          end
        end.flatten
      end
      messages
    end

    def invalid_service_errors
      messages = {}
      if validator.errors[:invalid_services]
        messages[:invalid_services] = validator.errors[:invalid_services].map do |key, value|
          {
            id: key,
            actions: value
          }
        end
      end
      messages
    end

    def invalid_security_contract_errors
      messages = {}
      if validator.errors[:invalid_security_contract]
        messages[:invalid_security_contract] = validator.errors[:invalid_security_contract].values
      end
      messages
    end

    def invalid_security_profile_errors
      messages = {}
      if validator.errors[:invalid_security_profiles]
        messages[:invalid_security_profiles] = validator.errors[:invalid_security_profiles]
      end
      messages
    end

    def restricted_security_profile_errors
      messages = {}
      profiles = %w[oauth2_access_token_ws_security lti_jwt_ws_security]
      if tool_proxy.tool_profile.security_profiles.any? { |s| profiles.include?(s.security_profile_name) } &&
         !tool_proxy.enabled_capabilities.include?("Security.splitSecret")
        messages[:restricted_security_profiles] = ["Security.splitSecret is required"]
      end
      messages
    end
  end
end
