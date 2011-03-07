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
    if (policy_encoded = params['Policy']) &&
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
    if @current_user && @current_user.unavailable?
      @current_pseudonym = nil
      @current_user = nil 
    end

    if @current_user && %w(become_user_id me become_teacher become_student).any? { |k| params.key?(k) } && Account.site_admin.grants_right?(@current_user, session, :become_user)
      if params[:become_user_id]
        session[:become_user_id] = params[:become_user_id]
      elsif params.keys.include?('me')
        session[:become_user_id] = nil
      elsif params.keys.include?('become_teacher')
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        teacher = course.teachers.first if course
        if teacher
          session[:become_user_id] = teacher.id
        else
          flash[:error] = "No teacher found"
        end
      elsif params.keys.include?('become_student')
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        student = course.students.first if course
        if student
          session[:become_user_id] = student.id
        else
          flash[:error] = "No student found"
        end
      end
    end

    params[:as_user_id] ||= session[:become_user_id]
    if params[:as_user_id] && Account.site_admin.grants_right?(@current_user, session, :become_user)
      @real_current_user = @current_user
      @current_user = User.find(params[:as_user_id]) rescue @current_user
      if @current_user.id != @real_current_user.id && Account.site_admin_user?(@current_user)
        # we can't let even site admins impersonate other site admins, since
        # they may have different permissions.
        logger.warn "#{@real_current_user.name}(#{@real_current_user.id}) attempting to impersonate another site admin (#{@current_user.name}). No dice."
        flash.now[:error] = "You can't impersonate other site admins. Sorry."
        @current_user = @real_current_user
      else
        logger.warn "#{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      end
    end

    @role_lookups = {}
    if @current_user
      @role_lookups = Rails.cache.fetch(['role_lookups', @current_user].cache_key) do
        lookups = {}
        @current_user.current_enrollments.select{|e| e.participating? }.each do |enrollment|
          lookups[enrollment.class.to_s] = true
          lookups["course_#{enrollment.course_id}"] = Enrollment.highest_enrollment_type(lookups["course_#{enrollment.course_id}"], enrollment.class.to_s) 
        end
        lookups
      end
    else
      @userless=true
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
          flash[:notice] = "You must! be logged in to access this page"
          format.html {redirect_to login_url}
          format.json {render :json => {:errors => {:message => "You must be logged in to view this page"}}, :status => :unauthorized}
        end
        return false;
      elsif !@context.users.include?(@current_user)
        respond_to do |format|
          flash[:notice] = "You are not authorized to view this page"
          format.html {redirect_to "/"}
          format.json {render :json => {:errors => {:message => "You are not authorized to view this page"}}, :status => :unauthorized}
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
            flash[:notice] = "You must be logged in to access this page"
            redirect_to login_url
          }
        end
        format.json { render :json => {:errors => {:message => "user authorization required"}}.to_json, :status => :unauthorized}
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

  # Reset the session, and copy the specified keys over to the new session.
  # Please consider the security implications of any keys you copy over.
  def reset_session_saving_keys(*keys)
    # can't use slice, because session has a different ctor than a normal hash
    saved = {}
    keys.each { |k| saved[k] = session[k] }
    reset_session
    session.merge!(saved)
  end

end
