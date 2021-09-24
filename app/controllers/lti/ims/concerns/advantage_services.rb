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

module Lti::Ims::Concerns
  module AdvantageServices
    extend ActiveSupport::Concern
    include LtiServices

    included do
      before_action(
        :verify_active_in_account,
        :verify_context,
        :verify_tool
      )

      def verify_active_in_account
        render_error("Invalid Developer Key", :unauthorized) unless active_binding_for_account?
      end

      def verify_context
        render_error("Context not found", :not_found) if context.blank?
      end

      def verify_tool
        render_error("Access Token not linked to a Tool associated with this Context", :unauthorized) if tool.blank?
      end

      def context
        raise 'Abstract Method'
      end

      def active_binding_for_account?
        developer_key.usable_in_context?(context)
      end

      def tool
        @_tool ||= begin
          return nil unless context
          return nil unless developer_key
          ContextExternalTool.all_tools_for(context).where(developer_key: developer_key).take
        end
      end
    end
  end
end
