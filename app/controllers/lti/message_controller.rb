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
      @lti_launch = Launch.new
      @lti_launch.resource_url = params[:tool_consumer_url]
      message = RegistrationRequestService.create_request(tool_consumer_profile_url, registration_return_url)
      @lti_launch.params = message.post_params
      @lti_launch.link_text = I18n.t('lti2.register_tool', 'Register Tool')
      @lti_launch.launch_type = message.launch_presentation_document_target
      render template: 'lti/framed_launch'
    end


    def basic_lti_launch_request
      if message_handler = MessageHandler.where(id: params[:lti_message_handler_id]).first
        resource_handler = message_handler.resource
        tool_proxy = resource_handler.tool_proxy
        #TODO create scoped method for query
        if ToolProxyBinding.where(tool_proxy_id: tool_proxy.id, context_id: @context.id, context_type: @context.class).count(:all) > 0
          message_service = IMS::LTI::Services::MessageService.new(tool_proxy.guid, tool_proxy.shared_secret)
          message = IMS::LTI::Models::Messages::BasicLTILaunchRequest.new(
            lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
            resource_link_id: Lti::Asset.opaque_identifier_for(@context),
            context_id: Lti::Asset.opaque_identifier_for(@context),
            tool_consumer_instance_guid: @context.root_account.lti_guid,
            launch_presentation_document_target: IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME
          )
          @lti_launch = Launch.new
          @lti_launch.resource_url = message_handler.launch_path
          @lti_launch.params = message_service.signed_params(@lti_launch.resource_url, message)
          @lti_launch.link_text = message_handler.resource.name
          @lti_launch.launch_type = message.launch_presentation_document_target

          render template: 'lti/framed_launch' and return
        end
      end
      not_found and return
    end


    private

    def tool_consumer_profile_url
      tp_id = SecureRandom.uuid
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

  end
end