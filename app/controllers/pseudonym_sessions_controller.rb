#
# Copyright (C) 2011-2013 Instructure, Inc.
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

class PseudonymSessionsController < ApplicationController
  protect_from_forgery :except => [:create, :destroy, :saml_consume, :oauth2_token, :oauth2_logout, :cas_logout]
  before_filter :forbid_on_files_domain, :except => [ :clear_file_session ]
  before_filter :require_password_session, :only => [ :otp_login, :disable_otp_login ]
  before_filter :require_user, :only => [ :otp_login ]
  skip_before_filter :require_reacceptance_of_terms

  def new
    if @current_user && !params[:force_login] && !params[:confirm] && !params[:expected_user_id] && !session[:used_remember_me_token]
      redirect_to dashboard_url
      return
    end

    if params[:needs_cookies] == '1'
      @needs_cookies = true
      return render(:template => 'shared/unauthorized', :layout => 'application', :status => :unauthorized)
    end

    session[:expected_user_id] = params[:expected_user_id].to_i if params[:expected_user_id]
    session[:confirm] = params[:confirm] if params[:confirm]
    session[:enrollment] = params[:enrollment] if params[:enrollment]

    if @current_pseudonym
      params[:pseudonym_session] ||= {}
      params[:pseudonym_session][:unique_id] ||= @current_pseudonym.unique_id
    end

    @pseudonym_session = PseudonymSession.new
    @headers = false
    @is_delegated = delegated_authentication_url?
    @is_cas = @domain_root_account.cas_authentication? && @is_delegated
    @is_saml = @domain_root_account.saml_authentication? && @is_delegated
    if @is_cas && !params[:no_auto]
      if params[:ticket]
        # handle the callback from CAS
        logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
        st = CASClient::ServiceTicket.new(params[:ticket], cas_login_url)
        begin
          cas_client.validate_service_ticket(st)
        rescue => e
          logger.warn "Failed to validate CAS ticket: #{e.inspect}"
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to cas_login_url(:no_auto=>'true')
          return
        end
        if st.is_valid?
          @pseudonym = nil
          @pseudonym = @domain_root_account.pseudonyms.custom_find_by_unique_id(st.response.user)
          if @pseudonym
            # Successful login and we have a user
            @domain_root_account.pseudonym_sessions.create!(@pseudonym, false)
            session[:cas_session] = params[:ticket]
            @pseudonym.claim_cas_ticket(params[:ticket])
            @user = @pseudonym.login_assertions_for_user

            successful_login(@user, @pseudonym)
            return
          else
            logger.warn "Received CAS login for unknown user: #{st.response.user}"
            reset_session
            session[:delegated_message] = t 'errors.no_matching_user', "Canvas doesn't have an account for user: %{user}", :user => st.response.user
            redirect_to(cas_client.logout_url(cas_login_url :no_auto => true))
            return
          end
        else
          logger.warn "Failed CAS login attempt."
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to cas_login_url(:no_auto=>'true')
          return
        end
      end

      initiate_cas_login(cas_client)
    elsif @is_saml && !params[:no_auto]
      if params[:account_authorization_config_id]
        if aac = @domain_root_account.account_authorization_configs.find_by_id(params[:account_authorization_config_id])
          initiate_saml_login(request.host_with_port, aac)
        else
          message = t('errors.login_errors.no_config_for_id', "The Canvas account has no authentication configuration with that id")
          if @domain_root_account.auth_discovery_url
            redirect_to @domain_root_account.auth_discovery_url + "?message=#{URI.escape message}"
          else
            flash[:delegated_message] = message
            redirect_to login_url(:no_auto=>'true')
          end
        end
      else
        if @domain_root_account.auth_discovery_url
          redirect_to @domain_root_account.auth_discovery_url
        else
          initiate_saml_login(request.host_with_port)
        end
      end
    else
      flash[:delegated_message] = session.delete :delegated_message if session[:delegated_message]
      maybe_render_mobile_login
    end
  end

  def maybe_render_mobile_login(status = nil)
    if mobile_device?
      @login_handle_name = @domain_root_account.login_handle_name rescue AccountAuthorizationConfig.default_login_handle_name
      @login_handle_is_email = @login_handle_name == AccountAuthorizationConfig.default_login_handle_name
      js_env(
        :GOOGLE_ANALYTICS_KEY => Setting.get('google_analytics_key', nil),
        :RESET_SENT =>  t("password_confirmation_sent", "Password confirmation sent. Make sure you check your spam box."),
        :RESET_ERROR =>  t("password_confirmation_error", "Error sending request.")
      )
      render :template => 'pseudonym_sessions/mobile_login', :layout => 'mobile_auth', :status => status
    else
      @request = request
      render :action => 'new', :status => status
    end
  end

  def create
    # reset the session id cookie to prevent session fixation.
    reset_session_for_login

    if params[:pseudonym_session].blank? || params[:pseudonym_session][:password].blank?
      return unsuccessful_login(t('errors.blank_password', "No password was given"))
    end

    # strip leading and trailing whitespace off the entered unique id. some
    # mobile clients (e.g. android) will add a space after the login when using
    # autocomplete. this would prevent us from recognizing someone's username,
    # making them unable to login.
    params[:pseudonym_session][:unique_id].try(:strip!)

    # Try to use authlogic's built-in login approach first
    @pseudonym_session = @domain_root_account.pseudonym_sessions.new(params[:pseudonym_session])
    @pseudonym_session.remote_ip = request.remote_ip
    found = @pseudonym_session.save

    # look for LDAP pseudonyms where we get the unique_id back from LDAP
    if !found && !@pseudonym_session.attempted_record
      @domain_root_account.account_authorization_configs.each do |aac|
        next unless aac.ldap_authentication?
        next unless aac.identifier_format.present?
        res = aac.ldap_bind_result(params[:pseudonym_session][:unique_id], params[:pseudonym_session][:password])
        unique_id = res.first[aac.identifier_format].first if res
        if unique_id && pseudonym = @domain_root_account.pseudonyms.active.by_unique_id(unique_id).first
          pseudonym.instance_variable_set(:@ldap_result, res.first)
          @pseudonym_session = PseudonymSession.new(pseudonym, params[:pseudonym_session][:remember_me] == "1")
          found = @pseudonym_session.save
          break
        end
      end
    end

    if !found && params[:pseudonym_session]
      pseudonym = Pseudonym.authenticate(params[:pseudonym_session], @domain_root_account.trusted_account_ids, request.remote_ip)
      if pseudonym && pseudonym != :too_many_attempts
        @pseudonym_session = PseudonymSession.new(pseudonym, params[:pseudonym_session][:remember_me] == "1")
        found = @pseudonym_session.save
      end
    end

    if pseudonym == :too_many_attempts || @pseudonym_session.too_many_attempts?
      unsuccessful_login t('errors.max_attempts', "Too many failed login attempts. Please try again later or contact your system administrator."), true
      return
    end

    @pseudonym = @pseudonym_session && @pseudonym_session.record
    # If the user's account has been deleted, feel free to share that information
    if @pseudonym && (!@pseudonym.user || @pseudonym.user.unavailable?)
      unsuccessful_login t('errors.user_deleted', "That user account has been deleted.  Please contact your system administrator to have your account re-activated."), true
      return
    end

    # If the user is registered and logged in, redirect them to their dashboard page
    if found
      # Call for some cleanups that should be run when a user logs in
      @user = @pseudonym.login_assertions_for_user
      successful_login(@user, @pseudonym)
    # Otherwise re-render the login page to show the error
    else
      unsuccessful_login t('errors.invalid_credentials', "Incorrect username and/or password")
    end
  end

  def destroy
    # the saml message has to survive a couple redirects and reset_session calls
    message = session[:delegated_message]

    if @domain_root_account.saml_authentication? and session[:saml_unique_id]
      increment_saml_stat("logout_attempt")
      # logout at the saml identity provider
      # once logged out it'll be redirected to here again
      if aac = @domain_root_account.account_authorization_configs.find_by_id(session[:saml_aac_id])
        settings = aac.saml_settings(request.host_with_port)
        request = Onelogin::Saml::LogOutRequest.new(settings, session)
        forward_url = request.generate_request

        if aac.debugging? && aac.debug_get(:logged_in_user_id) == @current_user.id
          aac.debug_set(:logout_request_id, request.id)
          aac.debug_set(:logout_to_idp_url, forward_url)
          aac.debug_set(:logout_to_idp_xml, request.request_xml)
          aac.debug_set(:debugging, t('debug.logout_redirect', "LogoutRequest sent to IdP"))
        end

        logout_current_user
        session[:delegated_message] = message if message
        redirect_to(forward_url)
        return
      else
        logout_current_user
        flash[:message] = t('errors.logout_errors.no_idp_found', "Canvas was unable to log you out at your identity provider")
      end
    elsif @domain_root_account.cas_authentication? and session[:cas_session]
      logout_current_user
      session[:delegated_message] = message if message
      redirect_to(cas_client.logout_url(cas_login_url))
      return
    else
      logout_current_user
      flash[:delegated_message] = message if message
    end

    flash[:logged_out] = true
    respond_to do |format|
      session.delete(:return_to)
      if delegated_authentication_url?
        format.html { redirect_to login_url(:no_auto=>'true') }
      else
        format.html { redirect_to login_url }
      end
      format.json { render :json => "OK".to_json, :status => :ok }
    end
  end

  def cas_logout
    if !Canvas.redis_enabled?
      # NOT SUPPORTED without redis
      return render :text => "NOT SUPPORTED", :status => :method_not_allowed
    elsif params['logoutRequest'] &&
        params['logoutRequest'] =~ %r{^<samlp:LogoutRequest.*?<samlp:SessionIndex>(.*)</samlp:SessionIndex>}m
      # we *could* validate the timestamp here, but the whole request is easily spoofed anyway, so there's no
      # point. all the security is in the ticket being secret and non-predictable
      return render :text => "OK", :status => :ok if Pseudonym.release_cas_ticket($1)
    end
    render :text => "NO SESSION FOUND", :status => :not_found
  end

  def clear_file_session
    session.delete('file_access_user_id')
    session.delete('file_access_expiration')
    render :text => "ok"
  end

  def saml_consume
    if @domain_root_account.account_authorization_configs.any? { |aac| aac.saml_authentication? } && params[:SAMLResponse]
      # Break up the SAMLResponse into chunks for logging (a truncated version was probably already
      # logged with the request when using syslog)
      chunks = params[:SAMLResponse].scan(/.{1,1024}/)
      chunks.each_with_index do |chunk, idx|
        logger.info "SAMLResponse[#{idx+1}/#{chunks.length}] #{chunk}"
      end

      increment_saml_stat('login_response_received')
      response = saml_response(params[:SAMLResponse])

      if @domain_root_account.account_authorization_configs.count > 1
        aac = @domain_root_account.account_authorization_configs.find_by_idp_entity_id(response.issuer)
        if aac.nil?
          logger.error "Attempted SAML login for #{response.issuer} on account without that IdP"
          destroy_session
          if @domain_root_account.auth_discovery_url
            message = t('errors.login_errors.unrecognized_idp', "Canvas did not recognize your identity provider")
            redirect_to @domain_root_account.auth_discovery_url + "?message=#{URI.escape message}"
          else
            flash[:delegated_message] = t 'errors.login_errors.no_idp_set', "The institution you logged in from is not configured on this account."
            redirect_to login_url(:no_auto=>'true')
          end
          return
        end
      else
        aac = @domain_root_account.account_authorization_config
      end

      settings = aac.saml_settings(request.host_with_port)
      response.process(settings)

      unique_id = nil
      if aac.login_attribute == 'nameid'
        unique_id = response.name_id
      elsif aac.login_attribute == 'eduPersonPrincipalName'
        unique_id = response.saml_attributes["eduPersonPrincipalName"]
      elsif aac.login_attribute == 'eduPersonPrincipalName_stripped'
        unique_id = response.saml_attributes["eduPersonPrincipalName"]
        unique_id = unique_id.split('@', 2)[0]
      end

      logger.info "Attempting SAML login for #{aac.login_attribute} #{unique_id} in account #{@domain_root_account.id}"

      debugging = aac.debugging? && aac.debug_get(:request_id) == response.in_response_to
      if debugging
        aac.debug_set(:debugging, t('debug.redirect_from_idp', "Recieved LoginResponse from IdP"))
        aac.debug_set(:idp_response_encoded, params[:SAMLResponse])
        aac.debug_set(:idp_response_xml_encrypted, response.xml)
        aac.debug_set(:idp_response_xml_decrypted, response.decrypted_document.to_s)
        aac.debug_set(:idp_in_response_to, response.in_response_to)
        aac.debug_set(:idp_login_destination, response.destination)
        aac.debug_set(:fingerprint_from_idp, response.fingerprint_from_idp)
        aac.debug_set(:login_to_canvas_success, 'false')
      end

      login_error_message = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name

      if response.is_valid?
        aac.debug_set(:is_valid_login_response, 'true') if debugging

        if response.success_status?
          @pseudonym = @domain_root_account.pseudonyms.custom_find_by_unique_id(unique_id)

          if @pseudonym
            # We have to reset the session again here -- it's possible to do a
            # SAML login without hitting the #new action, depending on the
            # school's setup.
            reset_session_for_login
            #Successful login and we have a user
            @domain_root_account.pseudonym_sessions.create!(@pseudonym, false)
            @user = @pseudonym.login_assertions_for_user

            if debugging
              aac.debug_set(:login_to_canvas_success, 'true')
              aac.debug_set(:logged_in_user_id, @user.id)
            end
            increment_saml_stat("normal.login_success")

            session[:saml_unique_id] = unique_id
            session[:name_id] = response.name_id
            session[:name_qualifier] = response.name_qualifier
            session[:session_index] = response.session_index
            session[:return_to] = params[:RelayState] if params[:RelayState] && params[:RelayState] =~ /\A\/(\z|[^\/])/
            session[:saml_aac_id] = aac.id

            successful_login(@user, @pseudonym)
          else
            increment_saml_stat("errors.unknown_user")
            message = "Received SAML login request for unknown user: #{unique_id}"
            logger.warn message
            aac.debug_set(:canvas_login_fail_message, message) if debugging
            # the saml message has to survive a couple redirects
            session[:delegated_message] = t 'errors.no_matching_user', "Canvas doesn't have an account for user: %{user}", :user => unique_id
            redirect_to :action => :destroy
          end
        elsif response.auth_failure?
          increment_saml_stat("normal.login_failure")
          message = "Failed to log in correctly at IdP"
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          flash[:delegated_message] = login_error_message
          redirect_to login_url(:no_auto=>'true')
        elsif response.no_authn_context?
          increment_saml_stat("errors.no_authn_context")
          message = "Attempted SAML login for unsupported authn_context at IdP."
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          flash[:delegated_message] = login_error_message
          redirect_to login_url(:no_auto=>'true')
        else
          increment_saml_stat("errors.unexpected_response_status")
          message = "Unexpected SAML status code - status code: #{response.status_code rescue ""} - Status Message: #{response.status_message rescue ""}"
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          redirect_to login_url(:no_auto=>'true')
        end
      else
        increment_saml_stat("errors.invalid_response")
        if debugging
          aac.debug_set(:is_valid_login_response, 'false')
          aac.debug_set(:login_response_validation_error, response.validation_error)
        end
        logger.error "Failed to verify SAML signature."
        destroy_session
        flash[:delegated_message] = login_error_message
        redirect_to login_url(:no_auto=>'true')
      end
    elsif !params[:SAMLResponse]
      logger.error "saml_consume request with no SAMLResponse parameter"
      destroy_session
      flash[:delegated_message] = login_error_message
      redirect_to login_url(:no_auto=>'true')
    else
      logger.error "Attempted SAML login on non-SAML enabled account."
      destroy_session
      flash[:delegated_message] = login_error_message
      redirect_to login_url(:no_auto=>'true')
    end
  end

  def saml_logout
    if @domain_root_account.account_authorization_configs.any? { |aac| aac.saml_authentication? } && params[:SAMLResponse]
      increment_saml_stat("logout_response_received")
      response = saml_logout_response(params[:SAMLResponse])
      if  aac = @domain_root_account.account_authorization_configs.find_by_idp_entity_id(response.issuer)
        settings = aac.saml_settings(request.host_with_port)
        response.process(settings)

        if aac.debugging? && aac.debug_get(:logout_request_id) == response.in_response_to
          aac.debug_set(:idp_logout_response_encoded, params[:SAMLResponse])
          aac.debug_set(:idp_logout_response_xml_encrypted, response.xml)
          aac.debug_set(:idp_logout_in_response_to, response.in_response_to)
          aac.debug_set(:idp_logout_destination, response.destination)
          aac.debug_set(:debugging, t('debug.logout_redirect_from_idp', "Received LogoutResponse from IdP"))
        end
      end
    end
    redirect_to :action => :destroy
  end

  def cas_client
    return @cas_client if @cas_client
    config = { :cas_base_url => @domain_root_account.account_authorization_config.auth_base }
    @cas_client = CASClient::Client.new(config)
  end

  def saml_response(raw_response, settings=nil)
    response = Onelogin::Saml::Response.new(raw_response, settings)
    response.logger = logger
    response
  end

  def saml_logout_response(raw_response, settings=nil)
    response = Onelogin::Saml::LogoutResponse.new(raw_response, settings)
    response.logger = logger
    response
  end

  def forbid_on_files_domain
    if HostUrl.is_file_host?(request.host_with_port)
      reset_session
      return redirect_to dashboard_url(:host => HostUrl.default_host)
    end
    true
  end

  def otp_remember_me_cookie_domain
    CANVAS_RAILS2 ? ActionController::Base.session_options[:domain] : CanvasRails::Application.config.session_options[:domain]
  end

  def otp_login(send_otp = false)
    if !@current_user.otp_secret_key || request.get?
      session[:pending_otp_secret_key] ||= ROTP::Base32.random_base32
    end
    if session[:pending_otp_secret_key] && params[:otp_login].try(:[], :otp_communication_channel_id)
      @cc = @current_user.communication_channels.sms.unretired.find(params[:otp_login][:otp_communication_channel_id])
      session[:pending_otp_communication_channel_id] = @cc.id
      send_otp = true
    end
    if session[:pending_otp_secret_key] && params[:otp_login].try(:[], :phone_number)
      path = "#{params[:otp_login][:phone_number].gsub(/[^\d]/, '')}@#{params[:otp_login][:carrier]}"
      @cc = @current_user.communication_channels.sms.by_path(path).first
      @cc ||= @current_user.communication_channels.sms.create!(:path => path)
      if @cc.retired?
        @cc.workflow_state = 'unconfirmed'
        @cc.save!
      end
      session[:pending_otp_communication_channel_id] = @cc.id
      send_otp = true
    end
    secret_key = session[:pending_otp_secret_key] || @current_user.otp_secret_key
    if send_otp
      @cc ||= @current_user.otp_communication_channel
      @cc.try(:send_later_if_production_enqueue_args, :send_otp!, { :priority => Delayed::HIGH_PRIORITY, :max_attempts => 1 }, ROTP::TOTP.new(secret_key).now)
    end

    return render :action => 'otp_login' unless params[:otp_login].try(:[], :verification_code)

    verification_code = params[:otp_login][:verification_code]
    if Canvas.redis_enabled?
      key = "otp_used:#{@current_user.global_id}:#{verification_code}"
      if Canvas.redis.get(key)
        force_fail = true
      else
        Canvas.redis.setex(key, 10.minutes, '1')
      end
    end

    drift = 30
    # give them 5 minutes to enter an OTP sent via SMS
    drift = 300 if session[:pending_otp_communication_channel_id] ||
        (!session[:pending_otp_secret_key] && @current_user.otp_communication_channel_id)

    if !force_fail && ROTP::TOTP.new(secret_key).verify_with_drift(verification_code, drift)
      if session[:pending_otp_secret_key]
        @current_user.otp_secret_key = session.delete(:pending_otp_secret_key)
        @current_user.otp_communication_channel_id = session.delete(:pending_otp_communication_channel_id)
        @current_user.otp_communication_channel.try(:confirm)
        @current_user.save!
      end

      if params[:otp_login][:remember_me] == '1'
        now = Time.now.utc
        cookies['canvas_otp_remember_me'] = {
              :value => @current_user.otp_secret_key_remember_me_cookie(now),
              :expires => now + 30.days,
              :domain => otp_remember_me_cookie_domain,
              :httponly => true,
              :secure => CANVAS_RAILS2 ? ActionController::Base.session_options[:secure] : CanvasRails::Application.config.session_options[:secure],
              :path => '/login'
            }
      end
      if session.delete(:pending_otp)
        successful_login(@current_user, @current_pseudonym, true)
      else
        flash[:notice] = t 'notices.mfa_complete', "Multi-factor authentication configured"
        redirect_to settings_profile_url
      end
    else
      @cc ||= @current_user.otp_communication_channel if !session[:pending_otp_secret_key]
      flash.now[:error] = t 'errors.invalid_otp', "Invalid verification code, please try again"
    end
  end

  def disable_otp_login
    if params[:user_id] == 'self'
      @user = @current_user
    else
      @user = User.find(params[:user_id])
      return unless @user == @current_user || authorized_action(@user, @current_user, :manage_logins)
    end
    return render_unauthorized_action if @user == @current_user && @user.mfa_settings == :required

    @user.otp_secret_key = nil
    @user.otp_communication_channel = nil
    @user.save!

    render :json => {}
  end

  def successful_login(user, pseudonym, otp_passed = false)
    @current_user = user
    @current_pseudonym = pseudonym
    Auditors::Authentication.record(@current_pseudonym, 'login')

    otp_passed ||= cookies['canvas_otp_remember_me'] &&
        @current_user.validate_otp_secret_key_remember_me_cookie(cookies['canvas_otp_remember_me'])
    if !otp_passed
      mfa_settings = @current_user.mfa_settings
      if (@current_user.otp_secret_key && mfa_settings == :optional) ||
          mfa_settings == :required
        session[:pending_otp] = true
        return otp_login(true)
      end
    end

    session[:require_terms] = true if @domain_root_account.require_acceptance_of_terms?(@current_user)

    respond_to do |format|
      if oauth = session[:oauth2]
        provider = Canvas::Oauth::Provider.new(oauth[:client_id], oauth[:redirect_uri], oauth[:scopes], oauth[:purpose])
        return oauth2_confirmation_redirect(provider)
      elsif session[:course_uuid] && user && (course = Course.find_by_uuid_and_workflow_state(session[:course_uuid], "created"))
        claim_session_course(course, user)
        format.html { redirect_to(course_url(course, :login_success => '1')) }
      elsif session[:confirm]
        format.html { redirect_to(registration_confirmation_path(session.delete(:confirm), :enrollment => session.delete(:enrollment), :login_success => 1, :confirm => (user.id == session.delete(:expected_user_id) ? 1 : nil))) }
      else
        # the URL to redirect back to is stored in the session, so it's
        # assumed that if that URL is found rather than using the default,
        # they must have cookies enabled and we don't need to worry about
        # adding the :login_success param to it.
        format.html { redirect_back_or_default(dashboard_url(:login_success => '1')) }
      end
      format.json { render :json => pseudonym.as_json(:methods => :user_code), :status => :ok }
    end
  end

  def unsuccessful_login(message, refresh = false)
    respond_to do |format|
      flash[:error] = message
      format.html do
        if refresh
          redirect_to login_url
        else
          @errored = true
          @headers = false
          maybe_render_mobile_login :bad_request
        end
      end
      format.json do
        @pseudonym_session ||= @domain_root_account.pseudonym_sessions.new
        @pseudonym_session.errors.add('base', message)
        render :json => @pseudonym_session.errors, :status => :bad_request
      end
    end
  end

  def logout_current_user
    Auditors::Authentication.record(@current_pseudonym, 'logout')
    super
  end

  def oauth2_auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render()
    end

    scopes =  params[:scopes].split(',') if params.key? :scopes
    scopes ||= []

    provider = Canvas::Oauth::Provider.new(params[:client_id], params[:redirect_uri], scopes, params[:purpose])

    return render(:status => 400, :json => { :message => "invalid client_id" }) unless provider.has_valid_key?
    return render(:status => 400, :json => { :message => "invalid redirect_uri" }) unless provider.has_valid_redirect?
    session[:oauth2] = provider.session_hash
    session[:oauth2][:state] = params[:state] if params.key?(:state)

    if @current_pseudonym && !params[:force_login]
      oauth2_confirmation_redirect(provider)
    else
      redirect_to login_url(params.slice(:canvas_login, :pseudonym_session, :force_login))
    end
  end

  def oauth2_confirm
    @provider = Canvas::Oauth::Provider.new(session[:oauth2][:client_id], session[:oauth2][:redirect_uri], session[:oauth2][:scopes], session[:oauth2][:purpose])

    if mobile_device?
      js_env :GOOGLE_ANALYTICS_KEY => Setting.get('google_analytics_key', nil)
      render :layout => 'mobile_auth', :action => 'oauth2_confirm_mobile'
    end
  end

  def oauth2_accept
    redirect_params = final_oauth2_redirect_params(:remember_access => params[:remember_access])
    redirect_params[:state] = session[:oauth2][:state] if session[:oauth2][:state]
    final_oauth2_redirect(session[:oauth2][:redirect_uri], redirect_params)
  end

  def oauth2_deny
    final_oauth2_redirect(session[:oauth2][:redirect_uri], :error => "access_denied")
  end

  def oauth2_token
    if CANVAS_RAILS2
      basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if ActionController::HttpAuthentication::Basic.authorization(request)
    else
      basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if request.authorization
    end

    client_id = params[:client_id].presence || basic_user
    secret = params[:client_secret].presence || basic_pass

    provider = Canvas::Oauth::Provider.new(client_id)
    return render(:status => 400, :json => { :message => "invalid client_id" }) unless provider.has_valid_key?
    return render(:status => 400, :json => { :message => "invalid client_secret" }) unless provider.is_authorized_by?(secret)

    token = provider.token_for(params[:code])
    return render(:status => 400, :json => { :message => "invalid code" }) unless token.is_for_valid_code?

    Canvas::Oauth::Token.expire_code(params[:code])

    render :json => token
  end

  def oauth2_logout
    logout_current_user if params[:expire_sessions]
    return render :json => { :message => "can't delete OAuth access token when not using an OAuth access token" }, :status => 400 unless @access_token
    @access_token.destroy
    render :json => {}
  end

  def oauth2_confirmation_redirect(provider)
    # skip the confirmation page if access is already (or automatically) granted
    if provider.authorized_token?(@current_user)
      final_oauth2_redirect(session[:oauth2][:redirect_uri], final_oauth2_redirect_params)
    else
      redirect_to oauth2_auth_confirm_url
    end
  end

  def final_oauth2_redirect_params(options = {})
    options = {:scopes => session[:oauth2][:scopes], :remember_access => options[:remember_access], :purpose => session[:oauth2][:purpose]}
    code = Canvas::Oauth::Token.generate_code_for(@current_user.global_id, session[:oauth2][:client_id], options)
    redirect_params = { :code => code }
  end

  def final_oauth2_redirect(redirect_uri, opts = {})
    if Canvas::Oauth::Provider.is_oob?(redirect_uri)
      redirect_to oauth2_auth_url(opts)
    else
      has_params = redirect_uri =~ %r{\?}
      redirect_to(redirect_uri + (has_params ? "&" : "?") + opts.to_query)
    end

    session.delete(:oauth2)
  end
end
