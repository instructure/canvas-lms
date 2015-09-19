#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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
  protect_from_forgery :except => [:token, :destroy]
  before_filter :run_login_hooks, :only => [:token]
  skip_before_filter :require_reacceptance_of_terms

  def auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render()
    end

    scopes = params.fetch(:scopes, '').split(',')

    provider = Canvas::Oauth::Provider.new(params[:client_id], params[:redirect_uri], scopes, params[:purpose])

    return render(:status => 400, :json => { :message => "invalid client_id" }) unless provider.has_valid_key?
    return render(:status => 400, :json => { :message => "invalid redirect_uri" }) unless provider.has_valid_redirect?
    return render(:status => 401, :json => { :message => "client not authorized for this account" }) unless provider.key.authorized_for_account?(@domain_root_account)
    session[:oauth2] = provider.session_hash
    session[:oauth2][:state] = params[:state] if params.key?(:state)

    if @current_pseudonym && !params[:force_login]
      redirect_to Canvas::Oauth::Provider.confirmation_redirect(self, provider, @current_user)
    else
      redirect_to login_url(params.slice(:canvas_login, :pseudonym_session, :force_login, :authentication_provider))
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
    redirect_params = Canvas::Oauth::Provider.final_redirect_params(session[:oauth2], @current_user, remember_access: params[:remember_access])
    redirect_to Canvas::Oauth::Provider.final_redirect(self, redirect_params)
  end

  def deny
    redirect_to Canvas::Oauth::Provider.final_redirect(self, :error => "access_denied")
  end

  def token
    basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if request.authorization

    client_id = params[:client_id].presence || basic_user
    secret = params[:client_secret].presence || basic_pass

    provider = Canvas::Oauth::Provider.new(client_id)
    return render(:status => 400, :json => { :message => "invalid client_id" }) unless provider.has_valid_key?
    return render(:status => 400, :json => { :message => "invalid client_secret" }) unless provider.is_authorized_by?(secret)

    token = provider.token_for(params[:code])
    return render(:status => 400, :json => { :message => "invalid code" }) unless token.is_for_valid_code?

    token.create_access_token_if_needed(value_to_boolean(params[:replace_tokens]))

    Canvas::Oauth::Token.expire_code(params[:code])

    render :json => token
  end

  def destroy
    logout_current_user if params[:expire_sessions]
    return render :json => { :message => "can't delete OAuth access token when not using an OAuth access token" }, :status => 400 unless @access_token
    @access_token.destroy
    render :json => {}
  end
end
