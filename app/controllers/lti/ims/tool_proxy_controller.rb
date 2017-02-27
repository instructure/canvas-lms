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
    class ToolProxyController < ApplicationController
      include Lti::ApiServiceHelper
      include Lti::Ims::AccessTokenHelper

      before_action :require_context, :except => [:show]
      skip_before_action :require_user, only: [:create, :show, :re_reg]
      skip_before_action :load_user, only: [:create, :show, :re_reg]

      rescue_from 'Lti::ToolProxyService::InvalidToolProxyError', only: [:create, :re_reg] do |exception|
        render json: {error: exception.message}, status: 400
      end

      def show
        tool_proxy = ToolProxy.where(guid: params['tool_proxy_guid']).first
        if tool_proxy && oauth_authenticated_request?(tool_proxy.shared_secret)
          render json: tool_proxy.raw_data, content_type: 'application/vnd.ims.lti.v2.toolproxy+json'
        else
          render json: {error: 'unauthorized'}, status: :unauthorized
        end
      end

      def create
        if oauth2_request?
          dev_key = DeveloperKey.find_cached(access_token.sub)
          render_new_tool_proxy(context, SecureRandom.uuid, dev_key) and return if authorized_lti2_tool
        else
          tool_proxy_guid = oauth_consumer_key
          secret = RegistrationRequestService.retrieve_registration_password(context, oauth_consumer_key)
          render_new_tool_proxy(context, SecureRandom.uuid) and return if secret.present? && oauth_authenticated_request?(secret)
        end

        render json: {error: 'unauthorized'}, status: :unauthorized
      end

      def re_reg
        tp = ToolProxy.where(guid: oauth_consumer_key).first

        unless oauth_authenticated_request?(tp.shared_secret)
          return render(json: {error: 'unauthorized'}, status: :unauthorized)
        end

        unless tp_validator.valid?
          raise Lti::ToolProxyService::InvalidToolProxyError.new "Invalid Tool Proxy", tp_validator.errors.to_json
        end

        json = {
            "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
            "@type" => "ToolProxy",
            "@id" => tp.raw_data["@id"],
            "tool_proxy_guid" => tp.guid
        }

        tps = ToolProxyService.new
        tps.create_secret(IMS::LTI::Models::ToolProxy.from_json(payload))

        tp.update_payload = {
          acknowledgement_url: request.headers["VND-IMS-CONFIRM-URL"],
          payload: JSON.parse(payload)
        }

        if (tc_half_secret = tps.tc_half_secret)
          tp.update_payload[:tc_half_shared_secret] = tc_half_secret
          json["tc_half_shared_secret"] = tc_half_secret
        end

        tp.save
        render json: json
      rescue JSON::ParserError
        render json: {error: 'Invalid request'}, status: 400
      end

      private

      def render_new_tool_proxy(context, tool_proxy_guid, dev_key = nil)
        tp_service = ToolProxyService.new
        tool_proxy = tp_service.process_tool_proxy_json(
          json: request.body.read,
          context: context,
          guid: tool_proxy_guid,
          developer_key: dev_key
        )
        json = {
          "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
          "@type" => "ToolProxy",
          "@id" => nil,
          "tool_proxy_guid" => tool_proxy.guid
        }
        json["tc_half_shared_secret"] = tp_service.tc_half_secret if tp_service.tc_half_secret
        render json: json, status: :created, content_type: 'application/vnd.ims.lti.v2.toolproxy.id+json'
      end

      def payload
        @payload ||= (
          request.body.rewind
          request.body.read
        )
      end

      def tp_validator
        @tp_validator ||= (
          tcp_url = polymorphic_url([@context, :tool_consumer_profile],
                                    tool_consumer_profile_id: Lti::ToolConsumerProfileCreator::TCP_UUID)
          profile = Lti::ToolConsumerProfileCreator.new(@context, tcp_url).create

          tp_validator = IMS::LTI::Services::ToolProxyValidator.new(IMS::LTI::Models::ToolProxy.from_json(payload))
          tp_validator.tool_consumer_profile = profile
          tp_validator
        )
      end
    end
  end
end
