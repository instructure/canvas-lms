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

class Login::CanvasController < ApplicationController
  include Login::Shared

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, only: [:new, :create]
  before_action :fix_ms_office_redirects, only: :new

  protect_from_forgery except: :create, with: :exception

  def new
    @pseudonym_session = PseudonymSession.new
    @headers = false
    flash.now[:error] = params[:message] if params[:message]

    maybe_render_mobile_login
  end

  def create
    # Check referer and authenticity token.  If the token is invalid but the referer is trusted
    # and one is not provided then continue.  If the referer is trusted and they provide a token
    # we still want to check it.
    if params.key?(request_forgery_protection_token) || !@domain_root_account.trusted_referer?(request.referer)
      begin
        verify_authenticity_token
      rescue ActionController::InvalidAuthenticityToken
        return unsuccessful_login(t("Invalid Authenticity Token"))
      end
    end

    # reset the session id cookie to prevent session fixation.
    reset_session_for_login

    if params[:pseudonym_session].blank? || params[:pseudonym_session][:password].blank?
      return unsuccessful_login(t("No password was given"))
    end

    # strip leading and trailing whitespace off the entered unique id. some
    # mobile clients (e.g. android) will add a space after the login when using
    # autocomplete. this would prevent us from recognizing someone's username,
    # making them unable to login.
    params[:pseudonym_session][:unique_id].try(:strip!)

    # Try to use authlogic's built-in login approach first
    @pseudonym_session = @domain_root_account.pseudonym_sessions.new(params[:pseudonym_session].permit(:unique_id, :password, :remember_me).to_h)
    @pseudonym_session.remote_ip = request.remote_ip
    found = @pseudonym_session.save

    # look for LDAP pseudonyms where we get the unique_id back from LDAP, or if we're doing JIT provisioning
    if !found && !@pseudonym_session.attempted_record
      found = @domain_root_account.authentication_providers.active.where(auth_type: 'ldap').any? do |aac|
        next unless aac.identifier_format.present? || aac.jit_provisioning?

        res = aac.ldap_bind_result(params[:pseudonym_session][:unique_id], params[:pseudonym_session][:password])
        next unless res
        unique_id = if aac.identifier_format.present?
                      res.first[aac.identifier_format].first
                    else
                      params[:pseudonym_session][:unique_id]
                    end
        next unless unique_id

        pseudonym = @domain_root_account.pseudonyms.active.by_unique_id(unique_id).first
        pseudonym ||= aac.provision_user(unique_id) if aac.jit_provisioning?
        next unless pseudonym

        pseudonym.instance_variable_set(:@ldap_result, res.first)
        @pseudonym_session = PseudonymSession.new(pseudonym, params[:pseudonym_session][:remember_me] == "1")
        @pseudonym_session.save
      end
    end

    if !found && params[:pseudonym_session]
      pseudonym = Pseudonym.authenticate(params[:pseudonym_session],
                                         @domain_root_account.trusted_account_ids,
                                         request.remote_ip)
      if pseudonym && pseudonym != :too_many_attempts
        @pseudonym_session = PseudonymSession.new(pseudonym, params[:pseudonym_session][:remember_me] == "1")
        found = @pseudonym_session.save
      end
    end

    if pseudonym == :too_many_attempts || @pseudonym_session.too_many_attempts?
      unsuccessful_login t("Too many failed login attempts. Please try again later or contact your system administrator.")
      return
    end

    pseudonym = @pseudonym_session && @pseudonym_session.record
    # If the user's @domain_root_account has been deleted, feel free to share that information
    if pseudonym && (!pseudonym.user || pseudonym.user.unavailable?)
      unsuccessful_login t("That user account has been deleted.  Please contact your system administrator to have your account re-activated.")
      return
    end

    # If the user is registered and logged in, redirect them to their dashboard page
    if found
      # Call for some cleanups that should be run when a user logs in
      user = pseudonym.login_assertions_for_user
      successful_login(user, pseudonym)
    else
      unsuccessful_login t("Invalid username or password")
    end
  end

  protected

  def unsuccessful_login(message)
    if request.format.json?
      return render :json => {:errors => [message]}, :status => :bad_request
    end
    flash[:error] = message
    @errored = true
    @headers = false
    maybe_render_mobile_login :bad_request
  end

  def maybe_render_mobile_login(status = nil)
    if mobile_device?
      @login_handle_name = @domain_root_account.login_handle_name_with_inference
      @login_handle_is_email = @login_handle_name == AccountAuthorizationConfig.default_login_handle_name
      js_env(
        GOOGLE_ANALYTICS_KEY: Setting.get('google_analytics_key', nil),
      )
      render :mobile_login, layout: 'mobile_auth', status: status
    else
      @aacs_with_buttons = @domain_root_account.authentication_providers.active.select { |aac| aac.class.login_button? }
      render :new, status: status
    end
  end
end
