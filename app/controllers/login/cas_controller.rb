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

require "casclient"

class Login::CasController < ApplicationController
  include Login::Shared

  protect_from_forgery except: :destroy, with: :exception

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, :fix_ms_office_redirects, only: :new

  delegate :client, to: :aac

  def new
    # CAS sends a GET with a ticket when it's doing a login
    if params[:ticket]
      params[:action] = :create
      return create
    end

    aac
    increment_statsd(:attempts)

    # inlines CASClient::Client#add_service_to_login_url method,
    # so that multiple params can be added
    uri = URI.parse(client.login_url)
    uri.query = (uri.query ? uri.query + "&" : "") + "service=#{CGI.escape(cas_login_url)}"
    if force_login_after_logout? || Canvas::Plugin.value_to_boolean(params[:force_login])
      uri.query += "&renew=true"
    end

    redirect_to uri.to_s
  end

  def create
    logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
    # only record further information if we're the first incoming ticket to fill out debugging info
    debugging = aac.debug_set(:ticket_received, params[:ticket], overwrite: false) if aac.debugging?
    increment_statsd(:attempts)

    st = CASClient::ServiceTicket.new(params[:ticket], cas_login_url)
    begin
      timeout_options = { raise_on_timeout: true, fallback_timeout_length: 10.0 }

      Canvas.timeout_protection("cas:#{aac.global_id}", timeout_options) do
        client.validate_service_ticket(st)
      end
    rescue => e
      logger.warn "Failed to validate CAS ticket: #{e.inspect}"

      if e.is_a?(Timeout::Error)
        if e.respond_to?(:error_count)
          increment_statsd(:failure, reason: :timeout, tags: { error_count: e.error_count })
        else
          increment_statsd(:failure, reason: :timeout)
        end
      else
        increment_statsd(:failure, reason: :validation_error)
      end

      aac.debug_set(:validate_service_ticket, t("Failed to validate CAS ticket: %{error}", error: e)) if debugging
      flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                    institution: @domain_root_account.display_name)
      return redirect_to login_url
    end

    if st.is_valid?
      aac.debug_set(:validate_service_ticket, t("Validated ticket for %{username}", username: st.user)) if debugging
      reset_session_for_login

      find_pseudonym(st)
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
      increment_statsd(:failure, reason: :invalid_ticket)
    end
  end

  def destroy
    if !Canvas.redis_enabled?
      # NOT SUPPORTED without redis
      return render plain: "NOT SUPPORTED", status: :method_not_allowed
    elsif params["logoutRequest"] &&
          (logout_request = SAML2::LogoutRequest.parse(params["logoutRequest"])) &&
          logout_request.valid_schema? &&
          logout_request.session_index.length == 1
      increment_statsd(:attempts)
      # we *could* validate the timestamp here, but the whole request is easily spoofed anyway, so there's no
      # point. all the security is in the ticket being secret and non-predictable
      if Pseudonym.expire_cas_ticket(logout_request.session_index.first, request)
        increment_statsd(:success)
        return render plain: "OK", status: :ok
      else
        increment_statsd(:failure, reason: :no_session)
      end
    end

    render plain: "NO SESSION FOUND", status: :not_found
  end

  private

  def find_pseudonym(service_ticket)
    pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(service_ticket.user, aac)
    if pseudonym
      aac.apply_federated_attributes(pseudonym, service_ticket.extra_attributes)
    elsif aac.jit_provisioning?
      pseudonym = aac.provision_user(service_ticket.user, service_ticket.extra_attributes)
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
      logger.warn "Received CAS login for unknown user: #{service_ticket.user}"
      redirect_to_unknown_user_url(t("Canvas doesn't have an account for user: %{user}", user: service_ticket.user))
      increment_statsd(:failure, reason: :unknown_user)
    end
  end

  def aac
    @aac ||= begin
      scope = @domain_root_account.authentication_providers.active.where(auth_type: "cas")
      params[:id] ? scope.find(params[:id]) : scope.first!
    end
  end

  def cas_login_url
    url_for({ controller: "login/cas", action: :new }.merge(params.permit(:id).to_unsafe_h))
  end

  def auth_type
    AuthenticationProvider::CAS.sti_name
  end
end
