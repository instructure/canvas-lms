# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
  class ExternalToolTab
    attr_reader :context, :locale, :opts, :placement, :tools

    def initialize(context, placement, tools, locale = nil)
      @context = context
      @placement = placement
      @tools = tools
      @opts = opts
      @locale = locale || I18n.locale
    end

    def tabs
      tools.sort_by(&:id).map do |tool|
        asset_string_relative_to_context = context.shard.activate { tool.asset_string }
        tab = {
          id: asset_string_relative_to_context,
          label: tool.label_for(placement, locale),
          css_class: asset_string_relative_to_context,
          visibility: tool.extension_setting(placement, :visibility),
          href: :"#{context.class.to_s.downcase}_external_tool_path",
          external: true,
          hidden: tool.extension_setting(placement, :default) == "disabled",
          args: [context.id, tool.id]
        }
        target = tool.extension_setting(placement, :windowTarget)
        if target && target == "_blank"
          tab[:target] = target
          tab[:args] << { display: "borderless" }
        end
        tab
      end
    end

    def self.tool_id_for_tab(tab)
      return nil unless tab.is_a?(Hash) && tab[:id].is_a?(String)
      return nil unless tab[:id].start_with?("context_external_tool")
      return nil unless tab[:args]

      tab[:args][1]
    end

    def self.tool_for_tab(tab)
      tool_id = tool_id_for_tab(tab)
      tool_id && ContextExternalTool.find_by(id: tool_id)
    end
  end
end
