#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

  def load_pseudonym_from_policy
    if (policy_encoded = params['Policy']) &&
        (signature = params['Signature']) &&
        signature == Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Attachment.shared_secret, policy_encoded)).gsub(/\n/, '') &&
        (policy = JSON.parse(Base64.decode64(policy_encoded)) rescue nil) &&
        policy['conditions'] &&
        (credential = policy['conditions'].detect{ |cond| cond.is_a?(Hash) && cond.has_key?("pseudonym_id") })
      @policy_pseudonym_id = credential['pseudonym_id']
      # so that we don't have to explicitly skip verify_authenticity_token
      params[self.class.request_forgery_protection_token] ||= form_authenticity_token
    end
    yield if block_given?
  end

  class AccessTokenError < Exception
  end

  class LoggedOutError < Exception
  end

  def self.access_token(request, params_method = :params)
    auth_header = request.authorization
    if auth_header.present? && (header_parts = auth_header.split(' ', 2)) && header_parts[0] == 'Bearer'
      header_parts[1]
    else
      request.send(params_method)['access_token'].presence
    end
  end

  def self.user_id(request)
    request.session[:user_id]
  end

  def load_pseudonym_from_jwt
    return unless api_request?
    token_string = AuthenticationMethods.access_token(request)
    return unless token_string.present?
    begin
      services_jwt = Canvas::Security::ServicesJwt.new(token_string)
      @current_user = User.find(services_jwt.user_global_id)
      @current_pseudonym = @current_user.find_pseudonym_for_account(@domain_root_account, true)
      unless @current_user && @current_pseudonym
        raise AccessTokenError
      end
      if services_jwt.masquerading_user_global_id
        @real_current_user = User.find(services_jwt.masquerading_user_global_id)
        @real_current_pseudonym = @real_current_user.find_pseudonym_for_account(@domain_root_account, true)
        logger.warn "#{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      end
      @authenticated_with_jwt = true
    rescue JSON::JWT::InvalidFormat,             # definitely not a JWT
           Canvas::Security::TokenExpired,       # it could be a JWT, but it's expired if so
           Canvas::Security::InvalidToken,       # Looks like garbage
           Canvas::DynamicSettings::ConsulError  # no config present for talking to consul
      # these will happen for some configurations (no consul)
      # and for some normal use cases (old token, access token),
      # so we can return and move on
      return
    rescue  Faraday::ConnectionFailed,            # consul config present, but couldn't connect
            Faraday::ClientError,                 # connetion established, but something went wrong
            Diplomat::KeyNotFound => exception    # talked to consul, but data missing
      # these are indications of infrastructure of data problems
      # so we should log them for resolution, but recover gracefully
      Canvas::Errors.capture_exception(:jwt_check, exception)
    end
  end

  def load_pseudonym_from_access_token
    return unless api_request? || (params[:controller] == 'oauth2_provider' && params[:action] == 'destroy')

    token_string = AuthenticationMethods.access_token(request)

    if token_string
      @access_token = AccessToken.authenticate(token_string)
      if !@access_token
        raise AccessTokenError
      end

      if !@access_token.authorized_for_account?(@domain_root_account)
        raise AccessTokenError
      end

      @current_user = @access_token.user
      @current_pseudonym = @current_user.find_pseudonym_for_account(@domain_root_account, true)

      unless @current_user && @current_pseudonym
        raise AccessTokenError
      end
      @access_token.used!

      RequestContextGenerator.add_meta_header('at', @access_token.global_id)
      RequestContextGenerator.add_meta_header('dk', @access_token.global_developer_key_id) if @access_token.developer_key_id
    end
  end

  def load_user
    @current_user = @current_pseudonym = nil

    masked_authenticity_token # ensure that the cookie is set

    load_pseudonym_from_jwt

    unless @current_pseudonym.present?
      load_pseudonym_from_access_token
    end

    if !@current_pseudonym
      if @policy_pseudonym_id
        @current_pseudonym = Pseudonym.where(id: @policy_pseudonym_id).first
      elsif @pseudonym_session = PseudonymSession.find
        @current_pseudonym = @pseudonym_session.record

        # if the session was created before the last time the user explicitly
        # logged out (of any session for any of their pseudonyms), invalidate
        # this session
        invalid_before = @current_pseudonym.user.last_logged_out
        # they logged out in the future?!? something's busted; just ignore it -
        # either my clock is off or whoever set this value's clock is off
        invalid_before = nil if invalid_before && invalid_before > Time.now.utc
        if invalid_before &&
          (session_refreshed_at = request.env['encrypted_cookie_store.session_refreshed_at']) &&
          session_refreshed_at < invalid_before

          logger.info "Invalidating session: Session created before user logged out."
          destroy_session
          @current_pseudonym = nil
          if api_request? || request.format.json?
            raise LoggedOutError
          end
        end

        if @current_pseudonym &&
           session[:cas_session] &&
           @current_pseudonym.cas_ticket_expired?(session[:cas_session])

          logger.info "Invalidating session: CAS ticket expired - #{session[:cas_session]}."
          destroy_session
          @current_pseudonym = nil

          raise LoggedOutError if api_request? || request.format.json?

          redirect_to_login
        end
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

    # required by the user throttling middleware
    session[:user_id] = @current_user.global_id if @current_user

    if @current_user && %w(become_user_id me become_teacher become_student).any? { |k| params.key?(k) }
      request_become_user = nil
      if params[:become_user_id]
        request_become_user = User.where(id: params[:become_user_id]).first
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

      if request_become_user && request_become_user.id != session[:become_user_id].to_i && request_become_user.can_masquerade?(@current_user, @domain_root_account)
        params_without_become = params.dup
        params_without_become.delete_if {|k,v| [ 'become_user_id', 'become_teacher', 'become_student', 'me' ].include? k }
        params_without_become[:only_path] = true
        session[:masquerade_return_to] = url_for(params_without_become)
        return redirect_to user_masquerade_url(request_become_user.id)
      end
    end

    as_user_id = api_request? && params[:as_user_id].presence
    as_user_id ||= session[:become_user_id]
    if as_user_id
      begin
        user = api_find(User, as_user_id)
      rescue ActiveRecord::RecordNotFound
      end
      if user && user.can_masquerade?(@current_user, @domain_root_account)
        @real_current_user = @current_user
        @current_user = user
        @real_current_pseudonym = @current_pseudonym
        @current_pseudonym = @current_user.find_pseudonym_for_account(@domain_root_account, true)
        logger.warn "#{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      elsif api_request?
        # fail silently for UI, but not for API
        render :json => {:errors => "Invalid as_user_id"}, :status => :unauthorized
        return false
      end
    end

    @current_user
  end
  private :load_user

  def require_user
    if @current_user && @current_pseudonym
      true
    else
      redirect_to_login
      false
    end
  end
  protected :require_user

  def clean_return_to(url)
    return nil if url.blank?
    begin
      uri = URI.parse(url)
    rescue URI::Error
      return nil
    end
    return nil unless uri.path[0] == '/'
    return "#{request.protocol}#{request.host_with_port}#{uri.path}#{uri.query && "?#{uri.query}"}#{uri.fragment && "##{uri.fragment}"}"
  end

  def return_to(url, fallback)
    url = clean_return_to(url) || clean_return_to(fallback)
    redirect_to url
  end

  def store_location(uri=nil, overwrite=true)
    if overwrite || !session[:return_to]
      uri ||= request.get? ? request.fullpath : request.referrer
      session[:return_to] = clean_return_to(uri)
    end
  end
  protected :store_location

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end
  protected :redirect_back_or_default

  def redirect_to_referrer_or_default(default)
    redirect_to(:back)
  rescue ActionController::RedirectBackError
    redirect_to(default)
  end

  def redirect_to_login
    return unless fix_ms_office_redirects
    respond_to do |format|
      format.html {
        store_location
        flash[:warning] = I18n.t('lib.auth.errors.not_authenticated', "You must be logged in to access this page") unless request.path == '/'
        redirect_to login_url(params.permit(:canvas_login, :authentication_provider))
      }
      format.json { render_json_unauthorized }
    end
  end

  def render_json_unauthorized
    add_www_authenticate_header if api_request? && !@current_user
    if @current_user
      render :json => {
               :status => I18n.t('lib.auth.status_unauthorized', 'unauthorized'),
               :errors => [{ :message => I18n.t('lib.auth.not_authorized', "user not authorized to perform that action") }]
             },
             :status => :unauthorized
    else
      render :json => {
               :status => I18n.t('lib.auth.status_unauthenticated', 'unauthenticated'),
               :errors => [{ :message => I18n.t('lib.auth.authentication_required', "user authorization required") }]
             },
             :status => :unauthorized
    end
  end

  def add_www_authenticate_header
    response['WWW-Authenticate'] = %{Bearer realm="canvas-lms"}
  end

  # Reset the session, and copy the specified keys over to the new session.
  # Please consider the security implications of any keys you copy over.
  def reset_session_saving_keys(*keys)
    # can't use slice, because session has a different ctor than a normal hash
    saved = {}
    keys.each { |k| saved[k] = session[k] if session[k] }
    reset_session
    saved.each_pair { |k, v| session[k] = v }
  end

  # this really belongs on Login::Shared, but is left here for plugins that
  # have always overridden it here
  def delegated_auth_redirect_uri(uri)
    uri
  end

end
