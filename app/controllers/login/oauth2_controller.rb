#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class Login::Oauth2Controller < Login::OauthBaseController
  def new
    super
    state = session[:oauth2_state] = SecureRandom.hex(24)
    redirect_to @aac.client.auth_code.authorize_url(redirect_uri: redirect_uri, state: state)
  end

  def create
    super
    raise ActiveRecord::RecordNotFound unless @aac.is_a?(AccountAuthorizationConfig::Oauth2)

    check_csrf

    unique_id = nil
    return unless timeout_protection do
      token = @aac.get_token(params[:code], redirect_uri)
      unique_id = @aac.unique_id(token)
    end

    find_pseudonym(unique_id)
  end

  protected

  def check_csrf
    if params[:state].blank? || params[:state] != session.delete(:oauth2_state)
      raise ActionController::InvalidAuthenticityToken
    end
  end

  def redirect_uri
    oauth2_login_callback_url(id: @aac)
  end
end
