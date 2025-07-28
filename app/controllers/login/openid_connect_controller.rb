# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class Login::OpenidConnectController < Login::OAuth2Controller
  OIDC_BACKCHANNEL_LOGOUT_EVENT_URN = "http://schemas.openid.net/event/backchannel-logout"

  protect_from_forgery except: :new, with: :exception

  def new
    Login::Shared.set_return_to_from_provider(request, session, nil, @domain_root_account, params[:target_link_uri])

    super
  end

  def destroy
    return unless (logout_token = validate_logout_token)

    @aac = validate_authentication_provider(logout_token)

    increment_statsd(:attempts)
    return unless @aac

    if (signature_error = @aac.validate_signature(logout_token))
      increment_statsd(:failure, reason: :invalid_signature)
      return render plain: "Invalid signature: #{signature_error}", status: :bad_request
    end
    unless Pseudonym.expire_oidc_session(logout_token, request)
      increment_statsd(:failure, reason: :no_session)
      return render plain: "No session found", status: :not_found
    end

    increment_statsd(:success)
    render plain: "OK", status: :ok
  end

  def validate_logout_token
    # NOT SUPPORTED without redis
    return render plain: "NOT SUPPORTED", status: :method_not_allowed unless Canvas.redis_enabled?

    jwt_string = request.request_parameters["logout_token"]

    logout_token = begin
      ::Canvas::Security.decode_jwt(jwt_string, [:skip_verification])
    rescue ::Canvas::Security::InvalidToken
      Rails.logger.warn("Failed to decode OpenID Connect back-channel logout token: #{jwt_string.inspect}")
      render plain: "Invalid logout token", status: :bad_request
      increment_statsd(:failure, reason: :invalid_token)
      nil
    end
    return unless logout_token

    unless (missing_claims = %w[aud iss iat exp events jti] - logout_token.keys).empty?
      render plain: "Missing claim#{"s" if missing_claims.length > 1} #{missing_claims.join(", ")}",
             status: :bad_request
      increment_statsd(:failure, reason: :missing_claims)
      return
    end
    unless logout_token["events"].is_a?(Hash) && logout_token["events"][OIDC_BACKCHANNEL_LOGOUT_EVENT_URN].is_a?(Hash)
      render plain: "Invalid events", status: :bad_request
      increment_statsd(:failure, reason: :invalid_events)
      return
    end
    unless logout_token["sid"] || logout_token["sub"]
      render plain: "Missing session information", status: :bad_request
      increment_statsd(:failure, reason: :missing_session)
      return
    end
    if logout_token["nonce"]
      render plain: "Nonce must not be provided", status: :bad_request
      increment_statsd(:failure, reason: :missing_nonce)
      return
    end

    duplicate_request_key = "oidc_slo_jti_#{Digest::MD5.new.update(logout_token["jti"].to_s).hexdigest}"
    unless Canvas.redis.set(duplicate_request_key, true, nx: true, exat: logout_token["exp"])
      render plain: "Received duplicate logout token", status: :bad_request
      increment_statsd(:failure, reason: :duplicate)
      return
    end

    logout_token
  end

  def validate_authentication_provider(logout_token)
    ap = @domain_root_account
         .authentication_providers
         .merge(AuthenticationProvider::OpenIDConnect.all)
         .active
         .find_by(entity_id: logout_token["aud"],
                  idp_entity_id: logout_token["iss"])
    unless ap
      render plain: "Invalid audience/issuer pair", status: :not_found
      return
    end

    ap
  end

  private

  def aac
    if params[:iss]
      @aac ||= begin
        auth_type = params[:controller].sub(%r{^login/}, "")
        @domain_root_account.authentication_providers
                            .active
                            .where(auth_type:, idp_entity_id: params[:iss])
                            .take!
      end
    end
    super
  end

  def additional_authorize_params
    result = params.permit(:login_hint)
    result[:prompt] = "login" if force_login_after_logout? || Canvas::Plugin.value_to_boolean(params[:force_login])

    result
  end

  def auth_type
    AuthenticationProvider::OpenIDConnect.sti_name
  end
end
