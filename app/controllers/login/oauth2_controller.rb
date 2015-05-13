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

class Login::Oauth2Controller < ApplicationController
  include Login::Shared

  before_filter :forbid_on_files_domain
  before_filter :run_login_hooks, :check_sa_delegated_cookie, only: :new

  def new
    auth_type = params[:controller].sub(%r{^login/}, '')
    # ActionController::TestCase can't deal with aliased controllers, so we have to
    # explicitly specify this
    auth_type = params[:auth_type] if Rails.env.test?
    scope = @domain_root_account.account_authorization_configs.where(auth_type: auth_type)
    if params[:id]
      aac = scope.find(params[:id])
    else
      aac = scope.first!
    end

    reset_session_for_login
    state = session[:oauth2_state] = SecureRandom.hex(24)
    redirect_to aac.client.auth_code.authorize_url(redirect_uri: redirect_uri(aac), state: state)
  end

  def create
    reset_session_for_login

    aac = @domain_root_account.account_authorization_configs.find(params[:id])
    raise ActiveRecord::RecordNotFound unless aac.is_a?(AccountAuthorizationConfig::Oauth2)

    check_csrf

    unique_id = nil
    begin
      default_timeout = Setting.get('oauth2_timelimit', 5.seconds.to_s).to_f

      timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }

      Canvas.timeout_protection("oauth2:#{aac.global_id}", timeout_options) do
        token = aac.get_token(params[:code], redirect_uri(aac))
        unique_id = aac.unique_id(token)
      end
    rescue => e
      Canvas::Errors.capture(e,
                             type: :oauth2_consumer,
                             aac: aac.global_id,
                             account: aac.global_account_id
                            )
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      return redirect_to login_url
    end

    pseudonym = @domain_root_account.pseudonyms.active.by_unique_id(unique_id).first
    if pseudonym
      # Successful login and we have a user
      @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
      session[:login_aac] = aac.id

      successful_login(pseudonym.user, pseudonym)
    else
      unknown_user_url = aac.unknown_user_url.presence || login_url
      logger.warn "Received OAuth2 login for unknown user: #{unique_id}, redirecting to: #{unknown_user_url}."
      flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", :user => unique_id
      redirect_to unknown_user_url
    end
  end

  protected

  def check_csrf
    if params[:state].blank? || params[:state] != session.delete(:oauth2_state)
      raise ActionController::InvalidAuthenticityToken
    end
  end

  def redirect_uri(aac)
    oauth2_login_callback_url(id: aac)
  end
end
