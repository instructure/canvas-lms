#
# Copyright (C) 2011 Instructure, Inc.
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
  protect_from_forgery :except => [:create, :destroy, :saml_consume, :oauth2_token]
  before_filter :forbid_on_files_domain, :except => [ :clear_file_session ]

  def new
    if @current_user && !params[:re_login] && !params[:confirm] && !params[:expected_user_id]
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

    @pseudonym_session = PseudonymSession.new
    @headers = false
    @is_delegated = @domain_root_account.delegated_authentication? && !params[:canvas_login]
    @is_cas = @domain_root_account.cas_authentication? && @is_delegated
    @is_saml = @domain_root_account.saml_authentication? && @is_delegated
    if @is_cas && !params[:no_auto]
      if session[:exit_frame]
        session.delete(:exit_frame)
        render :template => 'shared/exit_frame', :layout => false, :locals => {
          :url => login_url(params)
        }
        return
      elsif params[:ticket]
        # handle the callback from CAS
        logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
        st = CASClient::ServiceTicket.new(params[:ticket], login_url)
        begin
          cas_client.validate_service_ticket(st)
        rescue => e
          logger.warn "Failed to validate CAS ticket: #{e.inspect}"
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to login_url(:no_auto=>'true')
          return
        end
        if st.is_valid?
          @pseudonym = nil
          @pseudonym = @domain_root_account.pseudonyms.custom_find_by_unique_id(st.response.user)
          if @pseudonym
            # Successful login and we have a user
            @domain_root_account.pseudonym_sessions.create!(@pseudonym, false)
            session[:cas_login] = true
            @user = @pseudonym.login_assertions_for_user

            successful_login(@user, @pseudonym)
            return
          else
            logger.warn "Received CAS login for unknown user: #{st.response.user}"
            reset_session
            session[:delegated_message] = t 'errors.no_matching_user', "Canvas doesn't have an account for user: %{user}", :user => st.response.user
            redirect_to(cas_client.logout_url(login_url :no_auto => true))
            return
          end
        else
          logger.warn "Failed CAS login attempt."
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to login_url(:no_auto=>'true')
          return
        end
      end

      initiate_cas_login(cas_client)
    elsif @is_saml && !params[:no_auto]
      initiate_saml_login(request.host_with_port)
    else
      flash[:delegated_message] = session.delete :delegated_message if session[:delegated_message]
      maybe_render_mobile_login
    end
  end

  def maybe_render_mobile_login(status = nil)
    if request.user_agent.to_s =~ /ipod|iphone/i
      @login_handle_name = @domain_root_account.login_handle_name rescue AccountAuthorizationConfig.default_login_handle_name
      @login_handle_is_email = @login_handle_name == AccountAuthorizationConfig.default_login_handle_name
      @shared_js_vars = {
        :GOOGLE_ANALYTICS_KEY => Setting.get_cached('google_analytics_key', nil),
        :RESET_SENT =>  t("password_confirmation_sent", "Password confirmation sent. Make sure you check your spam box."),
        :RESET_ERROR =>  t("password_confirmation_error", "Error sending request.")
      }
      render :template => 'pseudonym_sessions/mobile_login', :layout => false, :status => status
    else
      @request = request
      render :action => 'new', :status => status
    end
  end

  def create
    # reset the session id cookie to prevent session fixation.
    reset_session_for_login

    # Try to use authlogic's built-in login approach first
    @pseudonym_session = @domain_root_account.pseudonym_sessions.new(params[:pseudonym_session])
    @pseudonym_session.remote_ip = request.remote_ip
    found = @pseudonym_session.save

    if @pseudonym_session.too_many_attempts?
      flash[:error] = t 'errors.max_attempts', "Too many failed login attempts. Please try again later or contact your system administrator."
      redirect_to login_url
      return
    end

    if !found && params[:pseudonym_session]
      if pseudonym = Pseudonym.authenticate(params[:pseudonym_session], @domain_root_account.trusted_account_ids)
        @pseudonym_session = PseudonymSession.new(pseudonym, params[:pseudonym_session][:remember_me] == "1")
        @pseudonym_session.save
        found = true
      end
    end

    @pseudonym = @pseudonym_session && @pseudonym_session.record
    # If the user's account has been deleted, feel free to share that information
    if @pseudonym && (!@pseudonym.user || @pseudonym.user.unavailable?)
      flash[:error] = t 'errors.user_deleted', "That user account has been deleted.  Please contact your system administrator to have your account re-activated."
      redirect_to login_url
      return
    end

    # Call for some cleanups that should be run when a user logs in
    @user = @pseudonym.login_assertions_for_user if found

    # If the user is registered and logged in, redirect them to their dashboard page
    if found
      successful_login(@user, @pseudonym)
    # Otherwise re-render the login page to show the error
    else
      respond_to do |format|
        flash[:error] = t 'errors.invalid_credentials', "Incorrect username and/or password"
        @errored = true
        @pre_registered = @user if @user && !@user.registered?
        @headers = false
        format.html { maybe_render_mobile_login :bad_request }
        format.json { render :json => @pseudonym_session.errors.to_json, :status => :bad_request }
      end
    end
  end

  def destroy
    # the saml message has to survive a couple redirects and reset_session calls
    message = session[:delegated_message]
    @pseudonym_session.destroy rescue true

    if @domain_root_account.saml_authentication? and session[:saml_unique_id]
      # logout at the saml identity provider
      # once logged out it'll be redirected to here again
      aac = @domain_root_account.account_authorization_config
      settings = aac.saml_settings(request.host_with_port)
      request = Onelogin::Saml::LogOutRequest.new(settings, session)
      forward_url = request.generate_request
      
      if aac.debugging? && aac.debug_get(:logged_in_user_id) == @current_user.id
        aac.debug_set(:logout_request_id, request.id)
        aac.debug_set(:logout_to_idp_url, forward_url)
        aac.debug_set(:logout_to_idp_xml, request.request_xml)
        aac.debug_set(:debugging, t('debug.logout_redirect', "LogoutRequest sent to IdP"))
      end
      
      reset_session
      session[:delegated_message] = message if message
      redirect_to(forward_url)
      return
    elsif @domain_root_account.cas_authentication? and session[:cas_login]
      reset_session
      session[:delegated_message] = message if message
      redirect_to(cas_client.logout_url(login_url))
      return
    else
      reset_session
      flash[:delegated_message] = message if message
    end

    flash[:notice] = t 'notices.logged_out', "You are currently logged out"
    flash[:logged_out] = true
    respond_to do |format|
      session.delete(:return_to)
      if @domain_root_account.delegated_authentication?
        format.html { redirect_to login_url(:no_auto=>'true') }
      else
        format.html { redirect_to login_url }
      end
      format.json { render :json => "OK".to_json, :status => :ok }
    end
  end

  def clear_file_session
    session.delete('file_access_user_id')
    session.delete('file_access_expiration')
    render :text => "ok"
  end

  def saml_consume
    if @domain_root_account.saml_authentication? && params[:SAMLResponse]
      # Break up the SAMLResponse into chunks for logging (a truncated version was probably already
      # logged with the request when using syslog)
      chunks = params[:SAMLResponse].scan(/.{1,1024}/)
      chunks.each_with_index do |chunk, idx|
        logger.info "SAMLResponse[#{idx+1}/#{chunks.length}] #{chunk}"
      end

      aac = @domain_root_account.account_authorization_config
      settings = aac.saml_settings(request.host_with_port)
      response = saml_response(params[:SAMLResponse], settings)

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

            session[:saml_unique_id] = unique_id
            session[:name_id] = response.name_id
            session[:name_qualifier] = response.name_qualifier
            session[:session_index] = response.session_index
            session[:return_to] = params[:RelayState] if params[:RelayState] && params[:RelayState] =~ /\A\/(\z|[^\/])/

            successful_login(@user, @pseudonym)
          else
            message = "Received SAML login request for unknown user: #{unique_id}"
            logger.warn message
            aac.debug_set(:canvas_login_fail_message, message) if debugging
            # the saml message has to survive a couple redirects
            session[:delegated_message] = t 'errors.no_matching_user', "Canvas doesn't have an account for user: %{user}", :user => unique_id
            redirect_to :action => :destroy
          end
        elsif response.auth_failure?
          message = "Failed to log in correctly at IdP"
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to login_url(:no_auto=>'true')
        elsif response.no_authn_context?
          message = "Attempted SAML login for unsupported authn_context at IdP."
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
          redirect_to login_url(:no_auto=>'true')
        else
          message = "Unexpected SAML status code - status code: #{response.status_code rescue ""} - Status Message: #{response.status_message rescue ""}"
          logger.warn message
          aac.debug_set(:canvas_login_fail_message, message) if debugging
          redirect_to login_url(:no_auto=>'true')
        end
      else
        if debugging
          aac.debug_set(:is_valid_login_response, 'false')
          aac.debug_set(:login_response_validation_error, response.validation_error)
        end
        logger.error "Failed to verify SAML signature."
        @pseudonym_session.destroy rescue true
        reset_session
        flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
        redirect_to login_url(:no_auto=>'true')
      end
    elsif !params[:SAMLResponse]
      logger.error "saml_consume request with no SAMLResponse parameter"
      @pseudonym_session.destroy rescue true
      reset_session
      flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
      redirect_to login_url(:no_auto=>'true')
    else
      logger.error "Attempted SAML login on non-SAML enabled account."
      @pseudonym_session.destroy rescue true
      reset_session
      flash[:delegated_message] = t 'errors.login_error', "There was a problem logging in at %{institution}", :institution => @domain_root_account.display_name
      redirect_to login_url(:no_auto=>'true')
    end
  end

  def saml_logout
    if @domain_root_account.saml_authentication? && params[:SAMLResponse]
      aac = @domain_root_account.account_authorization_config
      settings = aac.saml_settings(request.host_with_port)
      response = Onelogin::Saml::LogoutResponse.new(params[:SAMLResponse], settings)
      response.logger = logger

      if aac.debugging? && aac.debug_get(:logout_request_id) == response.in_response_to
        aac.debug_set(:idp_logout_response_encoded, params[:SAMLResponse])
        aac.debug_set(:idp_logout_response_xml_encrypted, response.xml)
        aac.debug_set(:idp_logout_in_response_to, response.in_response_to)
        aac.debug_set(:idp_logout_destination, response.destination)
        aac.debug_set(:debugging, t('debug.logout_redirect_from_idp', "Received LogoutResponse from IdP"))
      end
    end
    redirect_to :action => :destroy
  end

  def cas_client
    return @cas_client if @cas_client
    config = { :cas_base_url => @domain_root_account.account_authorization_config.auth_base }
    @cas_client = CASClient::Client.new(config)
  end

  def saml_response(raw_response, settings)
    response = Onelogin::Saml::Response.new(raw_response, settings)
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

  def successful_login(user, pseudonym)
    respond_to do |format|
      flash[:notice] = t 'notices.login_success', "Login successful." unless flash[:error]
      if session[:oauth2]
        return redirect_to(oauth2_auth_confirm_url)
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
      format.json { render :json => pseudonym.to_json(:methods => :user_code), :status => :ok }
    end
  end

  OAUTH2_OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  def oauth2_auth
    if params[:code] || params[:error]
      # hopefully the user never sees this, since it's an oob response and the
      # browser should be closed automatically. but we'll at least display
      # something basic.
      return render()
    end

    @key = DeveloperKey.find_by_id(params[:client_id]) if params[:client_id].present?
    unless @key
      return render(:status => 400, :json => { :message => "invalid client_id" })
    end

    redirect_uri = params[:redirect_uri].presence || ""
    unless redirect_uri == OAUTH2_OOB_URI || @key.redirect_domain_matches?(redirect_uri)
      return render(:status => 400, :json => { :message => "invalid redirect_uri" })
    end

    session[:oauth2] = { :client_id => @key.id, :redirect_uri => redirect_uri }
    if @current_pseudonym
      redirect_to oauth2_auth_confirm_url
    else
      redirect_to login_url
    end
  end

  def oauth2_confirm
    @key = DeveloperKey.find(session[:oauth2][:client_id])
    @app_name = @key.name.presence || @key.user_name.presence || @key.email.presence || t(:default_app_name, "Third-Party Application")
  end

  def oauth2_accept
    # now generate the temporary code, and respond/redirect
    code = ActiveSupport::SecureRandom.hex(64)
    code_data = { 'user' => @current_user.id, 'client_id' => session[:oauth2][:client_id] }
    Canvas.redis.setex("oauth2:#{code}", 1.day, code_data.to_json)
    final_oauth2_redirect(session[:oauth2][:redirect_uri], :code => code)
    session.delete(:oauth2)
  end

  def oauth2_deny
    final_oauth2_redirect(session[:oauth2][:redirect_uri], :error => "access_denied")
    session.delete(:oauth2)
  end

  def oauth2_token
    basic_user, basic_pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request) if ActionController::HttpAuthentication::Basic.authorization(request)

    client_id = params[:client_id].presence || basic_user
    key = DeveloperKey.find_by_id(client_id) if client_id.present?
    unless key
      return render(:status => 400, :json => { :message => "invalid client_id" })
    end

    secret = params[:client_secret].presence || basic_pass
    unless secret == key.api_key
      return render(:status => 400, :json => { :message => "invalid client_secret" })
    end

    code = params[:code]
    code_data = JSON.parse(Canvas.redis.get("oauth2:#{code}").presence || "{}")
    unless code_data.present? && code_data['client_id'] == key.id
      return render(:status => 400, :json => { :message => "invalid code" })
    end

    user = User.find(code_data['user'])
    token = AccessToken.create!(:user => user, :developer_key => key)
    render :json => {
      'access_token' => token.token,
      'user' => user.as_json(:only => [:id, :name], :include_root => false),
    }
  end

  def final_oauth2_redirect(redirect_uri, opts = {})
    if redirect_uri == OAUTH2_OOB_URI
      redirect_to oauth2_auth_url(opts)
    else
      has_params = redirect_uri =~ %r{\?}
      redirect_to(redirect_uri + (has_params ? "&" : "?") + opts.to_query)
    end
  end
end
