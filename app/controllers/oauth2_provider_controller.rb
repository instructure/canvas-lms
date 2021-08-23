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

class Oauth2ProviderController < ApplicationController

  rescue_from Canvas::Oauth::RequestError, with: :oauth_error
  protect_from_forgery except: %i[token destroy], with: :exception
  before_action :run_login_hooks, only: %i[token]
  skip_before_action :require_reacceptance_of_terms, only: %i[token destroy]

  def auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render()
    end

    scopes = (params[:scope] || params[:scopes] || '').split(' ')

    provider = Canvas::Oauth::Provider.new(params[:client_id], params[:redirect_uri], scopes, params[:purpose])
    unless provider.has_valid_key?
      @should_not_redirect = true
      raise Canvas::Oauth::RequestError, :invalid_client_id
    end

    unless provider.has_valid_redirect?
      @should_not_redirect = true
      raise Canvas::Oauth::RequestError, :invalid_redirect
    end

    if provider.key.require_scopes?
      raise Canvas::Oauth::InvalidScopeError, provider.missing_scopes unless provider.valid_scopes?
    end

    session[:oauth2] = provider.session_hash
    session[:oauth2][:state] = params[:state] if params.key?(:state)

    unless provider.key.authorized_for_account?(@domain_root_account)
      return redirect_to Canvas::Oauth::Provider.final_redirect(self,
        error: "unauthorized_client",
        error_description: "Client does not have access to the specified Canvas account.")
    end

    unless params[:response_type] == 'code'
      return redirect_to Canvas::Oauth::Provider.final_redirect(self,
        error: "unsupported_response_type",
        error_description: "Only response_type=code is permitted")
    end

    case params[:prompt]
    when nil
      # do nothing, omitting this param is fine
    when 'none'
      if !logged_in_user
        return redirect_to Canvas::Oauth::Provider.final_redirect(self,
          error: 'login_required',
          error_description: 'prompt=none but there is no current session')
      elsif !provider.authorized_token?(@current_user, real_user: logged_in_user)
        return redirect_to Canvas::Oauth::Provider.final_redirect(self,
          error: 'interaction_required',
          error_description: 'prompt=none but a token cannot be granted without user interaction')
      else
        redirect_params = Canvas::Oauth::Provider.final_redirect_params(session[:oauth2], @current_user, logged_in_user)
        return redirect_to Canvas::Oauth::Provider.final_redirect(self, redirect_params)
      end
    else
      return redirect_to Canvas::Oauth::Provider.final_redirect(self,
        error: 'unsupported_prompt_type',
        error_description: 'prompt must be "none" (or omitted)')
    end

    if @current_pseudonym && !params[:force_login]
      redirect_to Canvas::Oauth::Provider.confirmation_redirect(self, provider, @current_user, logged_in_user)
    else
      params["pseudonym_session"] = {"unique_id" => params[:unique_id]} if params.key?(:unique_id)
      redirect_to login_url(params.permit(:canvas_login, :force_login,
                                          :authentication_provider, pseudonym_session: :unique_id))
    end
  end

  def confirm
    if session[:oauth2]
      @provider = Canvas::Oauth::Provider.new(session[:oauth2][:client_id], session[:oauth2][:redirect_uri], session[:oauth2][:scopes], session[:oauth2][:purpose])

      if mobile_device?
        render :layout => 'mobile_auth', :action => 'confirm_mobile'
      end
    else
      flash[:error] = t("Must submit new OAuth2 request")
      redirect_to login_url
    end
  end

  def accept
    return render plain: t("Invalid or missing session for oauth"), status: 400 unless session[:oauth2]
    redirect_params = Canvas::Oauth::Provider.final_redirect_params(session[:oauth2], @current_user, logged_in_user, remember_access: params[:remember_access])
    redirect_to Canvas::Oauth::Provider.final_redirect(self, redirect_params)
  end

  def deny
    return render plain: t("Invalid or missing session for oauth"), status: 400 unless session[:oauth2]
    params = { error: "access_denied" }
    params[:state] = session[:oauth2][:state] if session[:oauth2].key? :state
    redirect_to Canvas::Oauth::Provider.final_redirect(self, params)
  end

  def token
    basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if request.authorization
    client_id = params[:client_id].presence || basic_user
    secret = params[:client_secret].presence || basic_pass

    granter = if grant_type == "authorization_code"
      Canvas::Oauth::GrantTypes::AuthorizationCode.new(client_id, secret, params)
    elsif grant_type == "refresh_token"
      Canvas::Oauth::GrantTypes::RefreshToken.new(client_id, secret, params)
    elsif grant_type == 'client_credentials'
      Canvas::Oauth::GrantTypes::ClientCredentials.new(params, request.host_with_port, request.protocol)
    else
      Canvas::Oauth::GrantTypes::BaseType.new(client_id, secret, params)
    end

    raise Canvas::Oauth::RequestError, :unsupported_grant_type unless granter.supported_type?

    token = granter.token
    # make sure locales are set up
    if token.is_a?(Canvas::Oauth::Token)
      @current_user = token.user
      assign_localizer
      I18n.set_locale_with_localizer
    end

    increment_request_cost(Setting.get("oauth_token_additional_request_cost", "200").to_i)

    render :json => token
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
    return render :json => { :message => "can't delete OAuth access token when not using an OAuth access token" }, :status => 400 unless @access_token
    @access_token.destroy
    response = {}
    response[:forward_url] = redirect if redirect
    render json: response
  end

  def jwks
    keys = Canvas::Oauth::KeyStorage.public_keyset
    response.set_header('Cache-Control', "max-age=#{Canvas::Oauth::KeyStorage.max_cache_age}")
    render json: { keys: keys }
  end

  private
  def oauth_error(exception)
    if @should_not_redirect || params[:redirect_uri] == Canvas::Oauth::Provider::OAUTH2_OOB_URI || params[:redirect_uri].blank?
      response['WWW-Authenticate'] = 'Canvas OAuth 2.0' if exception.http_status == 401
      return render(exception.to_render_data)
    else
      redirect_to exception.redirect_uri(params[:redirect_uri])
    end
  end

  def grant_type
    @grant_type ||= (
      params[:grant_type] || (
        !params[:grant_type] && params[:code] ? "authorization_code" : "__UNSUPPORTED_PLACEHOLDER__"
      )
    )
  end
end
