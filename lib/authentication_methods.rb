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

module AuthenticationMethods
  
  def authorized(*groups)
    authorized_roles = groups
    return true
  end
  
  def authorized_roles
    @authorized_roles ||= []
  end
  
  def consume_authorized_roles
    authorized_roles = []
  end
  
  def load_pseudonym_from_policy
    skip_session_save = false
    if session.to_hash.empty? && # if there's already some session data, defer to normal auth
        (policy_encoded = params['Policy']) &&
        (signature = params['Signature']) &&
        signature == Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), Attachment.shared_secret, policy_encoded)).gsub(/\n/, '') &&
        (policy = JSON.parse(Base64.decode64(policy_encoded)) rescue nil) &&
        policy['conditions'] &&
        (credential = policy['conditions'].detect{ |cond| cond.is_a?(Hash) && cond.has_key?("pseudonym_id") })
      skip_session_save = true
      @policy_pseudonym_id = credential['pseudonym_id']
      # so that we don't have to explicitly skip verify_authenticity_token
      params[self.class.request_forgery_protection_token] ||= form_authenticity_token
    end
    yield if block_given?
    session.destroy if skip_session_save
  end

  def load_user
    if params[:access_token] && api_request?
      @access_token = AccessToken.find_by_token(params[:access_token])
      @developer_key = @access_token.try(:developer_key)
      if !@access_token.try(:usable?)
        render :json => {:errors => "Invalid access token"}, :status => :bad_request
        return false
      end
      @access_token.used!
      @current_user = @access_token.user
      @current_pseudonym = @current_user.pseudonym
    else
      @pseudonym_session = @domain_root_account.pseudonym_session_scope.find
      key = @pseudonym_session.send(:session_credentials)[1] rescue nil
      if key
        @current_pseudonym = Pseudonym.find_cached(['_pseudonym_lookup', key].cache_key) do
          @pseudonym_session && @pseudonym_session.record
        end
      elsif @policy_pseudonym_id
        @current_pseudonym = Pseudonym.find_by_id(@policy_pseudonym_id)
      else
        @current_pseudonym = @pseudonym_session && @pseudonym_session.record
      end
      if params[:login_success] == '1' && !@current_pseudonym
        # they just logged in successfully, but we can't find the pseudonym now?
        # sounds like somebody hates cookies.
        return redirect_to(login_url(:needs_cookies => '1'))
      end
      @current_user = @current_pseudonym && @current_pseudonym.user
    end
    if @current_user && @current_user.unavailable?
      @current_pseudonym = nil
      @current_user = nil 
    end

    if @current_user && %w(become_user_id me become_teacher become_student).any? { |k| params.key?(k) }
      request_become_user = nil
      if params[:become_user_id]
        request_become_user = User.find_by_id(params[:become_user_id])
      elsif params.keys.include?('me')
        request_become_user = @current_user
      elsif params.keys.include?('become_teacher')
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        teacher = course.teachers.first if course
        if teacher
          request_become_user = teacher
        else
          flash[:error] = I18n.t('lib.auth.errors.teacher_not_found', "No teacher found")
        end
      elsif params.keys.include?('become_student')
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        student = course.students.first if course
        if student
          request_become_user = student
        else
          flash[:error] = I18n.t('lib.auth.errors.student_not_found', "No student found")
        end
      end

      if request_become_user && request_become_user.id != session[:become_user_id].to_i && request_become_user.grants_right?(@current_user, session, :become_user)
        params_without_become = params.dup
        params_without_become.delete_if {|k,v| [ 'become_user_id', 'become_teacher', 'become_student', 'me' ].include? k }
        params_without_become[:only_path] = true
        session[:masquerade_return_to] = url_for(params_without_become)
        return redirect_to user_masquerade_url(request_become_user.id)
      end
    end

    if session[:become_user_id]
      user = User.find_by_id(session[:become_user_id])
      if user && user.grants_right?(@current_user, session, :become_user)
        @real_current_user = @current_user
        @current_user = user
        logger.warn "#{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      end
    end

    @current_user
  end
  private :load_user
  
  def require_user_for_context
    get_context
    if !@context
      redirect_to '/'
      return false
    elsif @context.state == 'available'
      if !@current_user 
        respond_to do |format|
          store_location
          flash[:notice] = I18n.t('lib.auth.errors.not_authenticated', "You must be logged in to access this page")
          format.html {redirect_to login_url}
          format.json {render :json => {:errors => {:message => I18n.t('lib.auth.errors.not_authenticated', "You must be logged in to access this page")}}, :status => :unauthorized}
        end
        return false;
      elsif !@context.users.include?(@current_user)
        respond_to do |format|
          flash[:notice] = I18n.t('lib.auth.errors.not_authorized', "You are not authorized to view this page")
          format.html {redirect_to "/"}
          format.json {render :json => {:errors => {:message => I18n.t('lib.auth.errors.not_authorized', "You are not authorized to view this page")}}, :status => :unauthorized}
        end
        return false
      end
    end
  end
  protected :require_user_for_context
  
  def require_user
    unless @current_pseudonym && @current_user
      respond_to do |format|
        if request.path.match(/getting_started/)
          format.html {
            store_location
            redirect_to register_url
          }
        else
          format.html {
            store_location
            flash[:notice] = I18n.t('lib.auth.errors.not_authenticated', "You must be logged in to access this page") unless request.path == '/'
            redirect_to login_url
          }
        end
        format.json { render :json => {:errors => {:message => I18n.t('lib.auth.authentication_required', "user authorization required")}}.to_json, :status => :unauthorized}
      end
      return false
    end
  end
  protected :require_user

  def store_location(uri=nil, overwrite=true)
    if overwrite || !session[:return_to]
      session[:return_to] = uri || request.request_uri
    end
  end
  protected :store_location

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  protected :redirect_back_or_default

  def redirect_to_referrer_or_default(default)
    redirect_to(:back)
  rescue ActionController::RedirectBackError
    redirect_to(default)
  end

  # Reset the session, and copy the specified keys over to the new session.
  # Please consider the security implications of any keys you copy over.
  def reset_session_saving_keys(*keys)
    # can't use slice, because session has a different ctor than a normal hash
    saved = {}
    keys.each { |k| saved[k] = session[k] }
    reset_session
    session.merge!(saved)
  end

  def initiate_delegated_login
    is_delegated = @domain_root_account.delegated_authentication? && !params[:canvas_login]
    is_cas = @domain_root_account.cas_authentication? && is_delegated
    is_saml = @domain_root_account.saml_authentication? && is_delegated
    if is_cas
      initiate_cas_login
      return true
    elsif is_saml
      initiate_saml_login
      return true
    end
    false
  end

  def initiate_cas_login(cas_client = nil)
    reset_session_saving_keys(:return_to)
    if @domain_root_account.account_authorization_config.log_in_url.present?
      session[:exit_frame] = true
      redirect_to(@domain_root_account.account_authorization_config.log_in_url)
    else
      config = { :cas_base_url => @domain_root_account.account_authorization_config.auth_base }
      cas_client ||= CASClient::Client.new(config)
      redirect_to(cas_client.add_service_to_login_url(login_url))
    end
  end

  def initiate_saml_login
    reset_session_saving_keys(:return_to)
    settings = @domain_root_account.account_authorization_config.saml_settings
    request = Onelogin::Saml::AuthRequest.create(settings)
    redirect_to(request)
  end

end
