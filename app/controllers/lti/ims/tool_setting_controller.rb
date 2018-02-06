#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'ims/lti'

module Lti
  module Ims
    class ToolSettingController < ApplicationController
      include Lti::ApiServiceHelper
      include Lti::Ims::AccessTokenHelper

      rescue_from ActiveRecord::RecordNotFound do
        render json: {
          :status => I18n.t('lib.auth.api.not_found_status', 'not_found'),
          :errors => [{:message => I18n.t('lib.auth.api.not_found_message', "not_found")}]
        }, status: :not_found
      end

      TOOL_SETTINGS_SERVICE = 'ToolProxySettings'.freeze
      TOOL_PROXY_BINDING_SERVICE = 'ToolProxyBindingSettings'.freeze
      LTI_LINK_SETTINGS = 'LtiLinkSettings'.freeze

      skip_before_action :load_user
      before_action :authenticate_api_call

      SERVICE_DEFINITIONS = [
        {
          id: TOOL_SETTINGS_SERVICE,
          endpoint: 'api/lti/tool_settings/tool_proxy/{tool_proxy_id}',
          format: %w(
            application/vnd.ims.lti.v2.toolsettings+json
            application/vnd.ims.lti.v2.toolsettings.simple+json
          ).freeze,
          action: %w(GET PUT).freeze
        }.freeze,
        {
          id: TOOL_PROXY_BINDING_SERVICE,
          endpoint: 'api/lti/tool_settings/bindings/{binding_id}',
          format: %w(
            application/vnd.ims.lti.v2.toolsettings+json'
            application/vnd.ims.lti.v2.toolsettings.simple+json
          ).freeze,
          action: %w(GET PUT).freeze
        }.freeze,
        {
          id: LTI_LINK_SETTINGS,
          endpoint: 'api/lti/tool_proxy/{tool_proxy_guid}/courses/{course_id}/resource_link_id/{resource_link_id}/tool_setting',
          format: %w(
            application/vnd.ims.lti.v2.toolsettings+json
            application/vnd.ims.lti.v2.toolsettings.simple+json
          ).freeze,
          action: %w(GET PUT).freeze
        }.freeze
      ].freeze

      def show
        render_bad_request and return unless valid_show_request?
        render json: tool_setting_json(tool_setting, params[:bubble]), content_type: @content_type
      end

      def update
        json = JSON.parse(request.body.read)
        render_bad_request and return unless valid_update_request?(json)
        tool_setting.update_attribute(:custom, custom_settings(tool_setting_type(tool_setting), json))
        head :ok
      end

      def lti2_service_name
        [TOOL_SETTINGS_SERVICE, TOOL_PROXY_BINDING_SERVICE, LTI_LINK_SETTINGS]
      end

      private

      def tool_setting_json(tool_setting, bubble)
        if %w(all distinct).include?(bubble)
          graph = []
          distinct = bubble == 'distinct' ? [] : nil
          while tool_setting
            graph << collect_tool_settings(tool_setting, distinct)
            distinct |= graph.last.custom.keys if distinct
            case tool_setting_type(tool_setting)
              when 'LtiLink'
                tool_setting = ToolSetting.where(tool_proxy_id: tool_setting.tool_proxy_id, context_type: tool_setting.context_type, context_id: tool_setting.context_id, resource_link_id: nil).first
              when 'ToolProxyBinding'
                tool_setting = ToolSetting.where(tool_proxy_id: tool_setting.tool_proxy_id, context_type: nil, context_id: nil, resource_link_id: nil).first
              when 'ToolProxy'
                tool_setting = nil
            end
          end

          if request.headers['accept'].include?('application/vnd.ims.lti.v2.toolsettings+json')
            @content_type = 'application/vnd.ims.lti.v2.toolsettings+json'
            IMS::LTI::Models::ToolSettingContainer.new(graph: graph)
          elsif bubble == 'distinct' && request.headers['accept'].include?('application/vnd.ims.lti.v2.toolsettings.simple+json')
            @content_type = 'application/vnd.ims.lti.v2.toolsettings.simple+json'
            custom = {}
            graph.reverse_each { |tool_setting| custom.merge!(tool_setting.custom) }
            custom
          end
        else
          if request.headers['accept'].include?('application/vnd.ims.lti.v2.toolsettings+json')
            @content_type = 'application/vnd.ims.lti.v2.toolsettings+json'
            IMS::LTI::Models::ToolSettingContainer.new(graph: [collect_tool_settings(tool_setting)])
          else
            @content_type = 'application/vnd.ims.lti.v2.toolsettings.simple+json'
            tool_setting.custom || {}
          end
        end
      end

      def collect_tool_settings(tool_setting, distinct = nil)
        type = tool_setting_type(tool_setting)
        url = show_lti_tool_settings_url(tool_setting.id)
        custom = tool_setting.custom || {}
        custom.delete_if { |k, _| distinct.include? k } if distinct
        IMS::LTI::Models::ToolSetting.new(custom: custom, type: type, id: url)
      end

      def custom_settings(type, json)
        if request.content_type == 'application/vnd.ims.lti.v2.toolsettings+json'
          setting = json['@graph'].find { |setting| setting['@type'] == type }
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

      def authenticate_api_call
        if oauth2_request?
          begin
            validate_access_token!
          rescue Lti::Oauth2::InvalidTokenError
            render_unauthorized and return
          end
        elsif request.authorization.present?
          lti_authenticate or return
        else
          render_unauthorized and return
        end
      end

      def tool_setting
        @_tool_setting ||= begin
          tool_setting_id = params[:tool_setting_id]
          ts = if tool_setting_id.present?
            tool_proxy.tool_settings.find(tool_setting_id)
          else
            get_context
            tool_proxy_guid = params[:tool_proxy_guid]
            resource_link_id = params[:resource_link_id]
            render_unauthorized and return unless tool_proxy_guid == tool_proxy.guid
            tool_proxy.tool_settings.find_by(
              context: @context,
              resource_link_id: resource_link_id
            )
          end
          raise ActiveRecord::RecordNotFound if ts.blank?
          ts
        end
      end

      def valid_show_request?
        #TODO: register a mime type in rails for these content-types
        params[:bubble].blank? ||
          params[:bubble] == 'distinct' ||
          (params[:bubble] == 'all' && request.accept.include?('application/vnd.ims.lti.v2.toolsettings+json'))
      end

      def valid_update_request?(json)
        valid = params[:bubble].blank?
        if valid && request.content_type == 'application/vnd.ims.lti.v2.toolsettings+json'
          valid = json['@graph'].count == 1
        elsif valid && request.content_type == 'application/vnd.ims.lti.v2.toolsettings.simple+json'
          valid = !json.keys.include?('@graph')
        end
        valid
      end

      def render_bad_request
        render :json => {
                             :status => I18n.t('lib.auth.api.bad_request_status', 'bad_request'),
                             :errors => [{:message => I18n.t('lib.auth.api.bad_request_message', "bad_request")}]
                           },
               :status => :bad_request
      end

    end
  end
end
