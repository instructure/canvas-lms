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

class OAuth2ProviderController < ApplicationController
  protect_from_forgery except: %i[token destroy], with: :exception
  before_action :run_login_hooks, only: %i[token]
  skip_before_action :require_reacceptance_of_terms, only: %i[token destroy]

  def auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render
    end

    scopes = (params[:scope] || params[:scopes] || "").split

    provider = Canvas::OAuth::Provider.new(params[:client_id], params[:redirect_uri], scopes, params[:purpose])
    begin
      raise Canvas::OAuth::RequestError, :invalid_client_id unless provider.has_valid_key?
      raise Canvas::OAuth::RequestError, :invalid_redirect unless provider.has_valid_redirect?
    rescue Canvas::OAuth::RequestError => e
      oauth_error(e)
      return
    end

    if provider.key.require_scopes? && !provider.valid_scopes?
      raise Canvas::OAuth::InvalidScopeError, provider.missing_scopes
    end

    session[:oauth2] = provider.session_hash
    session[:oauth2][:state] = params[:state] if params.key?(:state)

    unless provider.key.authorized_for_account?(@domain_root_account)
      return redirect_to Canvas::OAuth::Provider.final_redirect(self,
                                                                state: params[:state],
                                                                error: "unauthorized_client",
                                                                error_description: "Client does not have access to the specified Canvas account.")
    end

    unless params[:response_type] == "code"
      return redirect_to Canvas::OAuth::Provider.final_redirect(self,
                                                                state: params[:state],
                                                                error: "unsupported_response_type",
                                                                error_description: "Only response_type=code is permitted")
    end

    case params[:prompt]
    when nil
      # do nothing, omitting this param is fine
    when "none"
      if !logged_in_user
        return redirect_to Canvas::OAuth::Provider.final_redirect(self,
                                                                  state: params[:state],
                                                                  error: "login_required",
                                                                  error_description: "prompt=none but there is no current session")
      elsif !provider.authorized_token?(@current_user, real_user: logged_in_user)
        return redirect_to Canvas::OAuth::Provider.final_redirect(self,
                                                                  state: params[:state],
                                                                  error: "interaction_required",
                                                                  error_description: "prompt=none but a token cannot be granted without user interaction")
      else
        redirect_params = Canvas::OAuth::Provider.final_redirect_params(session[:oauth2], @current_user, logged_in_user)
        return redirect_to Canvas::OAuth::Provider.final_redirect(self, redirect_params)
      end
    else
      return redirect_to Canvas::OAuth::Provider.final_redirect(self,
                                                                state: params[:state],
                                                                error: "unsupported_prompt_type",
                                                                error_description: 'prompt must be "none" (or omitted)')
    end

    if @current_pseudonym && !params[:force_login]
      redirect_to Canvas::OAuth::Provider.confirmation_redirect(self, provider, @current_user, logged_in_user)
    else
      params["pseudonym_session"] = { "unique_id" => params[:unique_id] } if params.key?(:unique_id)
      redirect_to login_url(params.permit(:canvas_login, :force_login,
                                          :authentication_provider, pseudonym_session: :unique_id))
    end
  rescue Canvas::OAuth::RequestError => e
    Canvas::OAuth::Provider.is_oob?(params[:redirect_uri]) ? oauth_error(e) : redirect_oauth_error(e)
  end

  def confirm
    if session[:oauth2]
      @provider = Canvas::OAuth::Provider.new(session[:oauth2][:client_id], session[:oauth2][:redirect_uri], session[:oauth2][:scopes], session[:oauth2][:purpose])
      @special_confirm_message = special_confirm_message(@provider)

      if mobile_device?
        render layout: "mobile_auth", action: "confirm_mobile"
      end
    else
      flash[:error] = t("Must submit new OAuth2 request")
      redirect_to login_url
    end
  end

  def accept
    return render plain: t("Invalid or missing session for oauth"), status: :bad_request unless session[:oauth2]

    redirect_params = Canvas::OAuth::Provider.final_redirect_params(session[:oauth2], @current_user, logged_in_user, remember_access: params[:remember_access])
    redirect_to Canvas::OAuth::Provider.final_redirect(self, redirect_params)
  end

  def deny
    return render plain: t("Invalid or missing session for oauth"), status: :bad_request unless session[:oauth2]

    params = { error: "access_denied" }
    params[:state] = session[:oauth2][:state] if session[:oauth2].key? :state
    redirect_to Canvas::OAuth::Provider.final_redirect(self, params)
  end

  def token
    basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if request.authorization
    client_id = params[:client_id].presence || basic_user
    secret = params[:client_secret].presence || basic_pass

    granter = case grant_type
              when "authorization_code"
                Canvas::OAuth::GrantTypes::AuthorizationCode.new(client_id, secret, params)
              when "refresh_token"
                Canvas::OAuth::GrantTypes::RefreshToken.new(client_id, secret, params)
              when "client_credentials"
                Canvas::OAuth::GrantTypes::ClientCredentials.new(params, request.host_with_port, request.protocol)
              else
                Canvas::OAuth::GrantTypes::BaseType.new(client_id, secret, params)
              end

    raise Canvas::OAuth::RequestError, :unsupported_grant_type unless granter.supported_type?

    token = granter.token
    # make sure locales are set up
    if token.is_a?(Canvas::OAuth::Token)
      @current_user = token.user
      assign_localizer
      I18n.set_locale_with_localizer
    end

    increment_request_cost(Setting.get("oauth_token_additional_request_cost", "200").to_i)

    render json: token
  rescue Canvas::OAuth::RequestError => e
    Account.site_admin.feature_enabled?(:no_redirect_on_oauth_token_method) ? oauth_error(e) : old_silly_behavior(e)
  end

  def destroy
    if params[:expire_sessions]
      if session[:login_aac]
        # The AAC could have been deleted since the user logged in
        aac = AuthenticationProvider.where(id: session[:login_aac]).first
        redirect = aac.try(:user_logout_redirect, self, @current_user)
      end
      logout_current_user
    end
    return render json: { message: "can't delete OAuth access token when not using an OAuth access token" }, status: :bad_request unless @access_token

    @access_token.destroy
    response = {}
    response[:forward_url] = redirect if redirect
    render json: response
  end

  private

  def oauth_error(exception)
    response["WWW-Authenticate"] = "Canvas OAuth 2.0" if exception.http_status == 401
    render(exception.to_render_data)
  end

  def redirect_oauth_error(exception)
    redirect_to exception.redirect_uri(params[:redirect_uri])
  end

  # this method should be removed when the no_redirect_on_oauth_token_method flag is removed
  def old_silly_behavior(exception)
    if @should_not_redirect || Canvas::OAuth::Provider.is_oob?(params[:redirect_uri]) || params[:redirect_uri].blank?
      response["WWW-Authenticate"] = "Canvas OAuth 2.0" if exception.http_status == 401
      render(exception.to_render_data)
    else
      redirect_to exception.redirect_uri(params[:redirect_uri])
    end
  end

  def grant_type
    @grant_type ||= params[:grant_type] || (
        (!params[:grant_type] && params[:code]) ? "authorization_code" : "__UNSUPPORTED_PLACEHOLDER__"
      )
  end

  def special_confirm_message(provider)
    commons_dk_id = Setting.get("commons_developer_key_id", nil)
    if commons_dk_id.present? && commons_dk_id.to_s == provider.key.global_id.to_s
      mt "Please note: Instructure hosts Canvas Commons in the USA. This means that when you use Canvas Commons your personal data will be stored and processed in the USA. These personal data elements include: name, email address, Canvas User ID, Canvas login name, Canvas Avatar, IP Address, Canvas Commons resources favorited by you, and comments you make to any resources in Canvas Commons. You can find more information about Instructure’s privacy practices [here](%{url}).", url: "https://www.instructure.com/policies/privacy"
    end
  end
end
