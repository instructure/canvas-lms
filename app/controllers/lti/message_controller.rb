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

module Lti
  class MessageController < ApplicationController
    before_filter :require_context

    def registration
      if authorized_action(@context, @current_user, :update)
        @lti_launch = Launch.new
        @lti_launch.resource_url = params[:tool_consumer_url]
        message = RegistrationRequestService.create_request(tool_consumer_profile_url, registration_return_url)
        @lti_launch.params = message.post_params
        @lti_launch.link_text = I18n.t('lti2.register_tool', 'Register Tool')
        @lti_launch.launch_type = message.launch_presentation_document_target

        render template: 'lti/framed_launch'
      end
    end


    def basic_lti_launch_request
      if message_handler = MessageHandler.find(params[:message_handler_id])
        resource_handler = message_handler.resource_handler
        tool_proxy = resource_handler.tool_proxy
        #TODO create scope for query
        if tool_proxy.workflow_state == 'active'
          message = IMS::LTI::Models::Messages::BasicLTILaunchRequest.new(
            launch_url: message_handler.launch_path,
            oauth_consumer_key: tool_proxy.guid,
            lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
            resource_link_id: build_resource_link_id(tool_proxy),
            context_id: Lti::Asset.opaque_identifier_for(@context),
            tool_consumer_instance_guid: @context.root_account.lti_guid,
            launch_presentation_locale: I18n.locale || I18n.default_locale.to_s,
            roles: Lti::SubstitutionsHelper.new(@context, @domain_root_account, @current_user).all_roles('lis2'),
            launch_presentation_document_target: IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME
          )
          message.user_id = Lti::Asset.opaque_identifier_for(@current_user) if @current_user
          @active_tab = message_handler.asset_string
          @lti_launch = Launch.new
          @lti_launch.resource_url = message.launch_url
          @lti_launch.link_text = resource_handler.name
          @lti_launch.launch_type = message.launch_presentation_document_target

          module_sequence(message_handler)
          message.add_custom_params(custom_params(message_handler.parameters, tool_proxy, message.resource_link_id))

          @lti_launch.params = message.signed_post_params(tool_proxy.shared_secret)

          render template: 'lti/framed_launch' and return
        end
      end
      not_found
    end

    private

    def module_sequence(message_handler)
      env_hash = {}
      if params[:module_item_id]
        @tag = ContextModuleItem.find_tag_with_preferred([message_handler], params[:module_item_id])
        @lti_launch.launch_type = 'window' if @tag.new_tab
        @tag.context_module_action(@current_user, :read)
        sequence_asset = @tag.try(:content)
        if sequence_asset
          env_hash[:SEQUENCE] = {
            :ASSET_ID => sequence_asset.id,
            :COURSE_ID => @context.id,
          }
          js_hash = {:LTI => env_hash}
          js_env(js_hash)
        end
      end
    end

    def custom_params(parameters, tool_proxy, resource_link_id)
      params = IMS::LTI::Models::Parameter.from_json(parameters || [])
      IMS::LTI::Models::Parameter.process_params(params, lti2_variable_substitutions(parameters, tool_proxy, resource_link_id))
    end

    def tool_consumer_profile_url
      tp_id = "339b6700-e4cb-47c5-a54f-3ee0064921a9" #Hard coded until we start persisting the tcp
      case context
        when Course
          course_tool_consumer_profile_url(context, tp_id)
        when Account
          account_tool_consumer_profile_url(context, tp_id)
        else
          raise "Unsupported context"
      end
    end

    def registration_return_url
      case context
        when Course
          course_settings_url(context)
        when Account
          account_settings_url(context)
        else
          raise "Unsupported context"
      end
    end

    def find_binding(tool_proxy)
      if @context.is_a?(Course)
        binding = ToolProxyBinding.where(context_type: 'Course', context: @context.id, tool_proxy_id: tool_proxy.id)
        return binding if binding
      end
      account_ids = @context.account_chain.map { |a| a.id }
      bindings = ToolProxyBinding.where(context_type: 'Account', context_id: account_ids, tool_proxy_id: tool_proxy.id)
      binding_lookup = bindings.each_with_object({}) { |binding, hash| hash[binding.context_id] = binding }
      sorted_bindings = account_ids.map { |account_id| binding_lookup[account_id] }
      sorted_bindings.first
    end

    def build_resource_link_id(message_handler, postfix = nil)
      resource_link_id = "#{params[:tool_launch_context]}_#{message_handler.id}"
      resource_link_id += "_#{params[:postfix_id]}" if params[:postfix_id]
      Base64.urlsafe_encode64("#{resource_link_id}")
    end

    def lti2_variable_substitutions(parameters, tool_proxy, resource_link_id)
      substitutions = common_variable_substitutions.inject({}) { |hash, (k, v)| hash[k.gsub(/\A\$/, '')] = v; hash }
      substitutions.merge!(prep_tool_settings(parameters, tool_proxy, resource_link_id))
      if @tag
        substitutions.merge!(
            {
                'Canvas.module.id' => @tag.context_module_id,
                'Canvas.moduleItem.id' => @tag.id,
            }
        )
      end
      substitutions
    end

    def prep_tool_settings(parameters, tool_proxy, resource_link_id)
      if parameters && (parameters.map {|p| p['variable']}.compact & (%w( LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url ))).any?
        link = ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: @context.id, context_type: @context.class.name, resource_link_id: resource_link_id).first_or_create
        binding = ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: @context.id, context_type: @context.class.name, resource_link_id: nil).first_or_create
        proxy = ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: nil, resource_link_id: nil).first_or_create
        {
          'LtiLink.custom.url' => show_lti_tool_settings_url(link.id),
          'ToolProxyBinding.custom.url' => show_lti_tool_settings_url(binding.id),
          'ToolProxy.custom.url' => show_lti_tool_settings_url(proxy.id)
        }
      else
        {}
      end
    end

  end
end
