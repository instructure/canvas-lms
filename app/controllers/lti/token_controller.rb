# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Lti::TokenController < ApplicationController
  include SupportHelpers::ControllerHelpers

  before_action :require_site_admin
  before_action :verify_1_3_tool, except: :lti_2_token

  # site-admin-only action to get an LTI 1.3 Access Token for any ContextExternalTool
  # specified by `tool_id`, or for any DeveloperKey specified by `client_id`.
  # Tool and key must use LTI 1.3, or this will error. Access token will have all LTI scopes.
  # Why advantage_access_token? LTI Advantage is the suite of grade passback
  # and other communication services for 1.3 tools, and is the main use case for these tokens.
  def advantage_access_token
    provider = Canvas::OAuth::SiteAdminClientCredentialsProvider.new(
      key.global_id,
      request.host_with_port,
      TokenScopes::LTI_SCOPES.keys,
      @current_user,
      request.protocol
    )
    render json: provider.generate_token
  end

  def lti_2_token
    unless tool_proxy
      return render json: {
                      status: :bad_request,
                      errors: [{ message: "Unable to find tool for given parameters" }]
                    },
                    status: :bad_request
    end
    token = Lti::OAuth2::AccessToken.create_jwt(aud: request.host, sub: tool_proxy.guid)
    render plain: token.to_s
  end

  private

  def verify_1_3_tool
    return if key&.is_lti_key

    render json: {
             status: :bad_request,
             errors: [{ message: "Tool/Developer Key must be for LTI 1.3 tool" }]
           },
           status: :bad_request
  end

  def key
    @key ||= if params[:client_id]
               DeveloperKey.find params.require(:client_id)
             else
               ContextExternalTool.find(params.require(:tool_id)).developer_key
             end
  end

  def tool_proxy
    @tool_proxy ||= if params[:basic_launch_lti2_id]
                      Lti::MessageHandler.find(params.require(:basic_launch_lti2_id)).tool_proxy
                    else
                      Lti::ToolProxy.find params.require(:tool_proxy_id)
                    end
  end
end
