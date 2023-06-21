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

module Lti
  class PermissionChecker
    def self.authorized_lti2_action?(tool:, context:)
      perm_checker = new(tool:, context:)
      perm_checker.tool_installed_in_context?
    end

    def initialize(tool:, context:)
      @tool = tool
      @context = context
    end
    private_class_method :new

    def tool_installed_in_context?
      requested_context = @context.respond_to?(:course) ? @context.course : @context
      authorized = @tool.active_in_context?(requested_context)
      if authorized && @context.is_a?(Assignment)
        authorized &&= matching_resource_codes?
      end
      authorized
    end

    def matching_resource_codes?
      return false if (@tool.resource_codes.to_a - @context.tool_settings_resource_codes.to_a).present?

      @tool.resources.map(&:message_handlers).flatten.any? do |mh|
        mh.resource_handler.resource_type_code == @context.tool_settings_resource_codes[:resource_type_code]
      end
    end
  end
end
