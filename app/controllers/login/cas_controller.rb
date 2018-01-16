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

  before_filter :forbid_on_files_domain
  before_filter :run_login_hooks, :check_sa_delegated_cookie, :fix_ms_office_redirects, only: :new

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

      sso_user = st.user
      was_nlu_sso = false
      if !st.extra_attributes["EmployeeNumber"].nil? && cas_login_url.ends_with?('cas/6')
        sso_user = "#{st.extra_attributes["EmployeeNumber"]}@nlu.edu"
        was_nlu_sso = true
      end

      pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(sso_user, aac)
      pseudonym ||= aac.provision_user(sso_user) if aac.jit_provisioning?

      if pseudonym
        # Successful login and we have a user
        @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
        session[:cas_session] = params[:ticket]
        session[:login_aac] = aac.id
        pseudonym.claim_cas_ticket(params[:ticket])

        successful_login(pseudonym.user, pseudonym)
      else
        # we don't have a user, but if it was a Braven login for an NLU student, 
        # we might be able to correct the problem by sending them right to the nlu
        # login
        if !was_nlu_sso
          possibilities = CommunicationChannel.active.where(:path_type => "email", :path => sso_user)
          if possibilities.any?
            maybe = Pseudonym.active.where(:user_id => possibilities.first.user_id).where("unique_id LIKE '%@nlu.edu'")
            if maybe.any?
              # looks like an NLU user using Braven SSO. Let's send them back to the NLU login
              # before considering it an error - hopefully they can just log in with that and
              # not have to bother us

              logger.warn "Received CAS login for unknown user: #{sso_user}, think it is #{possibilities.first.user_id} redirecting to: NLU SSO."

              redirect_to '/nlu'
              return
            end
          end
        end

        unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
        logger.warn "Received CAS login for unknown user: #{sso_user}, redirecting to: #{unknown_user_url}."
        flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", :user => sso_user
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
