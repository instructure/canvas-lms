# frozen_string_literal: true

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

module Lti
  module IMS
    class ToolProxyController < ApplicationController
      include Lti::ApiServiceHelper
      include Lti::IMS::AccessTokenHelper

      TOOL_PROXY_COLLECTION = "ToolProxy.collection"
      TOOL_PROXY_ITEM = "ToolProxy.item"

      SERVICE_DEFINITIONS = [
        {
          id: TOOL_PROXY_COLLECTION,
          endpoint: ->(context) { "api/lti/#{context.class.name.downcase}s/#{context.id}/tool_proxy" },
          format: ["application/vnd.ims.lti.v2.toolproxy+json"].freeze,
          action: ["POST"].freeze
        }.freeze,
        {
          id: TOOL_PROXY_ITEM,
          endpoint: "api/lti/tool_proxy/{tool_proxy_guid}",
          format: ["application/vnd.ims.lti.v2.toolproxy+json"].freeze,
          action: ["GET"].freeze
        }.freeze
      ].freeze

      def lti2_service_name
        [TOOL_PROXY_COLLECTION, TOOL_PROXY_ITEM]
      end

      before_action :require_context, except: [:show]
      skip_before_action :load_user, only: %i[create show re_reg]

      rescue_from Lti::Errors::InvalidToolProxyError, ::IMS::LTI::Errors::InvalidToolConsumerProfile do |exception|
        render json: exception.as_json, status: :bad_request
      end

      def show
        tool_proxy = ToolProxy.where(guid: params["tool_proxy_guid"]).first
        if tool_proxy && oauth_authenticated_request?(tool_proxy.shared_secret)
          render json: tool_proxy.raw_data, content_type: "application/vnd.ims.lti.v2.toolproxy+json"
        else
          render json: { error: "unauthorized" }, status: :unauthorized
        end
      end

      def create
        if oauth2_request?
          begin
            validate_access_token!
            reg_key = access_token.reg_key
            reg_info = RegistrationRequestService.retrieve_registration_password(context, reg_key) if reg_key
            if reg_info.present?
              render_new_tool_proxy(
                context:,
                tool_proxy_guid: reg_key,
                dev_key: developer_key,
                registration_url: reg_info[:registration_url]
              ) and return
            end
          rescue Lti::OAuth2::InvalidTokenError
            render_unauthorized and return
          end
        elsif request.authorization.present?
          secret = RegistrationRequestService.retrieve_registration_password(context, oauth_consumer_key)
          if secret.present? && oauth_authenticated_request?(secret[:reg_password])
            render_new_tool_proxy(
              context:,
              tool_proxy_guid: oauth_consumer_key,
              registration_url: secret[:registration_url]
            ) and return
          end
        end
        render_unauthorized
      end

      def re_reg
        tp = nil
        if oauth2_request?
          begin
            validate_access_token!
            tp = ToolProxy.find_by guid: access_token.sub
          rescue Lti::OAuth2::InvalidTokenError
            render_unauthorized and return
          end
        elsif request.authorization.present?
          tp = ToolProxy.find_by guid: oauth_consumer_key
          render_unauthorized and return unless oauth_authenticated_request?(tp.shared_secret)
        else
          render_unauthorized and return
        end

        unless tp_validator.valid?
          raise Lti::Errors::InvalidToolProxyError.new "Invalid Tool Proxy", tp_validator.errors.as_json
        end

        json = {
          "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
          "@type" => "ToolProxy",
          "@id" => tp.raw_data["@id"],
          "tool_proxy_guid" => tp.guid
        }

        tps = ToolProxyService.new
        tps.create_secret(::IMS::LTI::Models::ToolProxy.from_json(payload))

        tp.update_payload = {
          acknowledgement_url: request.headers["VND-IMS-CONFIRM-URL"],
          payload: JSON.parse(payload)
        }

        if (tc_half_secret = tps.tc_half_secret)
          tp.update_payload[:tc_half_shared_secret] = tc_half_secret
          json["tc_half_shared_secret"] = tc_half_secret
        end

        tp.save
        render json:, status: :created, content_type: "application/vnd.ims.lti.v2.toolproxy.id+json"
      rescue JSON::ParserError
        render json: { error: "Invalid request" }, status: :bad_request
      end

      private

      def render_new_tool_proxy(context:, tool_proxy_guid:, dev_key: nil, registration_url: nil)
        tp_service = ToolProxyService.new
        tool_proxy = tp_service.process_tool_proxy_json(
          json: request.body.read,
          context:,
          guid: tool_proxy_guid,
          developer_key: dev_key,
          registration_url:
        )
        json = {
          "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
          "@type" => "ToolProxy",
          "@id" => nil,
          "tool_proxy_guid" => tool_proxy.guid
        }
        json["tc_half_shared_secret"] = tp_service.tc_half_secret if tp_service.tc_half_secret
        render json:, status: :created, content_type: "application/vnd.ims.lti.v2.toolproxy.id+json"
      end

      def payload
        @payload ||= begin
          request.body.rewind
          request.body.read
        end
      end

      def tp_validator(tcp_uuid: nil)
        tcp_path = [@context, :tool_consumer_profile]
        tcp_url = tcp_uuid ? polymorphic_url(tcp_path, tool_consumer_profile_id: tcp_uuid) : polymorphic_url(tcp_path)
        profile = Lti::ToolConsumerProfileCreator.new(
          @context,
          tcp_url,
          tcp_uuid:,
          developer_key:
        ).create
        tp_validator = ::IMS::LTI::Services::ToolProxyValidator.new(::IMS::LTI::Models::ToolProxy.from_json(payload))
        tp_validator.tool_consumer_profile = profile
        tp_validator
      end
    end
  end
end
