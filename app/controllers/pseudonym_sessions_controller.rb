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
  protect_from_forgery :except => [:create, :destroy, :saml_consume]
  ssl_required :create, :new
  ssl_allowed :saml_consume, :saml_logout
  
  def new
    if @current_user && !params[:re_login]
      redirect_to dashboard_url
      return
    end

    if params[:needs_cookies] == '1'
      @needs_cookies = true
      return render(:template => 'shared/unauthorized', :layout => 'application', :status => :unauthorized)
    end

    @pseudonym_session = PseudonymSession.new
    @headers = false
    @is_delegated = @domain_root_account.delegated_authentication? && !params[:canvas_login]
    @is_cas = @domain_root_account.cas_authentication? && @is_delegated
    @is_saml = @domain_root_account.saml_authentication? && @is_delegated
    if @is_cas && !params[:no_auto]
      if params[:ticket]
        # handle the callback from CAS
        logger.info "Attempting CAS login with ticket #{params[:ticket]} in account #{@domain_root_account.id}"
        st = CASClient::ServiceTicket.new(params[:ticket], login_url)
        begin
          cas_client.validate_service_ticket(st)
        rescue => e
          logger.warn "Failed to validate CAS ticket: #{e.inspect}"
          flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
          redirect_to login_url(:no_auto=>'true')
          return
        end
        if st.is_valid?
          @pseudonym = nil
          @pseudonym = Pseudonym.find_by_unique_id_and_workflow_state(st.response.user, 'active')
          if @pseudonym
            # Successful login and we have a user
            PseudonymSession.create!(@pseudonym, false)
            session[:cas_login] = true
            @user = @pseudonym.login_assertions_for_user rescue nil

            flash[:notice] = 'Login successful.'
            default_url = dashboard_url
            redirect_back_or_default default_url
            return
          else
            logger.warn "Received CAS login for unknown user: #{st.response.user}"
            session[:delegated_message] = "Canvas doesn't have an account for user: #{st.response.user}"
            redirect_to :action => :destroy
            return
          end
        else
          logger.warn "Failed CAS login attempt."
          flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
          redirect_to login_url(:no_auto=>'true')
          return
        end
      end

      # initial session; redirect to CAS
      reset_session
      redirect_to(cas_client.add_service_to_login_url(login_url))
    elsif @is_saml && !params[:no_auto]
      reset_session
      settings = @domain_root_account.account_authorization_config.saml_settings
      request = Onelogin::Saml::AuthRequest.create(settings)
      redirect_to(request)
    else
      render :action => "new"
    end
  end

  def create
    # reset the session id cookie to prevent session fixation.
    reset_session_saving_keys(:return_to)

    # Try to use authlogic's built-in login approach first
    @pseudonym_session = @domain_root_account.pseudonym_sessions.new(params[:pseudonym_session])
    found = @pseudonym_session.save
    
    # TODO: don't allow logins from other root accounts anymore
    # If authlogic fails and this account allows handles from other account,
    # try to log in with a handle from another account
    if !found && !@domain_root_account.require_account_pseudonym? && params[:pseudonym_session]
      valid_alternative = Pseudonym.find_all_by_unique_id_and_workflow_state(params[:pseudonym_session][:unique_id], 'active').find{|p|
        (p.valid_password?(params[:pseudonym_session][:password]) && p.account.password_authentication?) rescue false
      }
      if valid_alternative
        @pseudonym_session = PseudonymSession.new(valid_alternative, params[:pseudonym_session][:remember_me] == "1")
        @pseudonym_session.save
        found = true
      end
    end
    
    @pseudonym = @pseudonym_session && @pseudonym_session.record
    # If the user's account has been deleted, feel free to share that information
    if @pseudonym && (!@pseudonym.user || @pseudonym.user.unavailable?)
      flash[:error] = "That user account has been deleted.  Please contact your system adminitrator to have your account re-activated."
      redirect_to login_url
      return
    end
    
    # Call for some cleanups that should be run when a user logs in
    @user = @pseudonym.login_assertions_for_user rescue nil
    
    # Boy there's a lot of code ended up in here...
    
    # When a user logs in we get acccess to their email address as well as their
    # handle.  If the email address that the authentication system returns is
    # different than the email address that the SIS returns, we should give the
    # user the option to add the new address to their account
    if @pseudonym
      begin
        channel = @pseudonym.ldap_channel_to_possibly_merge(params[:pseudonym_session][:password]) rescue nil
        session[:channel_conflict] = channel if channel && @pseudonym.login_path_to_ignore != channel.path
      rescue => e
        ErrorLogging.log_error(:default, {
          :message => "LDAP email merge, unexpected error",
          :error_type => (e.inspect rescue ''),
          :exception_message => (e.message rescue ''),
          :failure_status => (e.to_s rescue ''),
          :backtrace => (e.backtrace rescue '')
        })
      end
    end

    respond_to do |format|
      # If the user is registered and logged in, redirect them to their dashboard page
      if @user && @user.registered? && found

        flash[:notice] = 'Login successful.'
        if session[:course_uuid] && @user && (course = Course.find_by_uuid_and_workflow_state(session[:course_uuid], "created"))
          claim_session_course(course, @user)
          format.html { redirect_to(course_url(course, :login_success => '1')) }
        else
          # the URL to redirect back to is stored in the session, so it's
          # assumed that if that URL is found rather than using the default,
          # they must have cookies enabled and we don't need to worry about
          # adding the :login_success param to it.
          format.html { redirect_back_or_default(dashboard_url(:login_success => '1')) }
        end
        format.json { render :json => @pseudonym.to_json(:methods => :user_code), :status => :ok }
      # Otherwise re-render the login page to show the error
      else
        flash[:error] = 'Incorrect username and/or password'
        @errored = true
        if @user && @user.creation_pending?
          @user.update_attribute(:workflow_state, "pre_registered")
        end
        @pre_registered = @user if @user && !@user.registered?
        @headers = false
        format.html { render :action => "new", :status => :bad_request }
        format.xml  { render :xml => @pseudonym_session.errors.to_xml }
        format.json { render :json => @pseudonym_session.errors.to_json, :status => :bad_request }
      end
    end
  end
  
  def destroy
    # the saml message has to survive a couple redirects and reset_session calls
    message = session[:delegated_message]
    @pseudonym_session.destroy rescue true 

    if @domain_root_account.saml_authentication? and session[:name_id]
      # logout at the saml identity provider
      # once logged out it'll be redirected to here again
      settings = @domain_root_account.account_authorization_config.saml_settings
      request = Onelogin::Saml::LogOutRequest.create(settings, session)
      reset_session
      session[:delegated_message] = message if message
      redirect_to(request)
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
    
    flash[:notice] = "You are currently logged out"
    flash[:logged_out] = true
    respond_to do |format|
      session[:return_to] = nil      
      if @domain_root_account.delegated_authentication?
        format.html { redirect_to login_url(:no_auto=>'true') }
      else
        format.html { redirect_to login_url }
      end
      format.xml { head :ok }
      format.json { render :json => "OK".to_json, :status => :ok }
    end
  end
  
  def clear_file_session
    session['file_access_user_id'] = nil
    session['file_access_expiration'] = nil
    render :text => "ok"
  end
  
  def saml_consume
    if @domain_root_account.saml_authentication? && params[:SAMLResponse]
      settings = @domain_root_account.account_authorization_config.saml_settings
      response = Onelogin::Saml::Response.new(params[:SAMLResponse])
      response.settings = settings
      response.logger = logger

      logger.info "Attempting SAML login for #{response.name_id} in account #{@domain_root_account.id}"

      if response.is_valid?
        if response.success_status?
          @pseudonym = nil
          @pseudonym = Pseudonym.find_by_unique_id_and_workflow_state(response.name_id, 'active')

          if @pseudonym
            # We have to reset the session again here -- it's possible to do a
            # SAML login without hitting the #new action, depending on the
            # school's setup.
            reset_session
            #Successful login and we have a user
            PseudonymSession.create!(@pseudonym, false)
            @user = @pseudonym.login_assertions_for_user rescue nil

            session[:name_id] = response.name_id
            session[:name_qualifier] = response.name_qualifier
            session[:session_index] = response.session_index

            flash[:notice] = 'Login successful.'
            default_url = dashboard_url
            redirect_back_or_default default_url 
          else
            logger.warn "Received SAML login request for unknown user: #{response.name_id}"
            # the saml message has to survive a couple redirects
            session[:delegated_message] = "Canvas doesn't have an account for user: #{response.name_id}"
            redirect_to :action => :destroy
          end
        elsif response.auth_failure?
          logger.warn "Failed SAML login attempt."
          flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
          redirect_to login_url(:no_auto=>'true')
        else
          logger.warn "Unexpected SAML status code - status code: #{response.status_code rescue ""}"
          logger.warn "Status Message: #{response.status_message rescue ""}"
          logger.warn "SAML Response:";i=0;while temp=params[:SAMLResponse][i...i+1500] do logger.warn temp;i+=1500;end
          redirect_to login_url(:no_auto=>'true')
        end
      else
        logger.error "Failed to verify SAML signature."
        logger.warn "SAML Response:";i=0;while temp=params[:SAMLResponse][i...i+1500] do logger.warn temp;i+=1500;end
        @pseudonym_session.destroy rescue true
        reset_session
        flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
        redirect_to login_url(:no_auto=>'true')
      end
    elsif !params[:SAMLResponse]
      logger.error "saml_consume request with no SAMLResponse parameter"
      @pseudonym_session.destroy rescue true
      reset_session
      flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
      redirect_to login_url(:no_auto=>'true')
    else
      logger.error "Attempted SAML login on non-SAML enabled account."
      @pseudonym_session.destroy rescue true
      reset_session
      flash[:delegated_message] = "There was a problem logging in at #{@domain_root_account.display_name rescue "your institution"}"
      redirect_to login_url(:no_auto=>'true')
    end
  end
  
  def saml_logout
    redirect_to :action => :destroy
  end

  def cas_client
      return @cas_client if @cas_client
      config = { :cas_base_url => @domain_root_account.account_authorization_config.auth_base }
      @cas_client = CASClient::Client.new(config)
  end
  
end
