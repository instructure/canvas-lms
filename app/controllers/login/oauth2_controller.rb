#
# Copyright (C) 2015 - present Instructure, Inc.
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
    nonce = session[:oauth2_nonce] = SecureRandom.hex(24)
    expiry = Time.zone.now + Setting.get('oauth2_client_timeout', 10.minutes.to_i).to_i
    jwt = Canvas::Security.create_jwt({ aac_id: @aac.global_id, nonce: nonce, host: request.host_with_port }, expiry)
    authorize_url = @aac.generate_authorize_url(oauth2_login_callback_url, jwt)

    if @aac.debugging? && @aac.debug_set(:nonce, nonce, overwrite: false)
      @aac.debug_set(:debugging, t("Redirected to identity provider"))
      @aac.debug_set(:authorize_url, authorize_url)
    end

    redirect_to delegated_auth_redirect_uri(authorize_url)
  end

  def create
    return unless validate_request

    @aac = AuthenticationProvider.find(jwt['aac_id'])
    raise ActiveRecord::RecordNotFound unless @aac.is_a?(AuthenticationProvider::Oauth2)
    debugging = @aac.debugging? && jwt['nonce'] == @aac.debug_get(:nonce)
    if debugging
      @aac.debug_set(:debugging, t("Received callback from identity provider"))
      @aac.instance_debugging = true
    end

    unique_id = nil
    provider_attributes = {}
    return unless timeout_protection do
      begin
        token = @aac.get_token(params[:code], oauth2_login_callback_url)
      rescue => e
        @aac.debug_set(:get_token_response, e) if debugging
        raise
      end
      begin
        unique_id = @aac.unique_id(token)
        provider_attributes = @aac.provider_attributes(token)
      rescue => e
        @aac.debug_set(:claims_response, e) if debugging
        raise
      end
    end

    find_pseudonym(unique_id, provider_attributes)
  end

  protected

  def validate_request
    if params[:error_description]
      flash[:delegated_message] = Sanitize.clean(params[:error_description])
      redirect_to login_url
      return false
    end

    begin
      if jwt['nonce'].blank? || jwt['nonce'] != session.delete(:oauth2_nonce)
        raise ActionController::InvalidAuthenticityToken
      end
    rescue Canvas::Security::TokenExpired
      flash[:delegated_message] = t("It took too long to login. Please try again")
      redirect_to login_url
      return false
    end

    reset_session_for_login
    true
  end

  def jwt
    @jwt ||= if params[:state].present?
               Canvas::Security.decode_jwt(params[:state])
             else
               {}
             end
  end
end
