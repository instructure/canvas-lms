# frozen_string_literal: true

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

class Login::OAuth2Controller < Login::OAuthBaseController
  skip_before_action :verify_authenticity_token

  rescue_from Canvas::Security::TokenExpired, with: :handle_expired_token
  rescue_from Canvas::TimeoutCutoff, with: :handle_external_timeout

  def new
    nonce = push_nonce
    jwt = Canvas::Security.create_jwt({ aac_id: aac.global_id, nonce:, host: request.host_with_port }.merge(additional_state_claims), 10.minutes.from_now)
    authorize_url = aac.generate_authorize_url(oauth2_login_callback_url, jwt, nonce:, **additional_authorize_params)

    if aac.debugging? && aac.debug_set(:nonce, nonce, overwrite: false)
      aac.debug_set(:debugging, t("Redirected to identity provider"))
      aac.debug_set(:authorize_url, authorize_url)
    end

    increment_statsd(:attempts)
    redirect_to authorize_url
  end

  def create
    return unless validate_request

    @aac = AuthenticationProvider.find(jwt["aac_id"])
    increment_statsd(:attempts)
    raise ActiveRecord::RecordNotFound unless @aac.is_a?(AuthenticationProvider::OAuth2)

    debugging = @aac.debugging? && jwt["nonce"] == @aac.debug_get(:nonce)
    if debugging
      @aac.debug_set(:debugging, t("Received callback from identity provider"))
      @aac.instance_debugging = true
    end
    timeout_protection do
      token = nil
      begin
        token = @aac.get_token(params[:code], oauth2_login_callback_url, params)
        token.options[:nonce] = jwt["nonce"]
      rescue => e
        @aac.debug_set(:get_token_response, e) if debugging
        increment_statsd(:failure, reason: :get_token)
        raise
      end
      process_token(token)
    end
  end

  private

  def process_token(token)
    unique_id = nil
    provider_attributes = nil
    begin
      unique_id = @aac.unique_id(token)
      provider_attributes = @aac.provider_attributes(token)
      @aac = @aac.try(:alternate_provider_for_token, token) || @aac
    rescue OAuthValidationError => e
      @aac.debug_set(:validation_error, e.message) if @aac.instance_debugging
      return redirect_to_unknown_user_url(e.message)
    rescue => e
      @aac.debug_set(:claims_response, e) if @aac.instance_debugging
      raise
    end

    find_pseudonym(unique_id, provider_attributes, token)
  end

  def additional_authorize_params
    {}
  end

  def additional_state_claims
    {}
  end

  def handle_expired_token
    flash[:delegated_message] = t("It took too long to login. Please try again")
    increment_statsd(:failure, reason: :stale_session)
    redirect_to login_url
  end

  def handle_external_timeout
    flash[:delegated_message] = t("A timeout occurred contacting external authentication service")
    increment_statsd(:failure, reason: :timeout)
    redirect_to login_url
    false
  end

  def validate_request
    if params[:error_description]
      flash[:delegated_message] = Sanitize.clean(params[:error_description])
      redirect_to login_url
      return false
    end

    begin
      if jwt["nonce"].blank? || jwt["nonce"] != pop_nonce
        increment_statsd(:failure, reason: :invalid_nonce)
        raise ActionController::InvalidAuthenticityToken
      end
    rescue Canvas::Security::TokenExpired
      handle_expired_token
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

  def auth_type
    "oauth2"
  end

  def push_nonce
    nonce = SecureRandom.hex(24)
    nonce_array = session[:oauth2_nonce] ||= []
    nonce_array << nonce
    nonce
  end

  def pop_nonce
    return unless (nonce_array = session[:oauth2_nonce])
    return nonce_array if nonce_array.is_a?(String)

    nonce = nonce_array.pop
    session.delete(:oauth2_nonce) if nonce_array.empty?
    nonce
  end
end
