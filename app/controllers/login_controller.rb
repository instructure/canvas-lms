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

require 'securerandom'

class LoginController < ApplicationController
  include Login::Shared

  before_filter :forbid_on_files_domain, except: :clear_file_session
  before_filter :run_login_hooks, only: :new
  before_filter :check_sa_delegated_cookie, only: [:new]
  skip_before_filter :require_reacceptance_of_terms

  def new
    if @current_user &&
        !params[:force_login] &&
        !params[:confirm] &&
        !params[:expected_user_id] &&
        !session[:used_remember_me_token]
      redirect_to dashboard_url
      return
    end

    if params[:needs_cookies] == '1'
      @needs_cookies = true
      return render 'shared/unauthorized', :layout => 'application', :status => :unauthorized
    end

    session[:expected_user_id] = params[:expected_user_id].to_i if params[:expected_user_id]
    session[:confirm] = params[:confirm] if params[:confirm]
    session[:enrollment] = params[:enrollment] if params[:enrollment]

    if @current_pseudonym
      params[:pseudonym_session] ||= {}
      params[:pseudonym_session][:unique_id] ||= @current_pseudonym.unique_id
    end

    # deprecated redirect; link directly to /login/canvas
    params[:authentication_provider] = 'canvas' if params['canvas_login']
    # deprecated redirect; they should already know the correct type
    params[:authentication_provider] ||= params[:id]

    if @domain_root_account.auth_discovery_url && !params[:authentication_provider]
      auth_discovery_url = @domain_root_account.auth_discovery_url
      if flash[:delegated_message]
        auth_discovery_url << (URI.parse(auth_discovery_url).query ? '&' : '?')
        auth_discovery_url << "message=#{URI.escape(flash[:delegated_message])}"
      end
      return redirect_to auth_discovery_url
    end

    if params[:authentication_provider]
      if params[:authentication_provider] == 'canvas'
        # canvas isn't an actual type, so we have to _not_ look for it
        auth_type = 'canvas'
      else
        auth_type = @domain_root_account.
          authentication_providers.
          active.
          find(params[:authentication_provider]).
          auth_type
      end
    else
      auth_type = @domain_root_account.authentication_providers.active.first.try(:auth_type)
      auth_type ||= 'canvas'
    end

    unless flash[:delegated_message]
      return redirect_to url_for({ controller: "login/#{auth_type}", action: :new }.merge(params.slice(:id)))
    end

    # we had an error from an SSO - we need to show it
    @headers = false
    @show_left_side = false
    @show_embedded_chat = false
  end

  # DELETE /logout
  def destroy
    if @domain_root_account == Account.site_admin && cookies['canvas_sa_delegated']
      cookies.delete('canvas_sa_delegated',
                     domain: remember_me_cookie_domain,
                     httponly: true,
                     secure: CanvasRails::Application.config.session_options[:secure])
    end

    if session[:login_aac]
      # The AAC could have been deleted since the user logged in
      aac = AccountAuthorizationConfig.where(id: session[:login_aac]).first
      if aac && aac.respond_to?(:user_logout_redirect)
        redirect = aac.user_logout_redirect(self, @current_user)
      end
    end

    redirect ||= login_url
    logout_current_user

    flash[:logged_out] = true
    redirect_to redirect
  end

  # GET /logout
  def logout_confirm
    redirect_to login_url unless @current_user
  end

  def clear_file_session
    session.delete('file_access_user_id')
    session.delete('file_access_expiration')
    session[:permissions_key] = SecureRandom.uuid

    render :text => "ok"
  end
end
