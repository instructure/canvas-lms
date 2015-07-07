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

      before_filter :require_context, :except => [:show]
      skip_before_filter :require_user, only: [:create, :show]
      skip_before_filter :load_user, only: [:create, :show]

      rescue_from 'Lti::ToolProxyService::InvalidToolProxyError', only: :create do |exception|
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
        secret = RegistrationRequestService.retrieve_registration_password(context, oauth_consumer_key)
        if oauth_authenticated_request?(secret)
          tool_proxy = ToolProxyService.new.process_tool_proxy_json(request.body.read, context, oauth_consumer_key)
          json = {
            "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
            "@type" => "ToolProxy",
            "@id" => nil,
            "tool_proxy_guid" => tool_proxy.guid
          }
          render json: json, status: :created, content_type: 'application/vnd.ims.lti.v2.toolproxy.id+json'
        else
          render json: {error: 'unauthorized'}, status: :unauthorized
        end
      end

    end
  end
end