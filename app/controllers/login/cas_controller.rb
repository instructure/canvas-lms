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

require 'casclient'

class Login::CasController < ApplicationController
  include Login::Shared

  protect_from_forgery except: :destroy, with: :exception

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, :fix_ms_office_redirects, only: :new

  delegate :client, to: :aac

  def new
    # CAS sends a GET with a ticket when it's doing a login
    return create if params[:ticket]

    redirect_to client.add_service_to_login_url(cas_login_url)
  end

  def create
    logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
    # only record further information if we're the first incoming ticket to fill out debugging info
    debugging = aac.debug_set(:ticket_received, params[:ticket], overwrite: false) if aac.debugging?

    st = CASClient::ServiceTicket.new(params[:ticket], cas_login_url)
    begin
      default_timeout = Setting.get('cas_timelimit', 5.seconds.to_s).to_f

      timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }

      Canvas.timeout_protection("cas:#{aac.global_id}", timeout_options) do
        client.validate_service_ticket(st)
      end
    rescue => e
      logger.warn "Failed to validate CAS ticket: #{e.inspect}"
      aac.debug_set(:validate_service_ticket, t("Failed to validate CAS ticket: %{error}", error: e)) if debugging
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      return redirect_to login_url
    end

    if st.is_valid?
      aac.debug_set(:validate_service_ticket, t("Validated ticket for %{username}", username: st.user)) if debugging
      reset_session_for_login

      pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(st.user, aac)
      if pseudonym
        aac.apply_federated_attributes(pseudonym, st.extra_attributes)
      elsif aac.jit_provisioning?
        pseudonym = aac.provision_user(st.user, st.extra_attributes)
      end

      if pseudonym && (user = pseudonym.login_assertions_for_user)
        # Successful login and we have a user

        @domain_root_account.pseudonyms.scoping do
          PseudonymSession.create!(pseudonym, false)
        end
        session[:cas_session] = params[:ticket]
        session[:login_aac] = aac.id

        pseudonym.infer_auth_provider(aac)
        successful_login(user, pseudonym)
      else
        unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
        logger.warn "Received CAS login for unknown user: #{st.user}, redirecting to: #{unknown_user_url}."
        flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", :user => st.user
        redirect_to unknown_user_url
      end
    else
      if debugging
        if st.failure_code || st.failure_message
          aac.debug_set(:validate_service_ticket, t("CAS server rejected ticket: %{message} (%{code})", message: st.failure_message, code: st.failure_code))
        else
          aac.debug_set(:validate_service_ticket, t("CAS server rejected ticket."))
        end
      end
      logger.warn "Failed CAS login attempt. (#{st.failure_code}: #{st.failure_message})"
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      redirect_to login_url
    end
  end

  CAS_SAML_LOGOUT_REQUEST = %r{^<samlp:LogoutRequest.*?<samlp:SessionIndex>(?<session_index>.*)</samlp:SessionIndex>}m

  def destroy
    if !Canvas.redis_enabled?
      # NOT SUPPORTED without redis
      return render plain: "NOT SUPPORTED", status: :method_not_allowed
    elsif params['logoutRequest'] &&
        (match = params['logoutRequest'].match(CAS_SAML_LOGOUT_REQUEST))
      # we *could* validate the timestamp here, but the whole request is easily spoofed anyway, so there's no
      # point. all the security is in the ticket being secret and non-predictable
      return render plain: "OK", status: :ok if Pseudonym.expire_cas_ticket(match[:session_index])
    end
    render plain: "NO SESSION FOUND", status: :not_found
  end

  protected

  def aac
    @aac ||= begin
      scope = @domain_root_account.authentication_providers.active.where(auth_type: 'cas')
      params[:id] ? scope.find(params[:id]) : scope.first!
    end
  end

  def cas_login_url
    url_for({ controller: 'login/cas', action: :new }.merge(params.permit(:id).to_unsafe_h))
  end
end
