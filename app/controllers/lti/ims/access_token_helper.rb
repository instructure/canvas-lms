#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti::Ims::AccessTokenHelper
  def authorized_lti2_tool
    validate_access_token!
    true
  rescue Lti::Oauth2::InvalidTokenError
    render_unauthorized_action
  end

  def validate_access_token!
    access_token.validate!
    raise Lti::Oauth2::InvalidTokenError 'Developer Key is not active or available in this environment' if developer_key && !developer_key.usable?
  rescue Lti::Oauth2::InvalidTokenError
    raise
  rescue StandardError => e
    raise Lti::Oauth2::InvalidTokenError, e
  end

  def access_token
    @_access_token ||= begin
      access_token = AuthenticationMethods.access_token(request)
      access_token && Lti::Oauth2::AccessToken.from_jwt(
        aud: request.host,
        jwt: access_token
      )
    end
  end

  def oauth2_request?
    pattern = /^Bearer /
    header = request.headers["Authorization"]
    header && header.match?(pattern)
  end

  def tool_proxy
    @_tool_proxy ||= Lti::ToolProxy.find_by(guid: access_token.sub)
  end

  def validate_services!(tool_proxy)
    ims_tp = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
    service_names = [*lti2_service_name]
    service = ims_tp.security_contract.tool_services.find(
      -> {
        raise Lti::Oauth2::InvalidTokenError,
              "The ToolProxy security contract doesn't include #{service_names.join(', or ')}"
      }) do |s|
      service_names.include? s.service.split(':').last.split('#').last
    end
    unless service.actions.map(&:downcase).include? request.method.downcase
      msg = "#{s.service.split(':').last.split('#').last}.#{request.method} not included in ToolProxy security Contract"
      raise Lti::Oauth2::InvalidTokenError, msg
    end

  end

  def developer_key
    @_developer_key ||= access_token && begin
      tp = Lti::ToolProxy.find_by(guid: access_token.sub)
      if tp.present?
        raise Lti::Oauth2::InvalidTokenError, 'Tool Proxy is not active' if tp.workflow_state != 'active'
        validate_services!(tp)
        tp.product_family.developer_key
      else
        DeveloperKey.find_cached(access_token.sub)
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def lti2_service_name
    raise 'the method #lti2_service_name must be defined in the class'
  end

  def render_unauthorized
    render json: {error: 'unauthorized'}, status: :unauthorized
  end

end
