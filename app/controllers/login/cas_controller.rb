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

require 'casclient'

class Login::CasController < ApplicationController
  include Login::Shared

  protect_from_forgery except: :destroy, with: :exception

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, :check_sa_delegated_cookie, :fix_ms_office_redirects, only: :new

  delegate :client, to: :aac

  def new
    # CAS sends a GET with a ticket when it's doing a login
    return create if params[:ticket]

    redirect_to delegated_auth_redirect_uri(client.add_service_to_login_url(cas_login_url))
  end

  def create
    logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
    st = CASClient::ServiceTicket.new(params[:ticket], cas_login_url)
    begin
      default_timeout = Setting.get('cas_timelimit', 5.seconds.to_s).to_f

      timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }

      Canvas.timeout_protection("cas:#{aac.global_id}", timeout_options) do
        client.validate_service_ticket(st)
      end
    rescue => e
      logger.warn "Failed to validate CAS ticket: #{e.inspect}"
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      return redirect_to login_url
    end

    if st.is_valid?
      reset_session_for_login

      pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(st.user, aac)
      pseudonym ||= aac.provision_user(st.user) if aac.jit_provisioning?

      if pseudonym
        # Successful login and we have a user
        @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
        session[:cas_session] = params[:ticket]
        session[:login_aac] = aac.id
        pseudonym.claim_cas_ticket(params[:ticket])

        successful_login(pseudonym.user, pseudonym)
      else
        unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
        logger.warn "Received CAS login for unknown user: #{st.user}, redirecting to: #{unknown_user_url}."
        flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", :user => st.user
        redirect_to unknown_user_url
      end
    else
      logger.warn "Failed CAS login attempt."
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      redirect_to login_url
    end
  end

  CAS_SAML_LOGOUT_REQUEST = %r{^<samlp:LogoutRequest.*?<samlp:SessionIndex>(?<session_index>.*)</samlp:SessionIndex>}m

  def destroy
    if !Canvas.redis_enabled?
      # NOT SUPPORTED without redis
      return render text: "NOT SUPPORTED", status: :method_not_allowed
    elsif params['logoutRequest'] &&
        (match = params['logoutRequest'].match(CAS_SAML_LOGOUT_REQUEST))
      # we *could* validate the timestamp here, but the whole request is easily spoofed anyway, so there's no
      # point. all the security is in the ticket being secret and non-predictable
      return render text: "OK", status: :ok if Pseudonym.expire_cas_ticket(match[:session_index])
    end
    render text: "NO SESSION FOUND", status: :not_found
  end

  protected

  def aac
    @aac ||= begin
      scope = @domain_root_account.authentication_providers.active.where(auth_type: 'cas')
      params[:id] ? scope.find(params[:id]) : scope.first!
    end
  end

  def cas_login_url
    url_for({ controller: 'login/cas', action: :new }.merge(params.slice(:id)))
  end
end
