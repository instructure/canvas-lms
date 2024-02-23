# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::IMS::Concerns
  module AdvantageServices
    def self.included(klass)
      super
      return unless klass.is_a?(Class)

      klass.include(LtiServices)

      klass.before_action(
        :verify_active_in_account,
        :verify_context,
        :verify_tool
      )
    end

    def verify_active_in_account
      render_error("Invalid Developer Key", :unauthorized) unless active_binding_for_account?
    end

    def verify_context
      render_error("Context is deleted or not found", :not_found) if context.blank? || context.deleted?
    end

    def verify_tool
      render_error("Access Token not linked to a Tool associated with this Context", :unauthorized) if tool.blank?
    end

    def context
      raise "Abstract Method"
    end

    def active_binding_for_account?
      developer_key.usable_in_context?(context)
    end

    def tool
      # Not sure what the correct order is. Previously it used collation order on name, followed
      # by id, but that seems arbitrary; now that tools can be cross-shard, it's also hard to
      # implement. It now is shard (course/immediate root-account first), then id.
      @tool ||= context && developer_key &&
                Lti::ContextToolFinder.new(
                  context,
                  base_scope: ContextExternalTool.order(:id).where(developer_key:)
                ).all_tools_scope_union.take
    end
  end
end
