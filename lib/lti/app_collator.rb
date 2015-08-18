# Copyright (C) 2014 Instructure, Inc.
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
  class AppCollator

    def initialize(context)
      @context = context
    end

    def bookmarked_collection
      external_tools_scope = ContextExternalTool.all_tools_for(@context)
      external_tools_collection = BookmarkedCollection.wrap(ExternalToolNameBookmarker, external_tools_scope)
      tool_proxy_scope = ToolProxy.find_installed_proxies_for_context(@context)
      tool_proxy_collection = BookmarkedCollection.wrap(ToolProxyNameBookmarker, tool_proxy_scope)
      BookmarkedCollection.merge(
        ['external_tools', external_tools_collection],
        ['message_handlers', tool_proxy_collection]
      )
    end

    def app_definitions(collection)
      collection.map do |o|
        case o
          when ContextExternalTool
            external_tool_definition(o)
          when ToolProxy
            tool_proxy_definition(o)
        end
      end
    end

    private

    def external_tool_definition(external_tool)
      {
        app_type: external_tool.class.name,
        app_id: external_tool.id,
        name: external_tool.name,
        description: external_tool.description,
        installed_locally: external_tool.context == @context,
        enabled: true,
        tool_configuration: external_tool.tool_configuration
      }
    end

    def tool_proxy_definition(tool_proxy)
      {
        app_type: tool_proxy.class.name,
        app_id: tool_proxy.id,
        name: tool_proxy.name,
        description: tool_proxy.description,
        installed_locally: tool_proxy.context == @context,
        enabled: tool_proxy.workflow_state == 'active',
        tool_configuration: nil
      }
    end


  end
end
