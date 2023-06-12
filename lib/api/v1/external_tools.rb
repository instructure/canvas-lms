# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  def external_tools_json(tools, context, user, session, extension_types = Lti::ResourcePlacement.valid_placements(@domain_root_account))
    tools.map do |topic|
      external_tool_json(topic, context, user, session, extension_types)
    end
  end

  def external_tool_json(tool, context, user, session, extension_types = Lti::ResourcePlacement.valid_placements(@domain_root_account))
    methods = %w[privacy_level custom_fields workflow_state vendor_help_link]
    methods += extension_types
    only = %w[id name description url domain consumer_key created_at updated_at description]
    only << "allow_membership_service_access" if tool.context.root_account.feature_enabled?(:membership_service_for_lti_tools)
    json = api_json(tool,
                    user,
                    session,
                    only:,
                    methods:)
    json["url"] = tool.url_with_environment_overrides(tool.url, include_launch_url: true)
    json["domain"] = tool.domain_with_environment_overrides
    json["is_rce_favorite"] = tool.is_rce_favorite_in_context?(context) if tool.can_be_rce_favorite?
    json.merge!(tool.settings.with_indifferent_access.slice("selection_width", "selection_height", "prefer_sis_email"))
    json["icon_url"] = tool.icon_url if tool.icon_url
    json["not_selectable"] = tool.not_selectable
    json["version"] = tool.use_1_3? ? "1.3" : "1.1"
    json["developer_key_id"] = tool.developer_key_id if tool.developer_key_id
    json["deployment_id"] = tool.deployment_id if tool.deployment_id
    extension_types.each do |type|
      next unless json[type]

      json[type]["label"] = tool.label_for(type, I18n.locale)
      json[type].delete "labels"
      json.delete "labels"

      if json[type]["url"]
        json[type]["url"] = tool.url_with_environment_overrides(json[type]["url"])
      end

      %i[selection_width selection_height icon_url].each do |key|
        value = tool.extension_setting type, key
        json[type][key] = value if value
      end
    end

    json
  end

  def tool_pagination_url
    case @context
    when Course
      api_v1_course_external_tools_url(@context)
    when Group
      api_v1_group_external_tools_url(@context)
    else
      api_v1_account_external_tools_url(@context)
    end
  end

  module UrlHelpers
    def sessionless_launch_url(context, opts = {})
      uri = URI(api_v1_account_external_tool_sessionless_launch_url(context)) if context.is_a?(Account)
      uri = URI(api_v1_course_external_tool_sessionless_launch_url(context)) if context.is_a?(Course)
      return nil unless uri

      query_params = {}
      query_params[:id] = opts[:id] if opts.include?(:id)
      query_params[:url] = opts[:url] if opts.include?(:url)
      query_params[:launch_type] = opts[:launch_type] if opts.include?(:launch_type)
      query_params[:assignment_id] = opts[:assignment_id] if opts.include?(:assignment_id)
      query_params[:module_item_id] = opts[:module_item_id] if opts.include?(:module_item_id)
      uri.query = query_params.to_query

      uri.to_s
    end
  end
end
