#
# Copyright (C) 2011 Instructure, Inc.
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

module Api::V1::ExternalTools
  include Api::V1::Json

  def external_tools_json(tools, context, user, session, extension_types = ContextExternalTool::EXTENSION_TYPES)
    tools.map do |topic|
      external_tool_json(topic, context, user, session, extension_types)
    end
  end

  def external_tool_json(tool, context, user, session, extension_types = ContextExternalTool::EXTENSION_TYPES)
    methods = %w[privacy_level custom_fields workflow_state vendor_help_link]
    methods += extension_types
    json = api_json(tool, user, session,
                  :only => %w(id name description url domain consumer_key
                              created_at updated_at description),
                  :methods => methods
    )

    json['selection_width'] = tool.settings[:selection_width] if tool.settings.key? :selection_width
    json['selection_height'] = tool.settings[:selection_height] if tool.settings.key? :selection_height
    json['icon_url'] = tool.settings[:icon_url] if tool.settings.key? :icon_url
    json['not_selectable'] = tool.not_selectable
    extension_types.each do |type|
      if json[type]
        json[type]['label'] = tool.label_for(type, user.locale)
        json[type].delete 'labels'
        json.delete 'labels'

        [:selection_width, :selection_height, :icon_url].each do |key|
          value = tool.extension_setting type, key
          json[type][key] = value if value
        end
      end
    end

    json
  end

  def tool_pagination_url
    if @context.is_a? Course
      api_v1_course_external_tools_url(@context)
    else
      api_v1_account_external_tools_url(@context)
    end
  end

  module UrlHelpers
    def sessionless_launch_url(context, opts={})
      uri = URI(api_v1_account_external_tool_sessionless_launch_url(context)) if context.is_a?(Account)
      uri = URI(api_v1_course_external_tool_sessionless_launch_url(context)) if context.is_a?(Course)
      return nil unless uri

      query_params = {}
      query_params[:id] = opts[:id] if opts.include?(:id)
      query_params[:url] = opts[:url] if opts.include?(:url)
      query_params[:launch_type] = opts[:launch_type] if opts.include?(:launch_type)
      query_params[:assignment_id] = opts[:assignment_id] if opts.include?(:assignment_id)
      uri.query = query_params.to_query

      uri.to_s
    end
  end
end
