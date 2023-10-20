# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  class AccessTokenError < RuntimeError
  end

  class AccessTokenScopeError < RuntimeError
  end

  class LoggedOutError < RuntimeError
  end

  def self.access_token(request, params_method = :params)
    auth_header = request.authorization
    if auth_header.present? && (header_parts = auth_header.split(" ", 2)) && header_parts[0] == "Bearer"
      header_parts[1]
    else
      request.send(params_method)["access_token"].presence
    end
  end

  def self.user_id(request)
    request.session[:user_id]
  end

  def load_pseudonym_from_inst_access_token(token_string)
    token = ::AuthenticationMethods::InstAccessToken.parse(token_string)
    return false unless token

    auth_context = ::AuthenticationMethods::InstAccessToken.load_user_and_pseudonym_context(token, @domain_root_account)

    raise AccessTokenError unless ::AuthenticationMethods::InstAccessToken.usable_developer_key?(token, @domain_root_account)

    @current_user = auth_context[:current_user]
    @current_pseudonym = auth_context[:current_pseudonym]
    raise AccessTokenError unless @current_user && @current_pseudonym

    if auth_context[:real_current_user]
      @real_current_user = auth_context[:real_current_user]
      @real_current_pseudonym = auth_context[:real_current_pseudonym]
      logger.warn "[AUTH] #{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
    end
    @authenticated_with_jwt = @authenticated_with_inst_access_token = true
  end

  def load_pseudonym_from_jwt
    return unless api_request?

    token_string = AuthenticationMethods.access_token(request)
    return unless token_string.present?
    return if load_pseudonym_from_inst_access_token(token_string)

    begin
      services_jwt = CanvasSecurity::ServicesJwt.new(token_string)
      @current_user = User.find(services_jwt.user_global_id)
      @current_pseudonym = SisPseudonym.for(@current_user, @domain_root_account, type: :implicit, require_sis: false)
      unless @current_user && @current_pseudonym
        raise AccessTokenError
      end

      if services_jwt.masquerading_user_global_id
        @real_current_user = User.find(services_jwt.masquerading_user_global_id)
        @real_current_pseudonym = SisPseudonym.for(@real_current_user, @domain_root_account, type: :implicit, require_sis: false)
        logger.warn "[AUTH] #{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      end
      @authenticated_with_jwt = true
    rescue JSON::JWT::InvalidFormat,       # definitely not a JWT
           Canvas::Security::TokenExpired, # it could be a JWT, but it's expired if so
           Canvas::Security::InvalidToken  # not formatted like a JWT
      # these will happen for some configurations (no consul)
      # and for some normal use cases (old token, access token),
      # so we can return and move on
      nil
    end
  end

  ALLOWED_SCOPE_INCLUDES = %w[uuid].freeze

  def filter_includes(key)
    # no funny business
    params.delete(key) unless params[key].instance_of?(Array)
    return unless params.key?(key)

    params[key] &= ALLOWED_SCOPE_INCLUDES
  end

  def validate_scopes
    return unless @access_token

    developer_key = @access_token.developer_key
    request_method = (request.method.casecmp("HEAD") == 0) ? "GET" : request.method.upcase

    if developer_key.try(:require_scopes)
      scope_patterns = @access_token.url_scopes_for_method(request_method).concat(AccessToken.always_allowed_scopes)
      if scope_patterns.any? { |scope| scope =~ request.path }
        unless developer_key.try(:allow_includes)
          filter_includes(:include)
          filter_includes(:includes)
        end
      else
        raise AccessTokenScopeError
      end
    end
  end

  def self.graphql_type_authorized?(access_token, type)
    if access_token&.developer_key&.require_scopes
      # allowing the root query type for now, but any other type is forbidden
      type == "Query"
    else
      true
    end
  end

  def load_pseudonym_from_access_token
    return unless api_request? ||
                  (params[:controller] == "oauth2_provider" && params[:action] == "destroy") ||
                  (params[:controller] == "login" && params[:action] == "session_token")

    token_string = AuthenticationMethods.access_token(request)

    if token_string
      @access_token = AccessToken.authenticate(token_string)
      raise AccessTokenError unless @access_token

      account = access_token_account(@domain_root_account, @access_token)
      raise AccessTokenError unless @access_token.authorized_for_account?(account)

      @current_user = @access_token.user
      @real_current_user = @access_token.real_user
      @real_current_pseudonym = SisPseudonym.for(@real_current_user, @domain_root_account, type: :implicit, require_sis: false) if @real_current_user
      @current_pseudonym = SisPseudonym.for(@current_user, @domain_root_account, type: :implicit, require_sis: false)
      @current_pseudonym = nil if (@current_pseudonym&.suspended? && !@real_current_pseudonym) || @real_current_pseudonym&.suspended?

      raise AccessTokenError unless @current_user && @current_pseudonym

      validate_scopes
      @access_token.used!

      RequestContext::Generator.add_meta_header("at", @access_token.global_id)
      RequestContext::Generator.add_meta_header("dk", @access_token.global_developer_key_id) if @access_token.developer_key_id
    end
  end

  def access_token_account(domain_root_account, access_token)
    dev_key_account_id = access_token.dev_key_account_id
    if dev_key_account_id.blank? || domain_root_account.id == dev_key_account_id
      domain_root_account
    else
      get_context
      (@context && Context.get_account(@context)) || domain_root_account
    end
  end

  def load_user
    @current_user = @current_pseudonym = nil

    masked_authenticity_token # ensure that the cookie is set

    load_pseudonym_from_jwt
    load_pseudonym_from_access_token unless @current_pseudonym.present?

    unless @current_pseudonym
      if @policy_pseudonym_id
        @current_pseudonym = Pseudonym.where(id: @policy_pseudonym_id).first
      else
        @pseudonym_session = PseudonymSession.find_with_validation
        if @pseudonym_session
          @current_pseudonym = @pseudonym_session.record
          @current_pseudonym.user.reload if @current_pseudonym.shard != @current_pseudonym.user.shard

          # if the session was created before the last time the user explicitly
          # logged out (of any session for any of their pseudonyms), invalidate
          # this session
          invalid_before = @current_pseudonym.user.last_logged_out
          # they logged out in the future?!? something's busted; just ignore it -
          # either my clock is off or whoever set this value's clock is off
          invalid_before = nil if invalid_before && invalid_before > Time.now.utc
          if invalid_before &&
             (session_refreshed_at = request.env["encrypted_cookie_store.session_refreshed_at"]) &&
             session_refreshed_at < invalid_before

            logger.info "[AUTH] Invalidating session: Session created before user logged out."
            invalidate_session
            return
          end

          if @current_pseudonym &&
             session[:cas_session] &&
             @current_pseudonym.cas_ticket_expired?(session[:cas_session])

            logger.info "[AUTH] Invalidating session: CAS ticket expired - #{session[:cas_session]}."
            invalidate_session
            return
          end

          if @current_pseudonym.suspended?
            logger.info "[AUTH] Invalidating session: Pseudonym is suspended."
            invalidate_session
            return
          end
        end
      end

      if params[:login_success] == "1" && !@current_pseudonym
        # they just logged in successfully, but we can't find the pseudonym now?
        # sounds like somebody hates cookies.
        return redirect_to(login_url(needs_cookies: "1"))
      end

      @current_user = @current_pseudonym&.user
    end

    logger.info "[AUTH] inital load: pseud -> #{@current_pseudonym&.id}, user -> #{@current_user&.id}"
    if @current_user&.unavailable?
      logger.info "[AUTH] Invalid request: User is currently UNAVAILABLE"
      @current_pseudonym = nil
      @current_user = nil
    end

    # required by the user throttling middleware
    session[:user_id] = @current_user.global_id if @current_user

    if @current_user && %w[become_user_id me become_teacher become_student].any? { |k| params.key?(k) }
      request_become_user = nil
      if params[:become_user_id]
        request_become_user = User.where(id: params[:become_user_id]).first
      elsif params.key?("me")
        request_become_user = @current_user
      elsif params.key?("become_teacher")
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        teacher = course.teachers.first if course
        if teacher
          request_become_user = teacher
        else
          flash[:error] = I18n.t("lib.auth.errors.teacher_not_found", "No teacher found")
        end
      elsif params.key?("become_student")
        course = Course.find(params[:course_id] || params[:id]) rescue nil
        student = course.students.first if course
        if student
          request_become_user = student
        else
          flash[:error] = I18n.t("lib.auth.errors.student_not_found", "No student found")
        end
      end

      if request_become_user && request_become_user.id != session[:become_user_id].to_i && request_become_user.can_masquerade?(@current_user, @domain_root_account)
        params_without_become = params.except("become_user_id", "become_teacher", "become_student", "me")
        params_without_become[:only_path] = true
        session[:masquerade_return_to] = url_for(params_without_become.to_unsafe_h)
        return redirect_to user_masquerade_url(request_become_user.id)
      end
    end

    as_user_id = api_request? && params[:as_user_id].presence
    as_user_id ||= session[:become_user_id]
    if as_user_id
      begin
        user = api_find(User, as_user_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
      if user && @real_current_user
        if @current_user != user
          # if we're already masquerading from an access token, and now try to
          # masquerade as someone else
          render json: { errors: "Cannot change masquerade" }, status: :unauthorized
          return false
          # else: they do match, everything is already set
        end
        logger.warn "[AUTH] #{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url} via masquerade token"
      elsif user&.can_masquerade?(@current_user, @domain_root_account)
        @real_current_user = @current_user
        @current_user = user
        @real_current_pseudonym = @current_pseudonym
        @current_pseudonym = SisPseudonym.for(@current_user, @domain_root_account, type: :implicit, require_sis: false)
        logger.warn "[AUTH] #{@real_current_user.name}(#{@real_current_user.id}) impersonating #{@current_user.name} on page #{request.url}"
      elsif api_request? # fail silently for UI, but not for API
        result = { errors: "Invalid as_user_id" }
        if user&.deleted? && user.merged_into_user_id && user.grants_right?(@current_user, :read)
          result[:merged_into_user_id] = user.merged_into_user_id
        end
        # this should maybe be 404, not 401, but we can't change it now
        render json: result, status: :unauthorized
        return false
      end
    end

    logger.info "[AUTH] final user: #{@current_user&.id}"
    if Sentry.initialized? && !Rails.env.test?
      Sentry.set_user({ id: @current_user&.global_id, ip_address: request.remote_ip }.compact)
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

  def require_non_jwt_auth
    if @authenticated_with_jwt
      render(
        json: { error: "cannot generate a JWT when authorized by a JWT" },
        status: :forbidden
      )
    end
  end

  def clean_return_to(url)
    return nil if url.blank?

    begin
      uri = URI.parse(url)
    rescue URI::Error
      return nil
    end
    return nil unless uri.path && uri.path[0] == "/"
    return "#{request.protocol}#{request.host_with_port}#{uri.path.sub(%r{/download$}, "")}" if %r{/files/(\d+~)?\d+/download$}.match?(uri.path)

    "#{request.protocol}#{request.host_with_port}#{uri.path}#{uri.query && "?#{uri.query}"}#{uri.fragment && "##{uri.fragment}"}"
  end

  def return_to(url, fallback)
    url = clean_return_to(url) || clean_return_to(fallback)
    redirect_to url
  end

  def store_location(uri = nil, overwrite = true)
    if overwrite || !session[:return_to]
      uri ||= request.get? ? request.fullpath : request.referer
      session[:return_to] = clean_return_to(uri)
    end
  end
  protected :store_location

  def redirect_back_or_default(default)
    session.delete(:return_to) || default
  end
  protected :redirect_back_or_default

  def redirect_to_referrer_or_default(default)
    redirect_back(fallback_location: default)
  end

  def redirect_to_login
    return unless fix_ms_office_redirects

    respond_to do |format|
      format.any(:html, :pdf) do
        store_location
        flash[:warning] = I18n.t("lib.auth.errors.not_authenticated", "You must be logged in to access this page") unless request.path == "/"
        redirect_to login_url(params.permit(:canvas_login, :authentication_provider))
      end
      format.json { render_json_unauthorized }
      format.all { render plain: "Unauthenticated", status: :unauthorized }
    end
  end

  def render_json_unauthorized
    add_www_authenticate_header if api_request? && !@current_user

    if Account.site_admin.feature_enabled?(:api_auth_error_updates)
      if @current_user
        code = :forbidden
        status = "unauthorized"
        message = I18n.t("lib.auth.not_authorized", "user not authorized to perform that action")
      else
        code = :unauthorized
        status = "unauthenticated"
        message = I18n.t("lib.auth.authentication_required", "user authorization required")
      end
    else
      code = :unauthorized
      if @current_user
        status = I18n.t("lib.auth.status_unauthorized", "unauthorized")
        message = I18n.t("lib.auth.not_authorized", "user not authorized to perform that action")
      else
        status = I18n.t("lib.auth.status_unauthenticated", "unauthenticated")
        message = I18n.t("lib.auth.authentication_required", "user authorization required")
      end
    end
    render status: code, json: { status:, errors: [{ message: }] }
  end

  def add_www_authenticate_header
    response["WWW-Authenticate"] = %(Bearer realm="canvas-lms")
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

  def invalidate_session
    destroy_session
    @current_pseudonym = nil

    raise LoggedOutError if api_request? || request.format.json?

    redirect_to_login unless login_request? && params[:action] == "new"
  end

  def login_request?
    params[:controller]&.start_with?("login")
  end
end
