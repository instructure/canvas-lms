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
  protect_from_forgery :except => [:token, :destroy], with: :exception
  before_action :run_login_hooks, :only => [:token]
  skip_before_action :require_reacceptance_of_terms

  def auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render()
    end

    scopes = (params[:scope] || params[:scopes] || '').split(' ')

    provider = Canvas::Oauth::Provider.new(params[:client_id], params[:redirect_uri], scopes, params[:purpose])

    raise Canvas::Oauth::RequestError, :invalid_client_id unless provider.has_valid_key?
    raise Canvas::Oauth::RequestError, :invalid_redirect unless provider.has_valid_redirect?
    if developer_key_management_and_scoping_enabled? provider
      raise Canvas::Oauth::RequestError, :invalid_scope unless scopes.present? && scopes.all? { |scope| provider.key.scopes.include?(scope) }
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
        js_env :GOOGLE_ANALYTICS_KEY => Setting.get('google_analytics_key', nil)
        render :layout => 'mobile_auth', :action => 'confirm_mobile'
      end
    else
      flash[:error] = t("Must submit new OAuth2 request")
      redirect_to login_url
    end
  end

  def accept
    redirect_params = Canvas::Oauth::Provider.final_redirect_params(session[:oauth2], @current_user, logged_in_user, remember_access: params[:remember_access])
    redirect_to Canvas::Oauth::Provider.final_redirect(self, redirect_params)
  end

  def deny
    redirect_to Canvas::Oauth::Provider.final_redirect(self, :error => "access_denied")
  end

  def token
    basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if request.authorization
    client_id = params[:client_id].presence || basic_user
    secret = params[:client_secret].presence || basic_pass

    granter = if grant_type == "authorization_code"
      Canvas::Oauth::GrantTypes::AuthorizationCode.new(client_id, secret, params)
    elsif params[:grant_type] == "refresh_token"
      Canvas::Oauth::GrantTypes::RefreshToken.new(client_id, secret, params)
    else
      Canvas::Oauth::GrantTypes::BaseType.new(client_id, secret, params)
    end

    raise Canvas::Oauth::RequestError, :unsupported_grant_type unless granter.supported_type?
    render :json => granter.token
  end

  def destroy
    logout_current_user if params[:expire_sessions]
    return render :json => { :message => "can't delete OAuth access token when not using an OAuth access token" }, :status => 400 unless @access_token
    @access_token.destroy
    render :json => {}
  end

  private
  def oauth_error(exception)
    response['WWW-Authenticate'] = 'Canvas OAuth 2.0' if exception.http_status == 401
    return render(exception.to_render_data)
  end

  def grant_type
    @grant_type ||= (
      params[:grant_type] || (
        !params[:grant_type] && params[:code] ? "authorization_code" : "__UNSUPPORTED_PLACEHOLDER__"
      )
    )
  end

  def developer_key_management_and_scoping_enabled?(provider)
    (
      (
        @domain_root_account.site_admin? &&
        Setting.get(Setting::SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES, nil).present?
      ) ||
      @domain_root_account.feature_enabled?(:developer_key_management_and_scoping)
    ) &&
    provider.key.require_scopes?
  end
end
