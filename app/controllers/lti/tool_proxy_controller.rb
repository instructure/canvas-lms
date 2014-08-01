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
  class ToolProxyController < ApplicationController
    before_filter :require_context, :except => [:show]
    skip_before_filter :require_user, only: [:create, :show]
    skip_before_filter :load_user, only: [:create, :show]

    def show
      tool_proxy = ToolProxy.where(guid: params['tool_proxy_guid']).first
      if tool_proxy && authorized_request?(tool_proxy.shared_secret)
        render json: tool_proxy.raw_data
      else
        render json: {error: 'unauthorized'}, status: :unauthorized
      end
    end

    def create
      secret = RegistrationRequestService.retrieve_registration_password(oauth_consumer_key)
      if authorized_request?(secret)
        tool_proxy = ToolProxyService.new.process_tool_proxy_json(request.body.read, context, oauth_consumer_key)
        json = {
          "@context" => "http://purl.imsglobal.org/ctx/lti/v2/ToolProxyId",
          "@type" => "ToolProxy",
          "@id" => nil,
          "tool_proxy_guid" => tool_proxy.guid
        }

        render json: json, status: :created
      else
        render json: {error: 'unauthorized'}, status: :unauthorized
      end
    end

    private

    def authorized_request?(secret)
      OAuth::Signature.build(request, :consumer_secret => secret).verify()
    end

    def oauth_consumer_key
      @oauth_consumer_key ||= OAuth::Helper.parse_header(authorization_header(request))['oauth_consumer_key']
    end

    def authorization_header(request)
      if CANVAS_RAILS3
        request.authorization
      else
        request.env['HTTP_AUTHORIZATION'] ||
          request.env['X-HTTP_AUTHORIZATION'] ||
          request.env['X_HTTP_AUTHORIZATION'] ||
          request.env['REDIRECT_X_HTTP_AUTHORIZATION']
      end
    end

  end
end