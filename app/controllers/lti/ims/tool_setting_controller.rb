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
  module Ims
    class ToolSettingController < ApplicationController
      include Lti::ApiServiceHelper

      skip_before_filter :require_context
      skip_before_filter :require_user
      skip_before_filter :load_user

      def show
        tool_setting = ToolSetting.includes(:tool_proxy).find(params[:tool_setting_id])
        if tool_setting && oauth_authenticated_request?(tool_setting.tool_proxy.shared_secret)
          render json: tool_setting_json(tool_setting, value_to_boolean(params[:bubble]))
        else
          render json: {error: 'unauthorized'}, status: :unauthorized
        end
      end

      def update
        tool_setting = ToolSetting.includes(:tool_proxy).find(params[:tool_setting_id])
        if tool_setting && oauth_authenticated_request?(tool_setting.tool_proxy.shared_secret)
          tool_setting.update_attribute(:custom, custom_settings(tool_setting_type(tool_setting), JSON.parse(request.body.read)))
        else
          render json: {error: 'unauthorized'}, status: :unauthorized
        end
      end

      private

      def tool_setting_json(tool_setting, bubble)
        if bubble
          graph = []
          while tool_setting do
            graph << collect_tool_settings(tool_setting)
            case tool_setting_type(tool_setting)
              when 'LtiLink'
                tool_setting = ToolSetting.where(tool_proxy_id: tool_setting.tool_proxy_id, context_type: tool_setting.context_type, context_id: tool_setting.context_id, resource_link_id: nil).first
              when 'ToolProxyBinding'
                tool_setting = ToolSetting.where(tool_proxy_id: tool_setting.tool_proxy_id, context_type: nil, context_id: nil, resource_link_id: nil).first
              when 'ToolProxy'
                tool_setting = nil
            end
          end
          IMS::LTI::Models::ToolSettingContainer.new(graph: graph)
        else
          tool_setting.custom
        end
      end

      def collect_tool_settings(tool_setting)
        type = tool_setting_type(tool_setting)
        url = show_lti_tool_settings_url(tool_setting.id)
        custom = tool_setting.custom || {}
        IMS::LTI::Models::ToolSetting.new(custom: custom, type: type, id: url)
      end

      def custom_settings(type, json)
        if request.content_type == 'application/vnd.ims.lti.v2.toolsettings+json'
          setting = json['@graph'].find { |setting| setting['type'] == type }
          setting['custom']
        else
          json
        end
      end

      def tool_setting_type(tool_setting)
        if tool_setting.resource_link_id.present?
          'LtiLink'
        elsif tool_setting.context.present?
          'ToolProxyBinding'
        else
          'ToolProxy'
        end
      end

    end
  end
end