#
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
require 'ims/lti'

module Lti
  class MessageController < ApplicationController

    before_action :require_context

    def registration
      if authorized_action(@context, @current_user, :update)
        @lti_launch = Launch.new
        @lti_launch.resource_url = params[:tool_consumer_url]
        message = RegistrationRequestService.create_request(
          @context,
          polymorphic_url([@context, :tool_consumer_profile]),
          -> { polymorphic_url([@context, :registration_return]) }
        )

        @lti_launch.params = message.post_params
        @lti_launch.params['ext_tool_consumer_instance_guid'] = @context.root_account.lti_guid
        @lti_launch.params['ext_api_domain'] = HostUrl.context_host(@context, request.host)
        @lti_launch.link_text = I18n.t('lti2.register_tool', 'Register Tool')
        @lti_launch.launch_type = message.launch_presentation_document_target

        render Lti::AppUtil.display_template('borderless')
      end
    end

    def reregistration
      if authorized_action(@context, @current_user, :update)
        if (tp = ToolProxy.find(params['tool_proxy_id']))
          mh = tp.reregistration_message_handler
          return not_found unless mh.present?

          message = reregistration_message(mh, tp)
          @lti_launch = Launch.new
          @lti_launch.resource_url = message.launch_url
          @lti_launch.link_text = mh.resource_handler.name
          @lti_launch.launch_type = message.launch_presentation_document_target
          @lti_launch.params = message.signed_post_params(tp.shared_secret)
          render Lti::AppUtil.display_template('borderless') and return
        end
      end
      not_found
    end

    def reregistration_message(mh, tp)
      IMS::LTI::Models::Messages::ToolProxyReregistrationRequest.new(
        launch_url: mh.launch_path,
        oauth_consumer_key: tp.guid,
        lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P1,
        tc_profile_url: polymorphic_url([@context, :tool_consumer_profile]),
        launch_presentation_return_url: polymorphic_url([@context, :registration_return]),
        launch_presentation_document_target: IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME
      )
    end
    private :reregistration_message


    def basic_lti_launch_request
      if (message_handler = MessageHandler.find(params[:message_handler_id]))
        resource_handler = message_handler.resource_handler
        tool_proxy = resource_handler.tool_proxy
        # TODO: create scope for query
        if tool_proxy.workflow_state == 'active'
          launch_params = {
            launch_url: message_handler.launch_path,
            oauth_consumer_key: tool_proxy.guid,
            lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
            resource_link_id: build_resource_link_id(message_handler),
          }

          if params[:secure_params].present?
            secure_params = Canvas::Security.decode_jwt(params[:secure_params])
            launch_params.merge!({ext_lti_assignment_id: secure_params[:lti_assignment_id]}) if secure_params[:lti_assignment_id].present?
          end

          @lti_launch = Launch.new
          tag = find_tag
          custom_param_opts = prep_tool_settings(message_handler.parameters, tool_proxy, launch_params[:resource_link_id])
          custom_param_opts[:content_tag] = tag if tag

          variable_expander = create_variable_expander(custom_param_opts.merge(tool: tool_proxy))
          launch_params.merge! enabled_parameters(tool_proxy, message_handler, variable_expander)

          message = IMS::LTI::Models::Messages::BasicLTILaunchRequest.new(launch_params)
          message.user_id = Lti::Asset.opaque_identifier_for(@current_user) if @current_user
          @active_tab = message_handler.asset_string
          @lti_launch.resource_url = message.launch_url
          @lti_launch.link_text = resource_handler.name
          @lti_launch.launch_type = message.launch_presentation_document_target

          module_sequence(tag) if tag

          message.add_custom_params(custom_params(message_handler.parameters, variable_expander))
          message.add_custom_params(ToolSetting.custom_settings(tool_proxy.id, @context, message.resource_link_id))
          @lti_launch.params = message.signed_post_params(tool_proxy.shared_secret)

          render Lti::AppUtil.display_template(display_override: params[:display]) and return
        end
      end
      not_found
    end

    def registration_return
      @tool = ToolProxy.where(guid: params[:tool_proxy_guid]).first
      @data = {
          subject: 'lti.lti2Registration',
          status: params[:status],
          app_id: @tool.id,
          name: @tool.name,
          description: @tool.description,
          message: params[:lti_errormsg] || params[:lti_msg]
      }
      render layout: false
    end

    private

    def enabled_parameters(tp, mh, variable_expander)
      tool_proxy = IMS::LTI::Models::ToolProxy.from_json(tp.raw_data)
      enabled_capability = tool_proxy.enabled_capabilities
      enabled_capability = enabled_capability.concat(mh.capabilities).uniq if mh.capabilities.present?
      CapabilitiesHelper.capability_params_hash(enabled_capability, variable_expander)
    end

    def module_sequence(tag)
      env_hash = {}
      tag = @context.context_module_tags.not_deleted.find(params[:module_item_id])
      @lti_launch.launch_type = 'window' if tag.new_tab
      tag.context_module_action(@current_user, :read)
      sequence_asset = tag.try(:content)
      if sequence_asset
        env_hash[:SEQUENCE] = {
            :ASSET_ID => sequence_asset.id,
            :COURSE_ID => @context.id,
        }
        js_hash = {:LTI => env_hash}
        js_env(js_hash)
      end
    end

    def custom_params(parameters, variable_expander)
      params = IMS::LTI::Models::Parameter.from_json(parameters || [])
      IMS::LTI::Models::Parameter.process_params(params, variable_expander)
    end

    def find_binding(tool_proxy)
      if @context.is_a?(Course)
        tp_binding = ToolProxyBinding.where(context_type: 'Course', context: @context.id, tool_proxy_id: tool_proxy.id)
        return tp_binding if tp_binding
      end
      account_ids = @context.account_chain.map(&:id)
      bindings = ToolProxyBinding.where(context_type: 'Account', context_id: account_ids, tool_proxy_id: tool_proxy.id)
      binding_lookup = bindings.each_with_object({}) { |binding, hash| hash[binding.context_id] = binding }
      sorted_bindings = account_ids.map { |account_id| binding_lookup[account_id] }
      sorted_bindings.first
    end

    def build_resource_link_id(message_handler)
      resource_link_id = "#{@context.class}_#{@context.global_id},MessageHandler_#{message_handler.global_id}"
      resource_link_id += ",#{params[:resource_link_fragment]}" if params[:resource_link_fragment]
      Canvas::Security.hmac_sha1(resource_link_id)
    end

    def create_variable_expander(opts = {})
      default_opts = {
          current_user: @current_user,
          current_pseudonym: @current_pseudonym,
          assignment: nil
      }
      VariableExpander.new(@domain_root_account, @context, self, default_opts.merge(opts))
    end

    def prep_tool_settings(parameters, tool_proxy, resource_link_id)
      params = %w( LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url )
      if parameters && (parameters.map { |p| p['variable'] }.compact & params).any?
        link = ToolSetting.where(
          tool_proxy_id: tool_proxy.id,
          context_id: @context.id,
          context_type: @context.class.name,
          resource_link_id: resource_link_id
        ).first_or_create

        binding = ToolSetting.where(
          tool_proxy_id: tool_proxy.id,
          context_id: @context.id,
          context_type: @context.class.name,
          resource_link_id: nil
        ).first_or_create

        proxy = ToolSetting.where(
          tool_proxy_id: tool_proxy.id,
          context_id: nil,
          context_type: nil,
          resource_link_id: nil
        ).first_or_create

        {
            tool_setting_link_id: link.id,
            tool_setting_binding_id: binding.id,
            tool_setting_proxy_id: proxy.id
        }
      else
        {}
      end
    end

    def find_tag
      @context.context_module_tags.not_deleted.where(id: params[:module_item_id]).first if params[:module_item_id]
    end

  end
end
