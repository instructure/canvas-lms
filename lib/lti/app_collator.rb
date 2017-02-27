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

    def initialize(context, reregistration_url_builder = nil)
      @context = context
      @reregistration_url_builder = reregistration_url_builder
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

    def app_definitions(collection, opts={})
      collection.map do |o|
        case o
        when ContextExternalTool
          hash = external_tool_definition(o)
          if opts[:master_course_status]
            hash.merge!(o.master_course_api_restriction_data(opts[:master_course_status]))
          end
          hash
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
        tool_configuration: external_tool.tool_configuration,
        context: external_tool.context_type,
        context_id: external_tool.context.id,
        reregistration_url: nil,
        has_update: nil
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
        tool_configuration: nil,
        context: tool_proxy.context_type,
        context_id: tool_proxy.context.id,
        reregistration_url: build_reregistration_url(tool_proxy),
        has_update: root_account.feature_enabled?(:lti2_rereg) ? tool_proxy.update? : nil
      }
    end

    def root_account
      if @context.respond_to?(:root_account)
        @context.root_account
      else
        @context.account.root_account
      end
    end

    def build_reregistration_url(tool_proxy)
      if root_account.feature_enabled?(:lti2_rereg) && @reregistration_url_builder &&
          tool_proxy.reregistration_message_handler

        @reregistration_url_builder.call(@context, tool_proxy.id)
      end
    end
  end
end
