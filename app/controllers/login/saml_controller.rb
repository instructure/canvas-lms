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

class Login::SamlController < ApplicationController
  include Login::Shared

  protect_from_forgery except: [:create, :destroy], with: :exception

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, only: [:new, :create]
  before_action :fix_ms_office_redirects, only: :new

  def new
    increment_saml_stat("login_attempt")
    session[:saml2_processing] = false if Canvas::Plugin.value_to_boolean(params[:saml2_processing], ignore_unrecognized: true) == false
    redirect_to delegated_auth_redirect_uri(aac.generate_authn_request_redirect(host: request.host_with_port,
                                                                                parent_registration: session[:parent_registration],
                                                                                relay_state: Rails.env.development? && params[:RelayState]))
  end

  def create
    login_error_message = t("There was a problem logging in at %{institution}",
                            institution: @domain_root_account.display_name)

    saml2_processing = true
    saml2_processing = false if session[:saml2_processing] == false
    saml2_processing = false if @domain_root_account.settings[:process_saml_responses_with_saml2] == false

    legacy_response = Onelogin::Saml::Response.new(params[:SAMLResponse])
    response, relay_state = SAML2::Bindings::HTTP_POST.decode(request.request_parameters)

    increment_saml_stat('login_response_received')

    aac = @domain_root_account.authentication_providers.active.
      where(auth_type: 'saml').
      where(idp_entity_id: legacy_response.issuer).
      first
    if aac.nil?
      logger.error "Attempted SAML login for #{legacy_response.issuer} on account without that IdP"
      flash[:delegated_message] = if @domain_root_account.auth_discovery_url
        t("Canvas did not recognize your identity provider")
      elsif response.issuer
        t("Canvas is not configured to receive logins from %{issuer}.", issuer: legacy_response.issuer)
      else
        t("The institution you logged in from is not configured on this account.")
      end
      return redirect_to login_url
    end

    debugging = if aac.debugging? && response.is_a?(SAML2::Response)
      if response.in_response_to
        aac.debug_get(:request_id) == response.in_response_to
      else
        aac.debug_set(:request_id, t("IdP Initiated"), overwrite: false)
      end
    end
    encrypted_xml = response.to_s if debugging

    settings = aac.saml_settings(request.host_with_port)

    aac.sp_metadata(request.host_with_port).valid_response?(response,
                                                            aac.idp_metadata,
                                                            ignore_audience_condition: aac.settings['ignore_audience_condition'])
    legacy_response.process(settings) unless saml2_processing

    if debugging
      aac.debug_set(:debugging, t('debug.redirect_from_idp', "Received LoginResponse from IdP"))
      aac.debug_set(:idp_response_encoded, params[:SAMLResponse])
      aac.debug_set(:idp_response_xml_encrypted, saml2_processing ? encrypted_xml : legacy_response.xml)
      aac.debug_set(:idp_response_xml_decrypted, saml2_processing ? response.to_s : legacy_response.decrypted_document.to_s)
      aac.debug_set(:idp_in_response_to, saml2_processing ? response.try(:in_response_to) : legacy_response.in_response_to)
      aac.debug_set(:idp_login_destination, saml2_processing ? response.destination : legacy_response.destination)
      aac.debug_set(:login_to_canvas_success, 'false')
      unless saml2_processing
        aac.debug_set(:fingerprint_from_idp, legacy_response.fingerprint_from_idp)
      end
    end

    if !saml2_processing && legacy_response.is_valid? && !response.errors.empty?
      logger.warn("Response valid via legacy SAML processing from #{legacy_response.issuer}, but invalid according to SAML2 processing: #{response.errors.join("\n")}")
      unless aac.settings['first_saml_error']
        aac.settings['first_saml_error'] = response.errors.join("\n")
        aac.save!
      end
    end

    if saml2_processing
      # yes, a lot of this is duplicated from below, but there are also a lot of changes,
      # and it's easier to not interweave them so the legacy code can be easily stripped
      # in the future
      assertion = response.assertions.first
      # yes, they could be _that_ busted that we put a dangling rescue here.
      provider_attributes = assertion&.attribute_statements&.first&.to_h || {} rescue {}
      subject_name_id = assertion&.subject&.name_id
      unique_id = if aac.login_attribute == 'NameID'
        subject_name_id&.id
      else
        provider_attributes[aac.login_attribute]
      end
      if unique_id && aac.strip_domain_from_login_attribute?
        unique_id = unique_id.split('@', 2)[0]
      end

      logger.info "Attempting SAML2 login for #{aac.login_attribute} #{unique_id} in account #{@domain_root_account.id}"

      unless response.errors.empty?
        increment_saml_stat("errors.invalid_response")
        if debugging
          aac.debug_set(:is_valid_login_response, 'false')
          aac.debug_set(:login_response_validation_error, response.errors.join("\n"))
        end
        logger.error "Failed to verify SAML signature: #{response.errors.join("\n")}"
        flash[:delegated_message] = login_error_message
        return redirect_to login_url
      end

      aac.debug_set(:is_valid_login_response, 'true') if debugging

      # for parent using self-registration to observe a student
      # the student is logged out after validation
      # and registration process resumed
      if session[:parent_registration]
        expected_unique_id = session[:parent_registration][:observee][:unique_id]
        session[:parent_registration][:unique_id_match] = (expected_unique_id == unique_id)
        saml = ExternalAuthObservation::Saml.new(@domain_root_account, request, response)
        redirect_to saml.logout_url
        return
      end

      reset_session_for_login

      pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(unique_id, aac)
      if !pseudonym && aac.jit_provisioning?
        pseudonym = aac.provision_user(unique_id, provider_attributes)
      elsif pseudonym
        aac.apply_federated_attributes(pseudonym, provider_attributes)
      end

      if pseudonym
        # Successful login and we have a user
        @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
        user = pseudonym.login_assertions_for_user

        if debugging
          aac.debug_set(:login_to_canvas_success, 'true')
          aac.debug_set(:logged_in_user_id, user.id)
        end
        increment_saml_stat("normal.login_success")

        session[:saml_unique_id] = unique_id
        session[:name_id] = subject_name_id&.id
        session[:name_identifier_format] = subject_name_id&.format
        session[:name_qualifier] = subject_name_id&.name_qualifier
        session[:sp_name_qualifier] = subject_name_id&.sp_name_qualifier
        session[:session_index] = assertion.authn_statements.first&.session_index
        session[:login_aac] = aac.id

        if relay_state.present? && (uri = URI.parse(relay_state) rescue nil)
          if uri.host
            # allow relay_state's to other (trusted) domains, by tacking on a session token
            target_account = Account.find_by_domain(uri.host)
            if target_account &&
              target_account != @domain_root_account &&
              pseudonym.works_for_account?(target_account, true)
              token = SessionToken.new(pseudonym.global_id,
                                       current_user_id: pseudonym.global_user_id).to_s
              uri.query.concat('&') if uri.query
              uri.query ||= ''
              uri.query.concat("session_token=#{token}")
              session[:return_to] = uri.to_s
            end
          elsif uri.path[0] == '/'
            # otherwise, absolute paths on the same domain are okay
            session[:return_to] = relay_state
          end
        end
        successful_login(user, pseudonym)
      else
        unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
        increment_saml_stat("errors.unknown_user")
        message = "Received SAML login request for unknown user: #{unique_id} redirecting to: #{unknown_user_url}."
        logger.warn message
        aac.debug_set(:canvas_login_fail_message, message) if debugging
        flash[:delegated_message] = t("Canvas doesn't have an account for user: %{user}",
                                      user: unique_id)
        redirect_to unknown_user_url
      end

      return
    end

    provider_attributes = legacy_response.saml_attributes
    unique_id = if aac.login_attribute == 'NameID'
      legacy_response.name_id
    else
      provider_attributes[aac.login_attribute]
    end
    if unique_id && aac.strip_domain_from_login_attribute?
      unique_id = unique_id.split('@', 2)[0]
    end

    logger.info "Attempting SAML login for #{aac.login_attribute} #{unique_id} in account #{@domain_root_account.id}"

    if legacy_response.is_valid?
      aac.debug_set(:is_valid_login_response, 'true') if debugging

      if legacy_response.success_status?
        # for parent using self-registration to observe a student
        # the student is logged out after validation
        # and registration process resumed
        if session[:parent_registration]
          expected_unique_id = session[:parent_registration][:observee][:unique_id]
          session[:parent_registration][:unique_id_match] = (expected_unique_id == unique_id)
          saml = ExternalAuthObservation::Saml.new(@domain_root_account, request, legacy_response)
          redirect_to saml.logout_url
          return
        end

        reset_session_for_login

        pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(unique_id, aac)
        if !pseudonym && aac.jit_provisioning?
          pseudonym = aac.provision_user(unique_id, provider_attributes)
        elsif pseudonym
          aac.apply_federated_attributes(pseudonym, provider_attributes)
        end

        if pseudonym
          # Successful login and we have a user
          @domain_root_account.pseudonym_sessions.create!(pseudonym, false)
          user = pseudonym.login_assertions_for_user

          if debugging
            aac.debug_set(:login_to_canvas_success, 'true')
            aac.debug_set(:logged_in_user_id, user.id)
          end
          increment_saml_stat("normal.login_success")

          session[:saml_unique_id] = unique_id
          session[:name_id] = legacy_response.name_id
          session[:name_identifier_format] = legacy_response.name_identifier_format
          session[:name_qualifier] = legacy_response.name_qualifier
          session[:sp_name_qualifier] = legacy_response.sp_name_qualifier
          session[:session_index] = legacy_response.session_index
          session[:return_to] = params[:RelayState] if params[:RelayState] && params[:RelayState] =~ /\A\/(\z|[^\/])/
          session[:login_aac] = aac.id

          successful_login(user, pseudonym)
        else
          unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
          increment_saml_stat("errors.unknown_user")
          message = "Received SAML login request for unknown user: #{unique_id} redirecting to: #{unknown_user_url}."
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          flash[:delegated_message] = t("Canvas doesn't have an account for user: %{user}",
                                        user: unique_id)
          redirect_to unknown_user_url
        end
      elsif legacy_response.auth_failure?
        increment_saml_stat("normal.login_failure")
        message = "Failed to log in correctly at IdP"
        logger.warn message
        aac.debug_set(:canvas_login_fail_message, message) if debugging
        flash[:delegated_message] = login_error_message
        redirect_to login_url
      elsif legacy_response.no_authn_context?
        increment_saml_stat("errors.no_authn_context")
        message = "Attempted SAML login for unsupported authn_context at IdP."
        logger.warn message
        aac.debug_set(:canvas_login_fail_message, message) if debugging
        flash[:delegated_message] = login_error_message
        redirect_to login_url
      else
        increment_saml_stat("errors.unexpected_response_status")
        message = "Unexpected SAML status code - status code: #{legacy_response.status_code || ''} - Status Message: #{legacy_response.status_message || ''}"
        logger.warn message
        aac.debug_set(:canvas_login_fail_message, message) if debugging
        flash[:delegated_message] = login_error_message
        redirect_to login_url
      end
    else
      increment_saml_stat("errors.invalid_response")
      if debugging
        aac.debug_set(:is_valid_login_response, 'false')
        aac.debug_set(:login_response_validation_error, legacy_response.validation_error)
      end
      logger.error "Failed to verify SAML signature: #{legacy_response.validation_error}"
      flash[:delegated_message] = login_error_message
      redirect_to login_url
    end
  end

  rescue_from SAML2::InvalidMessage, with: :saml_error
  def saml_error(error)
    Canvas::Errors.capture_exception(:saml, error)
    render status: :bad_request, plain: error.to_s
  end

  def destroy
    aac = message = nil
    key_to_certificate = {}
    log_key_used = ->(key) do
      fingerprint = Digest::SHA1.hexdigest(key_to_certificate[key].to_der).gsub(/(\h{2})(?=\h)/, '\1:')
      logger.info "Received signed SAML LogoutRequest from #{message.issuer.id} using certificate #{fingerprint}"
    end

    message, relay_state = SAML2::Bindings::HTTPRedirect.decode(request.url, public_key_used: log_key_used) do |m|
      message = m
      aac = @domain_root_account.authentication_providers.active.where(idp_entity_id: message.issuer.id).first
      return render status: :bad_request, plain: "Could not find SAML Entity" unless aac

      # only require signatures for LogoutRequests, and only if the provider has a certificate on file
      next unless message.is_a?(SAML2::LogoutRequest)
      next if (certificates = aac.signing_certificates).blank?
      certificates.map do |cert_base64|
        certificate = OpenSSL::X509::Certificate.new(Base64.decode64(cert_base64))
        key = certificate.public_key
        key_to_certificate[key] = certificate
        key
      end
    end
    # the above block may have been skipped in specs due to stubbing
    aac ||= @domain_root_account.authentication_providers.active.where(idp_entity_id: message.issuer.id).first
    return render status: :bad_request, plain: "Could not find SAML Entity" unless aac

    case message
    when SAML2::LogoutResponse
      increment_saml_stat("logout_response_received")

      if aac.debugging? && aac.debug_get(:logout_request_id) == message.in_response_to
        aac.debug_set(:idp_logout_response_encoded, params[:SAMLResponse])
        aac.debug_set(:idp_logout_response_xml_encrypted, message.xml.to_xml)
        aac.debug_set(:idp_logout_response_in_response_to, message.in_response_to)
        aac.debug_set(:idp_logout_response_destination, message.destination)
        aac.debug_set(:debugging, t('debug.logout_response_redirect_from_idp', "Received LogoutResponse from IdP"))
      end

      unless message.status.code == SAML2::Status::SUCCESS
        logger.error "Failed SAML LogoutResponse: #{message.status.code}: #{message.status.message}"
        flash[:delegated_message] = t("There was a failure logging out at your IdP")
        return redirect_to login_url
      end

      # for parent using self-registration to observe a student
      # following saml validation of student
      # resume registration process
      if data = session.delete(:parent_registration)
        if data[:unique_id_match]
          if data[:observee_only].present?
            # TODO: a race condition exists where the observee unique_id is
            # already checked during pre-login form submit, but might have gone
            # away during login. this should be very rare, and we don't have a
            # mechanism for displaying and correcting the error yet.

            # create the observee relationship, then send them back to that index
            complete_observee_addition(data)
            redirect_to observees_profile_path
          else
            # TODO: a race condition exists where the observer unique_id and
            # observee unique_id are already checked during pre-login form
            # submit, but the former might have been taken or the latter gone
            # away during login. this should be very rare, and we don't have a
            # mechanism for displaying and correcting the error yet.

            # create the observer user connected to the observee
            pseudonym = complete_parent_registration(data)

            # log the new user in and send them to the dashboard
            PseudonymSession.new(pseudonym).save
            redirect_to dashboard_path(registration_success: 1)
          end
        else
          flash[:error] = t("We're sorry, a login error has occurred, please check your child's credentials and try again.")
          redirect_to data[:observee_only].present? ? observees_profile_path : canvas_login_path
        end
        return
      end

      return redirect_to saml_login_url(id: aac.id)
    when SAML2::LogoutRequest
      increment_saml_stat("logout_request_received")

      if aac.debugging? && aac.debug_get(:logged_in_user_id) == @current_user.id
        aac.debug_set(:idp_logout_request_encoded, params[:SAMLRequest])
        aac.debug_set(:idp_logout_request_xml_encrypted, message.xml.to_xml)
        aac.debug_set(:idp_logout_request_name_id, message.name_id.id)
        aac.debug_set(:idp_logout_request_session_index, message.session_index)
        aac.debug_set(:idp_logout_request_destination, message.destination)
        aac.debug_set(:debugging, t('debug.logout_request_redirect_from_idp', "Received LogoutRequest from IdP"))
      end

      logout_response = SAML2::LogoutResponse.respond_to(message,
                                                         aac.idp_metadata.identity_providers.first,
                                                         SAML2::NameID.new(aac.entity_id))

      # Seperate the debugging out because we want it to log the request even if the response dies.
      if aac.debugging? && aac.debug_get(:logged_in_user_id) == @current_user.id
        aac.debug_set(:idp_logout_response_xml_encrypted, logout_response.to_s)
        aac.debug_set(:idp_logout_response_status_code, logout_response.status.code)
        aac.debug_set(:idp_logout_response_destination, logout_response.destination)
        aac.debug_set(:idp_logout_response_in_response_to, logout_response.in_response_to)
        aac.debug_set(:debugging, t('debug.logout_response_redirect_to_idp', "Sending LogoutResponse to IdP"))
      end

      logout_current_user

      private_key = AuthenticationProvider::SAML.private_key
      private_key = nil if aac.sig_alg.nil?
      forward_url = SAML2::Bindings::HTTPRedirect.encode(logout_response,
                                                         relay_state: relay_state,
                                                         private_key: private_key,
                                                         sig_alg: aac.sig_alg)

      return redirect_to(forward_url)
    else
      error = "Unexpected SAML message: #{message.class}"
      Canvas::Errors.capture_exception(:saml, error)
      return render status: :bad_request, plain: error
    end
  end

  def metadata
    # This needs to be publicly available since external SAML
    # servers need to be able to access it without being authenticated.
    # It is used to disclose our SAML configuration settings.
    metadata = AuthenticationProvider::SAML.sp_metadata_for_account(@domain_root_account, request.host_with_port)
    render xml: metadata.to_xml
  end


  def observee_validation
    increment_saml_stat("login_attempt")
    redirect_to delegated_auth_redirect_uri(
                  @domain_root_account.parent_registration_aac.generate_authn_request_redirect(host: request.host_with_port,
                                                                                               parent_registration: session[:parent_registration]))
  end

  protected

  def aac
    @aac ||= begin
      scope = @domain_root_account.authentication_providers.active.where(auth_type: 'saml')
      id = params[:id] || params[:entityID]
      return scope.first! unless id
      if id.to_i == 0
        scope.find_by!(idp_entity_id: id)
      else
        scope.find(id)
      end
    end
  end

  def increment_saml_stat(key)
    CanvasStatsd::Statsd.increment("saml.#{CanvasStatsd::Statsd.escape(request.host)}.#{key}")
  end

  def complete_observee_addition(registration_data)
    observee_unique_id = registration_data[:observee][:unique_id]
    observee = @domain_root_account.pseudonyms.by_unique_id(observee_unique_id).first.user
    unless @current_user.as_observer_observation_links.where(user_id: observee, root_account: @domain_root_account).exists?
      UserObservationLink.create_or_restore(student: observee, observer: @current_user, root_account: @domain_root_account)
      @current_user.touch
    end
  end

  def complete_parent_registration(registration_data)
    user_name = registration_data[:user][:name]
    terms_of_use = registration_data[:user][:terms_of_use]
    observee_unique_id = registration_data[:observee][:unique_id]
    observer_unique_id = registration_data[:pseudonym][:unique_id]

    # create observer with specificed name
    user = User.new
    user.name = user_name
    user.terms_of_use = terms_of_use
    user.initial_enrollment_type = 'observer'
    user.workflow_state = 'pre_registered'
    user.require_presence_of_name = true
    user.require_acceptance_of_terms = @domain_root_account.terms_required?
    user.validation_root_account = @domain_root_account

    # add the desired pseudonym
    pseudonym = user.pseudonyms.build(account: @domain_root_account)
    pseudonym.account.email_pseudonyms = true
    pseudonym.unique_id = observer_unique_id
    pseudonym.workflow_state = 'active'
    pseudonym.user = user
    pseudonym.account = @domain_root_account

    # add the email communication channel
    cc = user.communication_channels.build(path_type: CommunicationChannel::TYPE_EMAIL, path: observer_unique_id)
    cc.workflow_state = 'unconfirmed'
    cc.user = user
    user.save!

    # set the new user (observer) to observe the target user (observee)
    observee = @domain_root_account.pseudonyms.active.by_unique_id(observee_unique_id).first.user
    UserObservationLink.create_or_restore(student: observee, observer: user, root_account: @domain_root_account)

    notify_policy = Users::CreationNotifyPolicy.new(false, unique_id: observer_unique_id)
    notify_policy.dispatch!(user, pseudonym, cc)

    pseudonym
  end
end
