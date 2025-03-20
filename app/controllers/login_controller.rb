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

class LoginController < ApplicationController
  include Login::Shared

  before_action :forbid_on_files_domain, except: :clear_file_session
  before_action :run_login_hooks, only: :new
  before_action :fix_ms_office_redirects, only: :new
  skip_before_action :require_reacceptance_of_terms
  before_action :require_user, only: :session_token

  def new
    if @current_user &&
       !params[:force_login] &&
       !params[:confirm] &&
       !params[:expected_user_id] &&
       !session[:used_remember_me_token]
      redirect_to dashboard_url
      return
    end

    if params[:needs_cookies] == "1"
      @needs_cookies = true
      return render "shared/unauthorized", layout: "application", status: :unauthorized
    end

    session[:expected_user_id] = params[:expected_user_id].to_i if params[:expected_user_id]
    session[:confirm] = params[:confirm] if params[:confirm]
    session[:enrollment] = params[:enrollment] if params[:enrollment]

    if @current_pseudonym
      params[:login_hint] ||= @current_pseudonym.unique_id
    end
    params[:login_hint] ||= params.dig(:pseudonym_session, :unique_id)

    # deprecated redirect; link directly to /login/canvas
    params[:authentication_provider] = "canvas" if params["canvas_login"]
    # deprecated redirect; they should already know the correct type
    params[:authentication_provider] ||= params[:id]

    redirect_to_discovery_url
    return if performed?

    if flash[:delegated_message]
      # we had an error from an SSO - we need to show it
      @headers = false
      @show_left_side = false
      @show_embedded_chat = false

      return render
    end

    if params[:authentication_provider]
      auth_type = @domain_root_account
                  .authentication_providers
                  .active
                  .find(params[:authentication_provider])
                  .auth_type
      params[:id] = params[:authentication_provider] if params[:authentication_provider] != auth_type
    end

    redirect_to_specific_provider(auth_type)
  end

  # DELETE /logout
  def destroy
    redirect = logout_current_user_for_idp
    return if performed?

    redirect_to redirect || login_url
  end

  # GET /logout
  def logout_landing
    # logged in; ask them to log out
    return render :logout_confirm if @current_user

    # not logged in at all; send them to login
    redirect_to login_url unless flash[:logged_out]
    # just barely logged out. render a landing page asking them to log in again.
    # render :logout_landing
  end

  # GET /login/session_token
  def session_token
    # must be used from API
    return render_unauthorized_action unless @access_token

    # verify that we're sending them back to a host from the same instance
    begin
      return_to = URI.parse(params[:return_to] || request.referer || root_url)
    rescue URI::InvalidURIError => e
      Canvas::Errors.capture_exception(:login, e, :info)
      return render json: { error: I18n.t("Invalid redirect URL") }, status: :bad_request
    end
    return render_unauthorized_action unless return_to.absolute?
    return render_unauthorized_action unless return_to.scheme == request.scheme

    host = return_to.host
    return render_unauthorized_action unless host.casecmp?(request.host)

    login_pseudonym = @real_current_pseudonym || @current_pseudonym
    token = SessionToken.new(login_pseudonym.global_id,
                             current_user_id: @real_current_user ? @current_user.global_id : nil,
                             used_remember_me_token: true).to_s
    return_to.query&.concat("&")
    return_to.query = "" unless return_to.query
    return_to.query.concat("session_token=#{token}")

    render json: {
      session_url: return_to.to_s,
      requires_terms_acceptance: login_pseudonym.account.require_acceptance_of_terms?(@real_current_user || @current_user)
    }
  end

  def clear_file_session
    session.delete("file_access_user_id")
    session.delete("file_access_expiration")
    session[:permissions_key] = SecureRandom.uuid

    render plain: "ok"
  end

  private

  def redirect_to_discovery_url
    if @domain_root_account.auth_discovery_url(request) && !params[:authentication_provider]
      auth_discovery_url = @domain_root_account.auth_discovery_url(request)
      if flash[:delegated_message]
        auth_discovery_url << (URI.parse(auth_discovery_url).query ? "&" : "?")
        auth_discovery_url << "message=#{URI::DEFAULT_PARSER.escape(flash[:delegated_message])}"
      end
      redirect_to auth_discovery_url, @domain_root_account.auth_discovery_url_options(request)
      increment_statsd(:discovery_redirect)
    end
  end

  def redirect_to_specific_provider(auth_type)
    auth_type ||= @domain_root_account.authentication_providers.active.first&.auth_type
    auth_type ||= "canvas"

    redirect_to url_for({ controller: "login/#{auth_type}", action: :new }
      .merge(params.permit(:id, :login_hint).to_unsafe_h))
  end

  def auth_type; end
end
