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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  class << self
    [:before, :after, :around,
     :skip_before, :skip_after, :skip_around,
     :prepend_before, :prepend_after, :prepend_around].each do |type|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{type}_filter(*)
          raise "Please use #{type}_action instead of #{type}_filter"
        end
      RUBY
    end
  end

  layout :application_layout

  attr_accessor :active_tab
  attr_reader :context

  include Api
  include LocaleSelection
  include Api::V1::User
  include Api::V1::WikiPage
  include LegalInformationHelper
  around_action :set_locale
  around_action :enable_request_cache
  around_action :batch_statsd
  around_action :report_to_datadog

  helper :all

  include AuthenticationMethods

  include Canvas::RequestForgeryProtection
  protect_from_forgery with: :exception

  # load_user checks masquerading permissions, so this needs to be cleared first
  before_action :clear_cached_contexts
  prepend_before_action :load_user, :load_account
  # make sure authlogic is before load_user
  skip_before_action :activate_authlogic
  prepend_before_action :activate_authlogic

  before_action :check_pending_otp
  before_action :set_user_id_header
  before_action :set_time_zone
  before_action :set_page_view
  before_action :require_reacceptance_of_terms
  before_action :clear_policy_cache
  before_action :setup_live_events_context
  after_action :log_page_view
  after_action :discard_flash_if_xhr
  after_action :cache_buster
  before_action :initiate_session_from_token
  # Yes, we're calling this before and after so that we get the user id logged
  # on events that log someone in and log someone out.
  after_action :set_user_id_header
  before_action :fix_xhr_requests
  before_action :init_body_classes
  after_action :set_response_headers
  after_action :update_enrollment_last_activity_at

  add_crumb(proc {
    title = I18n.t('links.dashboard', 'My Dashboard')
    crumb = <<-END
      <i class="icon-home"
         title="#{title}">
        <span class="screenreader-only">#{title}</span>
      </i>
    END

    crumb.html_safe
  }, :root_path, class: 'home')

  ##
  # Sends data from rails to JavaScript
  #
  # The data you send will eventually make its way into the view by simply
  # calling `to_json` on the data.
  #
  # It won't allow you to overwrite a key that has already been set
  #
  # Please use *ALL_CAPS* for keys since these are considered constants
  # Also, please don't name it stuff from JavaScript's Object.prototype
  # like `hasOwnProperty`, `constructor`, `__defineProperty__` etc.
  #
  # This method is available in controllers and views
  #
  # example:
  #
  #     # ruby
  #     js_env :FOO_BAR => [1,2,3], :COURSE => @course
  #
  #     # coffeescript
  #     require ['ENV'], (ENV) ->
  #       ENV.FOO_BAR #> [1,2,3]
  #
  def js_env(hash = {}, overwrite = false)
    return {} unless request.format.html? || request.format == "*/*" || @include_js_env
    # set some defaults
    unless @js_env
      editor_css = [
        active_brand_config_url('css'),
        view_context.stylesheet_path(css_url_for('what_gets_loaded_inside_the_tinymce_editor'))
      ]

      editor_hc_css = [
        active_brand_config_url('css', { force_high_contrast: true }),
        view_context.stylesheet_path(css_url_for('what_gets_loaded_inside_the_tinymce_editor', false, { force_high_contrast: true }))
      ]

      @js_env = {
        ASSET_HOST: Canvas::Cdn.config.host,
        active_brand_config_json_url: active_brand_config_url('json'),
        url_to_what_gets_loaded_inside_the_tinymce_editor_css: editor_css,
        url_for_high_contrast_tinymce_editor_css: editor_hc_css,
        current_user_id: @current_user.try(:id),
        current_user_roles: @current_user.try(:roles, @domain_root_account),
        current_user_disabled_inbox: @current_user.try(:disabled_inbox?),
        files_domain: HostUrl.file_host(@domain_root_account || Account.default, request.host_with_port),
        DOMAIN_ROOT_ACCOUNT_ID: @domain_root_account.try(:global_id),
        k12: k12?,
        use_responsive_layout: use_responsive_layout?,
        help_link_name: help_link_name,
        help_link_icon: help_link_icon,
        use_high_contrast: @current_user.try(:prefers_high_contrast?),
        LTI_LAUNCH_FRAME_ALLOWANCES: Lti::Launch::FRAME_ALLOWANCES,
        SETTINGS: {
          open_registration: @domain_root_account.try(:open_registration?),
          eportfolios_enabled: (@domain_root_account && @domain_root_account.settings[:enable_eportfolios] != false), # checking all user root accounts is slow
          collapse_global_nav: @current_user.try(:collapse_global_nav?),
          show_feedback_link: show_feedback_link?,
          enable_profiles: (@domain_root_account && @domain_root_account.settings[:enable_profiles] != false)
        },
      }
      @js_env[:current_user] = @current_user ? Rails.cache.fetch(['user_display_json', @current_user].cache_key, :expires_in => 1.hour) { user_display_json(@current_user, :profile) } : {}
      @js_env[:page_view_update_url] = page_view_path(@page_view.id, page_view_token: @page_view.token) if @page_view
      @js_env[:IS_LARGE_ROSTER] = true if !@js_env[:IS_LARGE_ROSTER] && @context.respond_to?(:large_roster?) && @context.large_roster?
      @js_env[:context_asset_string] = @context.try(:asset_string) if !@js_env[:context_asset_string]
      @js_env[:ping_url] = polymorphic_url([:api_v1, @context, :ping]) if @context.is_a?(Course)
      @js_env[:TIMEZONE] = Time.zone.tzinfo.identifier if !@js_env[:TIMEZONE]
      @js_env[:CONTEXT_TIMEZONE] = @context.time_zone.tzinfo.identifier if !@js_env[:CONTEXT_TIMEZONE] && @context.respond_to?(:time_zone) && @context.time_zone.present?
      unless @js_env[:LOCALE]
        I18n.set_locale_with_localizer
        @js_env[:LOCALE] = I18n.locale.to_s
        @js_env[:BIGEASY_LOCALE] = I18n.bigeasy_locale
        @js_env[:FULLCALENDAR_LOCALE] = I18n.fullcalendar_locale
        @js_env[:MOMENT_LOCALE] = I18n.moment_locale
      end

      @js_env[:lolcalize] = true if ENV['LOLCALIZE']
    end

    hash.each do |k,v|
      if @js_env[k] && !overwrite
        raise "js_env key #{k} is already taken"
      else
        @js_env[k] = v
      end
    end

    @js_env
  end
  helper_method :js_env

  # add keys to JS environment necessary for the RCE at the given risk level
  def rce_js_env(risk_level, root_account: @domain_root_account, domain: request.env['HTTP_HOST'], context: @context)
    rce_env_hash = Services::RichContent.env_for(root_account,
                                            risk_level: risk_level,
                                            user: @current_user,
                                            domain: domain,
                                            real_user: @real_current_user,
                                            context: context)
    js_env(rce_env_hash)
  end
  helper_method :rce_js_env

  def conditional_release_js_env(assignment = nil, includes: [])
    currentContext = @context
    if currentContext.is_a?(Group)
      currentContext = @context.context
    end
    return unless ConditionalRelease::Service.enabled_in_context?(currentContext)
    cr_env = ConditionalRelease::Service.env_for(
      currentContext,
      @current_user,
      session: session,
      assignment: assignment,
      domain: request.env['HTTP_HOST'],
      real_user: @real_current_user,
      includes: includes
    )
    js_env(cr_env)
  end
  helper_method :conditional_release_js_env

  def external_tools_display_hashes(type, context=@context, custom_settings=[])
    return [] if context.is_a?(Group)

    context = context.account if context.is_a?(User)
    tools = ContextExternalTool.all_tools_for(context, {:placements => type,
      :root_account => @domain_root_account, :current_user => @current_user}).to_a

    tools.select!{|tool| ContextExternalTool.visible?(tool.extension_setting(type)['visibility'], @current_user, context, session)}

    tools.map do |tool|
      external_tool_display_hash(tool, type, {}, context, custom_settings)
    end
  end

  def external_tool_display_hash(tool, type, url_params={}, context=@context, custom_settings=[])

    url_params = {
      id: tool.id,
      launch_type: type
    }.merge(url_params)

    hash = {
      :title => tool.label_for(type, I18n.locale),
      :base_url =>  polymorphic_url([context, :external_tool], url_params)
    }

    extension_settings = [:icon_url, :canvas_icon_class] | custom_settings
    extension_settings.each do |setting|
      hash[setting] = tool.extension_setting(type, setting)
    end
    hash
  end
  helper_method :external_tool_display_hash

  def k12?
    @domain_root_account && @domain_root_account.feature_enabled?(:k12)
  end
  helper_method :k12?

  def use_responsive_layout?
    @domain_root_account&.feature_enabled?(:responsive_layout)
  end
  helper_method :use_responsive_layout?

  def application_layout
    use_responsive_layout? ? "ic_layout" : "application"
  end
  private :application_layout

  def grading_periods?
    !!@context.try(:grading_periods?)
  end
  helper_method :grading_periods?

  def master_courses?
    @domain_root_account && @domain_root_account.feature_enabled?(:master_courses)
  end
  helper_method :master_courses?

  def setup_master_course_restrictions(objects, course, user_can_edit: false)
    return unless master_courses? && course.is_a?(Course) && (user_can_edit || course.grants_right?(@current_user, session, :read_as_admin))

    if MasterCourses::MasterTemplate.is_master_course?(course)
      MasterCourses::Restrictor.preload_default_template_restrictions(objects, course)
      return :master # return master/child status
    elsif MasterCourses::ChildSubscription.is_child_course?(course)
      MasterCourses::Restrictor.preload_child_restrictions(objects)
      return :child
    end
  end
  helper_method :setup_master_course_restrictions

  def set_master_course_js_env_data(object, course)
    return unless object.respond_to?(:master_course_api_restriction_data) && object.persisted?
    status = setup_master_course_restrictions([object], course)
    return unless status
    # we might have to include more information about the object here to make it easier to plug a common component in
    data = object.master_course_api_restriction_data(status)
    if status == :master
      data[:default_restrictions] = MasterCourses::MasterTemplate.full_template_for(course).default_restrictions_for(object)
    end
    js_env(:MASTER_COURSE_DATA => data)
  end
  helper_method :set_master_course_js_env_data

  def load_blueprint_courses_ui
    return unless @context && @context.is_a?(Course) && master_courses? && @context.grants_right?(@current_user, :manage)

    is_child = MasterCourses::ChildSubscription.is_child_course?(@context)
    is_master = MasterCourses::MasterTemplate.is_master_course?(@context)

    return unless is_master || is_child

    js_bundle(is_master ? :blueprint_course_master : :blueprint_course_child)
    css_bundle :blueprint_courses

    master_course = is_master ? @context : MasterCourses::MasterTemplate.master_course_for_child_course(@context)
    bc_data = {
      isMasterCourse: is_master,
      isChildCourse: is_child,
      accountId: @context.account.id,
      masterCourse: master_course.slice(:id, :name, :enrollment_term_id),
      course: @context.slice(:id, :name, :enrollment_term_id),
    }
    if is_master
      bc_data.merge!(
        subAccounts: @context.account.sub_accounts.pluck(:id, :name).map{|id, name| {id: id, name: name}},
        terms: @context.account.root_account.enrollment_terms.active.to_a.map{|term| {id: term.id, name: term.name}},
        canManageCourse: @context.account.grants_right?(@current_user, :manage_master_courses)
      )
    end
    js_env :BLUEPRINT_COURSES_DATA => bc_data
    if is_master && js_env.key?(:NEW_USER_TUTORIALS)
      js_env[:NEW_USER_TUTORIALS][:is_enabled] = false
    end
  end
  helper_method :load_blueprint_courses_ui

  def editing_restricted?(content, edit_type=:any)
    return false unless master_courses? && content.respond_to?(:editing_restricted?)
    content.editing_restricted?(edit_type)
  end
  helper_method :editing_restricted?

  def tool_dimensions
    tool_dimensions = {selection_width: '100%', selection_height: '100%'}

    tool_dimensions.each do |k, v|
      tool_dimensions[k] = @tool.settings[k] || v
      tool_dimensions[k] = tool_dimensions[k].to_s << 'px' unless tool_dimensions[k].to_s =~ /%|px/
    end

    tool_dimensions
  end
  private :tool_dimensions

  # Reject the request by halting the execution of the current handler
  # and returning a helpful error message (and HTTP status code).
  #
  # @param [String] cause
  #   The reason the request is rejected for.
  # @param [Optional, Integer|Symbol, Default :bad_request] status
  #   HTTP status code or symbol.
  def reject!(cause, status=:bad_request)
    raise RequestError.new(cause, status)
  end

  # returns the user actually logged into canvas, even if they're currently masquerading
  #
  # This is used by the google docs integration, among other things --
  # having @real_current_user first ensures that a masquerading user never sees the
  # masqueradee's files, but in general you may want to block access to google
  # docs for masqueraders earlier in the request
  def logged_in_user
    @real_current_user || @current_user
  end
  helper_method :logged_in_user

  def not_fake_student_user
    @current_user && @current_user.fake_student? ? logged_in_user : @current_user
  end

  def rescue_action_dispatch_exception
    rescue_action_in_public(request.env['action_dispatch.exception'])
  end

  # used to generate context-specific urls without having to
  # check which type of context it is everywhere
  def named_context_url(context, name, *opts)
    if context.is_a?(UserProfile)
      name = name.to_s.sub(/context/, "profile")
    else
      klass = context.class.base_class
      name = name.to_s.sub(/context/, klass.name.underscore)
      opts.unshift(context)
    end
    opts.push({}) unless opts[-1].is_a?(Hash)
    include_host = opts[-1].delete(:include_host)
    if !include_host
      opts[-1][:host] = context.host_name rescue nil
      opts[-1][:only_path] = true unless name.end_with?("_path")
    end
    self.send name, *opts
  end

  def self.promote_view_path(path)
    self.view_paths = self.view_paths.to_ary.reject{ |p| p.to_s == path }
    prepend_view_path(path)
  end

  protected

  # we track the cost of each request in RequestThrottle in order
  # to rate limit clients that are abusing the API.  Some actions consume
  # time or resources that are not well represented by simple time/cpu
  # benchmarks, so you can use this method to increase the perceived cost
  # of a request by an arbitrary amount.  For an anchor, rate limiting
  # kicks in when a user has exceeded 600 arbitrary units of cost (it's
  # a leaky bucket, go see RequestThrottle), so using an 'amount'
  # param of 600, for example, would max out the bucket immediately
  def increment_request_cost(amount)
    current_cost = request.env['extra-request-cost'] || 0
    request.env['extra-request-cost'] = current_cost + amount
  end

  def assign_localizer
    I18n.localizer = lambda {
      infer_locale :context => @context,
                   :user => not_fake_student_user,
                   :root_account => @domain_root_account,
                   :session_locale => session[:locale],
                   :accept_language => request.headers['Accept-Language']
    }
  end

  def set_locale
    store_session_locale
    assign_localizer
    yield if block_given?
  ensure
    I18n.localizer = nil
  end

  def enable_request_cache(&block)
    RequestCache.enable(&block)
  end

  def batch_statsd(&block)
    CanvasStatsd::Statsd.batch(&block)
  end

  def report_to_datadog(&block)
    if (metric = params[:datadog_metric]) && metric.present?
      require 'datadog/statsd'
      datadog = Datadog::Statsd.new('localhost', 8125)
      datadog.batch do |statsd|
        tags = [
          "domain:#{request.host_with_port.sub(':', '_')}",
          "action:#{controller_name}.#{action_name}",
        ]
        statsd.increment("graphql.rest_comparison.#{metric}.count", tags: tags)
        statsd.time("graphql.rest_comparison.#{metric}.time", tags: tags, &block)
      end
    else
      yield
    end
  end

  def store_session_locale
    return unless locale = params[:session_locale]
    supported_locales = I18n.available_locales.map(&:to_s)
    session[:locale] = locale if supported_locales.include? locale
  end

  def init_body_classes
    @body_classes = []
  end

  def set_user_id_header
    headers['X-Canvas-User-Id'] ||= @current_user.global_id.to_s if @current_user
    headers['X-Canvas-Real-User-Id'] ||= @real_current_user.global_id.to_s if @real_current_user
  end

  # make things requested from jQuery go to the "format.js" part of the "respond_to do |format|" block
  # see http://codetunes.com/2009/01/31/rails-222-ajax-and-respond_to/ for why
  def fix_xhr_requests
    request.format = :js if request.xhr? && request.format == :html && !params[:html_xhr]
  end

  # scopes all time objects to the user's specified time zone
  def set_time_zone
    user = not_fake_student_user
    if user && !user.time_zone.blank?
      Time.zone = user.time_zone
      if Time.zone && Time.zone.name == "UTC" && user.time_zone && user.time_zone.name.match(/\s/)
        Time.zone = user.time_zone.name.split(/\s/)[1..-1].join(" ") rescue nil
      end
    else
      Time.zone = @domain_root_account && @domain_root_account.default_time_zone
    end
  end

  # retrieves the root account for the given domain
  def load_account
    @domain_root_account = request.env['canvas.domain_root_account'] || LoadAccount.default_domain_root_account
    @files_domain = request.host_with_port != HostUrl.context_host(@domain_root_account) && HostUrl.is_file_host?(request.host_with_port)
    @domain_root_account
  end

  def set_response_headers
    # we can't block frames on the files domain, since files domain requests
    # are typically embedded in an iframe in canvas, but the hostname is
    # different
    if !files_domain? && Setting.get('block_html_frames', 'true') == 'true' && !@embeddable
      headers['X-Frame-Options'] = 'SAMEORIGIN'
    end
    headers['Strict-Transport-Security'] = 'max-age=31536000' if request.ssl?
    RequestContextGenerator.store_request_meta(request, @context)
    true
  end

  def files_domain?
    !!@files_domain
  end

  def check_pending_otp
    if session[:pending_otp] && params[:controller] != 'login/otp'
      return render plain: "Please finish logging in", status: 403 if request.xhr?

      reset_session
      redirect_to login_url
    end
  end

  def user_url(*opts)
    opts[0] == @current_user && !@current_user.grants_right?(@current_user, session, :view_statistics) ?
      user_profile_url(@current_user) :
      super
  end

  def tab_enabled?(id, opts = {})
    return true unless @context && @context.respond_to?(:tabs_available)
    tabs = Rails.cache.fetch(['tabs_available', @context, @current_user, @domain_root_account,
      session[:enrollment_uuid]].cache_key, expires_in: 1.hour) do

      @context.tabs_available(@current_user,
        :session => session, :include_hidden_unused => true, :root_account => @domain_root_account)
    end
    valid = tabs.any?{|t| t[:id] == id }
    render_tab_disabled unless valid || opts[:no_render]
    return valid
  end

  def render_tab_disabled
    msg = tab_disabled_message(@context)
    respond_to do |format|
      format.html {
        flash[:notice] = msg
        redirect_to named_context_url(@context, :context_url)
      }
      format.json {
        render :json => { :message => msg }, :status => :not_found
      }
    end
  end

  def tab_disabled_message(context)
    if context.is_a?(Account)
      t "#application.notices.page_disabled_for_account", "That page has been disabled for this account"
    elsif context.is_a?(Course)
      t "#application.notices.page_disabled_for_course", "That page has been disabled for this course"
    elsif context.is_a?(Group)
      t "#application.notices.page_disabled_for_group", "That page has been disabled for this group"
    else
      t "#application.notices.page_disabled", "That page has been disabled"
    end
  end

  def require_password_session
    if session[:used_remember_me_token]
      flash[:warning] = t "#application.warnings.please_log_in", "For security purposes, please enter your password to continue"
      store_location
      redirect_to login_url
      return false
    end
    true
  end

  def run_login_hooks
    LoginHooks.run_hooks(request)
  end

  # checks the authorization policy for the given object using
  # the vendor/plugins/adheres_to_policy plugin.  If authorized,
  # returns true, otherwise renders unauthorized messages and returns
  # false.  To be used as follows:
  # if authorized_action(object, @current_user, :update)
  #   render
  # end
  def authorized_action(object, actor, rights)
    can_do = object.grants_any_right?(actor, session, *Array(rights))
    render_unauthorized_action unless can_do
    can_do
  end
  alias :authorized_action? :authorized_action

  def fix_ms_office_redirects
    if ms_office?
      # Office will follow 302's internally, until it gets to a 200. _then_ it will pop it out
      # to a web browser - but you've lost your cookies! This breaks not only store_location,
      # but in the case of delegated authentication where the provider does an additional
      # redirect storing important information in session, makes it impossible to log in at all
      render plain: '', status: 200
      return false
    end
    true
  end

  def render_unauthorized_action
    respond_to do |format|
      @show_left_side = false
      clear_crumbs
      path_params = request.path_parameters
      path_params[:format] = nil
      @headers = !!@current_user if @headers != false
      @files_domain = @account_domain && @account_domain.host_type == 'files'
      format.html {
        return unless fix_ms_office_redirects
        store_location
        return redirect_to login_url(params.permit(:authentication_provider)) if !@files_domain && !@current_user

        if @context.is_a?(Course) && @context_enrollment
          if @context_enrollment.inactive?
            start_date = @context_enrollment.available_at
          end
          if @context.claimed?
            @unauthorized_message = t('#application.errors.unauthorized.unpublished', "This course has not been published by the instructor yet.")
            @unauthorized_reason = :unpublished
          elsif start_date && start_date > Time.now.utc
            @unauthorized_message = t('#application.errors.unauthorized.not_started_yet', "The course you are trying to access has not started yet.  It will start %{date}.", :date => TextHelper.date_string(start_date))
            @unauthorized_reason = :unpublished
          end
        end

        render "shared/unauthorized", status: :unauthorized
      }
      format.zip { redirect_to(url_for(path_params)) }
      format.json { render_json_unauthorized }
      format.all { render plain: 'Unauthorized', status: :unauthorized }
    end
    set_no_cache_headers
  end

  # To be used as a before_action, requires controller or controller actions
  # to have their urls scoped to a context in order to be valid.
  # So /courses/5/assignments or groups/1/assignments would be valid, but
  # not /assignments
  def require_context
    get_context
    if !@context
      if @context_is_current_user
        store_location
        redirect_to login_url
      elsif params[:context_id]
        raise ActiveRecord::RecordNotFound.new("Cannot find #{params[:context_type] || 'Context'} for ID: #{params[:context_id]}")
      else
        raise ActiveRecord::RecordNotFound.new("Context is required, but none found")
      end
    end
    return @context != nil
  end

  def require_context_and_read_access
    require_context && authorized_action(@context, @current_user, :read)
  end

  helper_method :clean_return_to

  def require_account_context
    require_context_type(Account)
  end

  def require_course_context
    require_context_type(Course)
  end

  def require_context_type(klass)
    unless require_context && @context.is_a?(klass)
      raise ActiveRecord::RecordNotFound.new("Context must be of type '#{klass}'")
    end
    true
  end

  MAX_ACCOUNT_LINEAGE_TO_SHOW_IN_CRUMBS = 3

  # Can be used as a before_action, or just called from controller code.
  # Assigns the variable @context to whatever context the url is scoped
  # to.  So /courses/5/assignments would have a @context=Course.find(5).
  # Also assigns @context_membership to the membership type of @current_user
  # if @current_user is a member of the context.
  def get_context
    unless @context
      if params[:course_id]
        @context = api_find(Course.active, params[:course_id])
        @context.root_account = @domain_root_account if @context.root_account_id == @domain_root_account.id # no sense in refetching it
        params[:context_id] = params[:course_id]
        params[:context_type] = "Course"
        if @context && @current_user
          @context_enrollment = @context.enrollments.where(user_id: @current_user).joins(:enrollment_state).
            order(Enrollment.state_by_date_rank_sql, Enrollment.type_rank_sql).readonly(false).first
        end
        @context_membership = @context_enrollment
        check_for_readonly_enrollment_state
      elsif params[:account_id] || (self.is_a?(AccountsController) && params[:account_id] = params[:id])
        @context = api_find(Account, params[:account_id])
        params[:context_id] = @context.id
        params[:context_type] = "Account"
        @context_enrollment = @context.account_users.active.where(user_id: @current_user.id).first if @context && @current_user
        @context_membership = @context_enrollment
        @account = @context
      elsif params[:group_id]
        @context = api_find(Group.active, params[:group_id])
        params[:context_id] = params[:group_id]
        params[:context_type] = "Group"
        @context_enrollment = @context.group_memberships.where(user_id: @current_user).first if @context && @current_user
        @context_membership = @context_enrollment
      elsif params[:user_id] || (self.is_a?(UsersController) && params[:user_id] = params[:id])
        @context = api_find(User, params[:user_id])
        params[:context_id] = params[:user_id]
        params[:context_type] = "User"
        @context_membership = @context if @context == @current_user
      elsif params[:course_section_id] || (self.is_a?(SectionsController) && params[:course_section_id] = params[:id])
        params[:context_id] = params[:course_section_id]
        params[:context_type] = "CourseSection"
        @context = api_find(CourseSection, params[:course_section_id])
      elsif request.path.match(/\A\/profile/) || request.path == '/' || request.path.match(/\A\/dashboard\/files/) || request.path.match(/\A\/calendar/) || request.path.match(/\A\/assignments/) || request.path.match(/\A\/files/) || request.path == '/api/v1/calendar_events/visible_contexts'
        # ^ this should be split out into things on the individual controllers
        @context_is_current_user = true
        @context = @current_user
        @context_membership = @context
      end

      assign_localizer if @context.present?

      if request.format.html?
        if @context.is_a?(Account) && !@context.root_account?
          account_chain = @context.account_chain.to_a.select {|a| a.grants_right?(@current_user, session, :read) }
          account_chain.slice!(0) # the first element is the current context
          count = account_chain.length
          account_chain.reverse.each_with_index do |a, idx|
            if idx == 1 && count >= MAX_ACCOUNT_LINEAGE_TO_SHOW_IN_CRUMBS
              add_crumb(I18n.t('#lib.text_helper.ellipsis', '...'), nil)
            elsif count >= MAX_ACCOUNT_LINEAGE_TO_SHOW_IN_CRUMBS && idx > 0 && idx <= count - MAX_ACCOUNT_LINEAGE_TO_SHOW_IN_CRUMBS
              next
            else
              add_crumb(a.short_name, account_url(a.id), :id => "crumb_#{a.asset_string}")
            end
          end
        end

        if @context && @context.respond_to?(:short_name)
          crumb_url = named_context_url(@context, :context_url) if @context.grants_right?(@current_user, session, :read)
          add_crumb(@context.nickname_for(@current_user, :short_name), crumb_url)
        end

        @set_badge_counts = true
      end
    end

    # There is lots of interesting information set up in here, that we want
    # to place into the live events context.
    setup_live_events_context
  end

  # This is used by a number of actions to retrieve a list of all contexts
  # associated with the given context.  If the context is a user then it will
  # include all the user's current contexts.
  # Assigns it to the variable @contexts
  def get_all_pertinent_contexts(opts = {})
    return if @already_ran_get_all_pertinent_contexts
    @already_ran_get_all_pertinent_contexts = true

    raise(ArgumentError, "Need a starting context") if @context.nil?

    @contexts = [@context]
    only_contexts = ActiveRecord::Base.parse_asset_string_list(opts[:only_contexts] || params[:only_contexts])
    if @context && @context.is_a?(User)
      # we already know the user can read these courses and groups, so skip
      # the grants_right? check to avoid querying for the various memberships
      # again.
      enrollment_scope = Enrollment
        .shard(opts[:cross_shard] ? @context.in_region_associated_shards : Shard.current)
        .for_user(@context)
        .current
        .active_by_date
      include_groups = !!opts[:include_groups]
      group_ids = nil

      courses = []
      if only_contexts.present?
        # find only those courses and groups passed in the only_contexts
        # parameter, but still scoped by user so we know they have rights to
        # view them.
        course_ids = only_contexts.select { |c| c.first == "Course" }.map(&:last)
        unless course_ids.empty?
          courses = Course.
            shard(opts[:cross_shard] ? @context.in_region_associated_shards : Shard.current).
            joins(enrollments: :enrollment_state).
            merge(enrollment_scope.except(:joins)).
            where(id: course_ids)
        end
        if include_groups
          group_ids = only_contexts.select { |c| c.first == "Group" }.map(&:last)
          include_groups = !group_ids.empty?
        end
      else
        courses = Course.
          shard(opts[:cross_shard] ? @context.in_region_associated_shards : Shard.current).
          joins(enrollments: :enrollment_state).
          merge(enrollment_scope.except(:joins))
      end

      groups = []
      if include_groups
        if group_ids
          Shard.partition_by_shard(group_ids) do |shard_group_ids|
            groups += @context.current_groups.shard(Shard.current).where(:id => shard_group_ids).to_a
          end
        else
          groups = @context.current_groups.shard(opts[:cross_shard] ? @context.in_region_associated_shards : Shard.current).to_a
        end
      end
      groups = @context.filter_visible_groups_for_user(groups)

      if opts[:favorites_first]
        favorite_course_ids = @context.favorite_context_ids("Course")
        courses = courses.sort_by {|c| [favorite_course_ids.include?(c.id) ? 0 : 1, Canvas::ICU.collation_key(c.name)]}
      end

      @contexts.concat courses
      @contexts.concat groups
    end

    include_contexts = opts[:include_contexts] || params[:include_contexts]
    if include_contexts
      include_contexts.split(",").each do |include_context|
        # don't load it again if we've already got it
        next if @contexts.any? { |c| c.asset_string == include_context }
        context = Context.find_by_asset_string(include_context)
        @contexts << context if context && context.grants_right?(@current_user, session, :read)
      end
    end

    @contexts = @contexts.uniq
    Course.require_assignment_groups(@contexts)
    @context_enrollment = @context.membership_for_user(@current_user) if @context.respond_to?(:membership_for_user)
    @context_membership = @context_enrollment
  end

  def check_for_readonly_enrollment_state
    return unless request.format.html?
    if @context_enrollment && @context_enrollment.is_a?(Enrollment) && ['invited', 'active'].include?(@context_enrollment.workflow_state) && action_name != "enrollment_invitation"
      state = @context_enrollment.state_based_on_date
      case state
      when :invited
        if @context_enrollment.available_at
          flash[:html_notice] = mt "#application.notices.need_to_accept_future_enrollment",
            "You'll need to [accept the enrollment invitation](%{url}) before you can fully participate in this course, starting on %{date}.",
            :url => course_url(@context),:date => datetime_string(@context_enrollment.available_at)
        else
          flash[:html_notice] = mt "#application.notices.need_to_accept_enrollment",
            "You'll need to [accept the enrollment invitation](%{url}) before you can fully participate in this course.", :url => course_url(@context)
        end
      when :accepted
        flash[:html_notice] = t("This course hasn’t started yet. You will not be able to participate in this course until %{date}.", :date => datetime_string(@context_enrollment.available_at))
      end
    end
  end

  def set_badge_counts_for(context, user, enrollment=nil)
    return if @js_env && @js_env[:badge_counts].present?
    return unless context.present? && user.present?
    return unless context.respond_to?(:content_participation_counts) # just Course and Group so far
    js_env(:badge_counts => badge_counts_for(context, user, enrollment))
  end
  helper_method :set_badge_counts_for

  def badge_counts_for(context, user, enrollment=nil)
    badge_counts = {}
    ['Submission'].each do |type|
      participation_count = context.content_participation_counts.
          where(:user_id => user.id, :content_type => type).first
      participation_count ||= ContentParticipationCount.create_or_update({
        :context => context,
        :user => user,
        :content_type => type,
      })
      badge_counts[type.underscore.pluralize] = participation_count.unread_count
    end
    badge_counts
  end

  def get_upcoming_assignments(course)
    assignments = AssignmentGroup.visible_assignments(
      @current_user,
      course,
      course.assignment_groups.active
    ).to_a

    log_course(course)

    if @current_user
      submissions = @current_user.submissions.shard(@current_user).to_a
      submissions.each{ |s| s.mute if s.muted_assignment? }
    else
      submissions = []
    end

    assignments.map! {|a| a.overridden_for(@current_user)}
    sorted = SortsAssignments.by_due_date({
      :assignments => assignments,
      :user => @current_user,
      :session => session,
      :upcoming_limit => 1.week.from_now,
      :submissions => submissions
    })

    sorted.upcoming.sort
  end

  def log_course(course)
    log_asset_access([ "assignments", course ], "assignments", "other")
  end

  # Calculates the file storage quota for @context
  def get_quota(context=nil)
    quota_params = Attachment.get_quota(context || @context)
    @quota = quota_params[:quota]
    @quota_used = quota_params[:quota_used]
  end

  # Renders a quota exceeded message if the @context's quota is exceeded
  def quota_exceeded(context=nil, redirect=nil)
    context ||= @context
    redirect ||= root_url
    get_quota(context)
    if response.body.size + @quota_used > @quota
      if context.is_a?(Account)
        error = t "#application.errors.quota_exceeded_account", "Account storage quota exceeded"
      elsif context.is_a?(Course)
        error = t "#application.errors.quota_exceeded_course", "Course storage quota exceeded"
      elsif context.is_a?(Group)
        error = t "#application.errors.quota_exceeded_group", "Group storage quota exceeded"
      elsif context.is_a?(User)
        error = t "#application.errors.quota_exceeded_user", "User storage quota exceeded"
      else
        error = t "#application.errors.quota_exceeded", "Storage quota exceeded"
      end
      respond_to do |format|
        flash[:error] = error unless request.format.to_s == "text/plain"
        format.html {redirect_to redirect }
        format.json {render :json => {:errors => {:base => error}}, :status => :bad_request }
        format.text {render :json => {:errors => {:base => error}}, :status => :bad_request }
      end
      return true
    end
    false
  end

  # Used to retrieve the context from a :feed_code parameter.  These
  # :feed_code attributes are keyed off the object type and the object's
  # uuid.  Using the uuid attribute gives us an unguessable url so
  # that we can offer the feeds without requiring password authentication.
  def get_feed_context(opts={})
    pieces = params[:feed_code].split("_", 2)
    if params[:feed_code].match(/\Agroup_membership/)
      pieces = ["group_membership", params[:feed_code].split("_", 3)[-1]]
    end
    @context = nil
    @problem = nil
    if pieces[0] == "enrollment"
      @enrollment = Enrollment.where(uuid: pieces[1]).first if pieces[1]
      @context_type = "Course"
      if !@enrollment
        @problem = t "#application.errors.mismatched_verification_code", "The verification code does not match any currently enrolled user."
      elsif @enrollment.course && !@enrollment.course.available?
        @problem = t "#application.errors.feed_unpublished_course", "Feeds for this course cannot be accessed until it is published."
      end
      @context = @enrollment.course unless @problem
      @current_user = @enrollment.user unless @problem
    elsif pieces[0] == 'group_membership'
      @membership = GroupMembership.active.where(uuid: pieces[1]).first if pieces[1]
      @context_type = "Group"
      if !@membership
        @problem = t "#application.errors.mismatched_verification_code", "The verification code does not match any currently enrolled user."
      elsif @membership.group && !@membership.group.available?
        @problem = t "#application.errors.feed_unpublished_group", "Feeds for this group cannot be accessed until it is published."
      end
      @context = @membership.group unless @problem
      @current_user = @membership.user unless @problem
    else
      @context_type = pieces[0].classify
      if Context::CONTEXT_TYPES.include?(@context_type.to_sym)
        @context_class = Object.const_get(@context_type, false)
        @context = @context_class.where(uuid: pieces[1]).first if pieces[1]
      end
      if !@context
        @problem = t "#application.errors.invalid_verification_code", "The verification code is invalid."
      elsif (!@context.is_public rescue false) && (!@context.respond_to?(:uuid) || pieces[1] != @context.uuid)
        if @context_type == 'course'
          @problem = t "#application.errors.feed_private_course", "The matching course has gone private, so public feeds like this one will no longer be visible."
        elsif @context_type == 'group'
          @problem = t "#application.errors.feed_private_group", "The matching group has gone private, so public feeds like this one will no longer be visible."
        else
          @problem = t "#application.errors.feed_private", "The matching context has gone private, so public feeds like this one will no longer be visible."
        end
      end
      @context = nil if @problem
      @current_user = @context if @context.is_a?(User)
    end
    if !@context || (opts[:only] && !opts[:only].include?(@context.class.to_s.underscore.to_sym))
      @problem ||= t("#application.errors.invalid_feed_parameters", "Invalid feed parameters.") if (opts[:only] && !opts[:only].include?(@context.class.to_s.underscore.to_sym))
      @problem ||= t "#application.errors.feed_not_found", "Could not find feed."
      render template: "shared/unauthorized_feed", status: :bad_request, formats: [:html]
      return false
    end
    @context
  end

  def discard_flash_if_xhr
    if request.xhr? || request.format.to_s == 'text/plain'
      flash.discard
    end
  end

  def cancel_cache_buster
    @cancel_cache_buster = true
  end

  def cache_buster
    # Annoying problem.  If I set the cache-control to anything other than "no-cache, no-store"
    # then the local cache is used when the user clicks the 'back' button.  I don't know how
    # to tell the browser to ALWAYS check back other than to disable caching...
    return true if @cancel_cache_buster || request.xhr? || api_request?
    set_no_cache_headers
  end

  def initiate_session_from_token
    # Login from a token generated via API
    if params[:session_token]
      token = SessionToken.parse(params[:session_token])
      if token&.valid?
        pseudonym = Pseudonym.active.find_by(id: token.pseudonym_id)

        if pseudonym
          unless pseudonym.works_for_account?(@domain_root_account, true)
            # if the logged in pseudonym doesn't work, we can only switch to another pseudonym
            # that does work if it's the same password, and it's not a managed pseudonym
            alternates = pseudonym.user.all_active_pseudonyms.select { |p|
              !p.managed_password? &&
                p.works_for_account?(@domain_root_account, true) &&
                p.password_salt == pseudonym.password_salt &&
                p.crypted_password == pseudonym.crypted_password }
            # prefer a site admin pseudonym, then a pseudonym in this account, and then any old
            # pseudonym
            pseudonym = alternates.find { |p| p.account_id == Account.site_admin.id }
            pseudonym ||= alternates.find { |p| p.account_id == @domain_root_account.id }
            pseudonym ||= alternates.first
          end
          if pseudonym && pseudonym != @current_pseudonym
            return_to = session.delete(:return_to)
            reset_session_saving_keys(:oauth2)
            PseudonymSession.create!(pseudonym)
            session[:used_remember_me_token] = true if token.used_remember_me_token
          end
          if pseudonym && token.current_user_id
            target_user = User.find(token.current_user_id)
            session[:become_user_id] = token.current_user_id if target_user.can_masquerade?(pseudonym.user, @domain_root_account)
          end
        end
        return redirect_to return_to if return_to
        if (oauth = session[:oauth2])
          provider = Canvas::Oauth::Provider.new(oauth[:client_id], oauth[:redirect_uri], oauth[:scopes], oauth[:purpose])
          return redirect_to Canvas::Oauth::Provider.confirmation_redirect(self, provider, pseudonym.user)
        end

        # do one final redirect to get the token out of the URL
        redirect_to remove_query_params(request.original_url, 'session_token')
      end
    end
  end

  def remove_query_params(url, *params)
    uri = URI.parse(url)
    return url unless uri.query
    qs = Rack::Utils.parse_query(uri.query)
    qs.except!(*params)
    uri.query = qs.empty? ? nil : Rack::Utils.build_query(qs)
    uri.to_s
  end

  def set_no_cache_headers
    response.headers["Pragma"] = "no-cache"
    response.headers["Cache-Control"] = "no-cache, no-store"
  end

  def clear_cached_contexts
    RoleOverride.clear_cached_contexts
  end

  def set_page_view
    return true if !page_views_enabled?

    ENV['RAILS_HOST_WITH_PORT'] ||= request.host_with_port rescue nil
    # We only record page_views for html page requests coming from within the
    # app, or if coming from a developer api request and specified as a
    # page_view.
    if @current_user && !request.xhr? && request.get?
      generate_page_view
    end
  end

  def require_reacceptance_of_terms
    if session[:require_terms] && request.get? && !api_request? && !verified_file_request?
      render "shared/terms_required", status: :unauthorized
      false
    end
  end

  def clear_policy_cache
    AdheresToPolicy::Cache.clear
  end

  def generate_page_view(user=@current_user)
    attributes = { :user => user, :real_user => @real_current_user }
    @page_view = PageView.generate(request, attributes)
    @page_view.user_request = true if params[:user_request] || (user && !request.xhr? && request.get?)
    @page_before_render = Time.now.utc
  end

  def disable_page_views
    @log_page_views = false
    true
  end

  def update_enrollment_last_activity_at
    return unless @context_enrollment.is_a?(Enrollment)
    activity = Enrollment::RecentActivity.new(@context_enrollment, @context)
    activity.record_for_access(response)
  end

  # Asset accesses are used for generating usage statistics.  This is how
  # we say, "the user just downloaded this file" or "the user just
  # viewed this wiki page".  We can then after-the-fact build statistics
  # and reports from these accesses.  This is currently being used
  # to generate access reports per student per course.
  #
  # If asset is an AR model, then its asset_string will be used. If it's an array,
  # it should look like [ "subtype", context ], like [ "pages", course ].
  def log_asset_access(asset, asset_category, asset_group=nil, level=nil, membership_type=nil, overwrite:true)
    # ideally this could just be `user = file_access_user` now, but that causes
    # problems with some integration specs where getting @files_domain set
    # reliably is... difficult
    user = @current_user
    user ||= User.where(id: session['file_access_user_id']).first if session['file_access_user_id'].present?
    return unless user && @context && asset
    return if asset.respond_to?(:new_record?) && asset.new_record?

    code = if asset.is_a?(Array)
             "#{asset[0]}:#{asset[1].asset_string}"
           else
             asset.asset_string
           end

    membership_type ||= @context_membership && @context_membership.class.to_s

    group_code = if asset_group.is_a?(String)
                   asset_group
                 elsif asset_group.respond_to?(:asset_string)
                   asset_group.asset_string
                 else
                   'unknown'
                 end

    if !@accessed_asset || overwrite
      @accessed_asset = {
        :user => user,
        :code => code,
        :group_code => group_code,
        :category => asset_category,
        :membership_type => membership_type,
        :level => level
      }
    end

    Canvas::LiveEvents.asset_access(asset, asset_category, membership_type, level)

    @accessed_asset
  end

  def log_page_view
    return true if !page_views_enabled?

    user = @current_user || (@accessed_asset && @accessed_asset[:user])
    if user && @log_page_views != false
      add_interaction_seconds
      log_participation(user)
      log_gets
      finalize_page_view
    else
      @page_view.destroy if @page_view && !@page_view.new_record?
    end

  rescue StandardError, CassandraCQL::Error::InvalidRequestException => e
    Canvas::Errors.capture_exception(:page_view, e)
    logger.error "Pageview error!"
    raise e if Rails.env.development?
    true
  end

  def add_interaction_seconds
    updated_fields = params.slice(:interaction_seconds)
    if request.xhr? && params[:page_view_token] && !updated_fields.empty? && !(@page_view && @page_view.generated_by_hand)
      RequestContextGenerator.store_interaction_seconds_update(params[:page_view_token], updated_fields[:interaction_seconds])

      page_view_info = PageView.decode_token(params[:page_view_token])
      @page_view = PageView.find_for_update(page_view_info[:request_id])
      if @page_view
        if @page_view.id
          response.headers["X-Canvas-Page-View-Update-Url"] = page_view_path(
            @page_view.id, page_view_token: @page_view.token)
        end
        @page_view.do_update(updated_fields)
        @page_view_update = true
      end
    end
  end

  def log_participation(user)
    # If we're logging the asset access, and it's either a participatory action
    # or it's not an update to an already-existing page_view.  We check to make sure
    # it's not an update because if the page_view already existed, we don't want to
    # double-count it as multiple views when it's really just a single view.
    if @accessed_asset && (@accessed_asset[:level] == 'participate' || !@page_view_update)
      @access = AssetUserAccess.where(user_id: user.id, asset_code: @accessed_asset[:code]).first_or_initialize
      @accessed_asset[:level] ||= 'view'
      @access.log @context, @accessed_asset

      if @page_view.nil? && page_views_enabled? && %w{participate submit}.include?(@accessed_asset[:level])
        generate_page_view(user)
      end

      if @page_view
        @page_view.participated = %w{participate submit}.include?(@accessed_asset[:level])
        @page_view.asset_user_access = @access
      end

      @page_view_update = true
    end
  end

  def log_gets
    if @page_view && !request.xhr? && request.get? && (((response.content_type || "").to_s.match(/html/)) ||
      (Setting.get('create_get_api_page_views', 'true') == 'true') && api_request?)
      @page_view.render_time ||= (Time.now.utc - @page_before_render) rescue nil
      @page_view_update = true
    end
  end

  def finalize_page_view
    if @page_view && @page_view_update
      @page_view.context = @context if !@page_view.context_id && PageView::CONTEXT_TYPES.include?(@context.class.name)
      @page_view.account_id = @domain_root_account.id
      @page_view.developer_key_id = @access_token.try(:developer_key_id)
      @page_view.store
      RequestContextGenerator.store_page_view_meta(@page_view)
    end
  end

  rescue_from Exception, :with => :rescue_exception

  # analogous to rescue_action_without_handler from ActionPack 2.3
  def rescue_exception(exception)
    ActiveSupport::Deprecation.silence do
      message = "\n#{exception.class} (#{exception.message}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << exception.backtrace.join("\n  ")
      logger.fatal("#{message}\n\n")
    end

    if config.consider_all_requests_local
      rescue_action_locally(exception)
    else
      rescue_action_in_public(exception)
    end
  end

  def interpret_status(code)
    message = Rack::Utils::HTTP_STATUS_CODES[code]
    code, message = [500, Rack::Utils::HTTP_STATUS_CODES[500]] unless message
    "#{code} #{message}"
  end

  def response_code_for_rescue(exception)
    ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
  end

  def render_optional_error_file(status)
    path = "#{Rails.public_path}/#{status.to_s[0,3]}"
    if File.exist?(path)
      render :file => path, :status => status, :content_type => Mime::HTML, :layout => false, :formats => [:html]
    else
      head status
    end
  end

  # Custom error catching and message rendering.
  def rescue_action_in_public(exception)
    response_code = exception.response_status if exception.respond_to?(:response_status)
    @show_left_side = exception.show_left_side if exception.respond_to?(:show_left_side)
    response_code ||= response_code_for_rescue(exception) || 500
    begin
      status_code = interpret_status(response_code)
      status = status_code
      status = 'AUT' if exception.is_a?(ActionController::InvalidAuthenticityToken)
      type = nil
      type = '404' if status == '404 Not Found'

      # TODO: get rid of exceptions that implement this "skip_error_report?" thing, instead
      # use the initializer in config/initializers/errors.rb to configure
      # exceptions we want skipped
      unless exception.respond_to?(:skip_error_report?) && exception.skip_error_report?
        opts = {type: type}
        opts[:canvas_error_info] = exception.canvas_error_info if exception.respond_to?(:canvas_error_info)
        info = Canvas::Errors::Info.new(request, @domain_root_account, @current_user, opts)
        error_info = info.to_h
        error_info[:tags][:response_code] = response_code
        capture_outputs = Canvas::Errors.capture(exception, error_info)
        error = nil
        if capture_outputs[:error_report]
          error = ErrorReport.find(capture_outputs[:error_report])
        end
      end

      if api_request?
        rescue_action_in_api(exception, error, response_code)
      else
        render_rescue_action(exception, error, status, status_code)
      end
    rescue => e
      # error generating the error page? failsafe.
      Canvas::Errors.capture(e)
      render_optional_error_file response_code_for_rescue(exception)
    end
  end

  def render_xhr_exception(error, message = nil, status = "500 Internal Server Error", status_code = 500)
    message ||= "Unexpected error, ID: #{error.id rescue "unknown"}"
    render status: status_code, json: {
      errors: {
        base: message
      },
      status: status
    }
  end

  def render_rescue_action(exception, error, status, status_code)
    clear_crumbs
    @headers = nil
    load_account unless @domain_root_account
    session[:last_error_id] = error.id rescue nil
    if request.xhr? || request.format == :text
      message = exception.xhr_message if exception.respond_to?(:xhr_message)
      render_xhr_exception(error, message, status, status_code)
    elsif exception.is_a?(ActionController::InvalidAuthenticityToken) && cookies[:_csrf_token].blank?
      redirect_to login_url(needs_cookies: '1')
      reset_session
      return
    else
      request.format = :html
      template = exception.error_template if exception.respond_to?(:error_template)
      unless template
        template = "shared/errors/#{status.to_s[0,3]}_message"
        erbpath = Rails.root.join('app', 'views', "#{template}.html.erb")
        template = "shared/errors/500_message" unless erbpath.file?
      end

      @status_code = status_code
      message = exception.is_a?(RequestError) ? exception.message : nil
      render template: template,
        layout: 'application',
        status: status_code,
        formats: [:html],
        locals: {
          error: error,
          exception: exception,
          status: status,
          message: message,
        }
    end
  end

  def rescue_action_in_api(exception, error_report, response_code)
    data = exception.error_json if exception.respond_to?(:error_json)
    data ||= api_error_json(exception, response_code)

    if error_report.try(:id)
      data[:error_report_id] = error_report.id
    end

    render :json => data, :status => response_code
  end

  def api_error_json(exception, status_code)
    case exception
    when ActiveRecord::RecordInvalid
      errors = exception.record.errors
      errors.set_reporter(:hash, Api::Errors::Reporter)
      data = errors.to_hash
    when Api::Error
      errors = ActiveModel::BetterErrors::Errors.new(nil)
      errors.error_collection.add(:base, exception.error_id, message: exception.message)
      errors.set_reporter(:hash, Api::Errors::Reporter)
      data = errors.to_hash
    when ActiveRecord::RecordNotFound
      data = { errors: [{message: 'The specified resource does not exist.'}] }
    when AuthenticationMethods::AccessTokenError
      add_www_authenticate_header
      data = { errors: [{message: 'Invalid access token.'}] }
    when AuthenticationMethods::AccessTokenScopeError
      data = { errors: [{message: 'Insufficient scopes on access token.'}] }
    when ActionController::ParameterMissing
      data = { errors: [{message: "#{exception.param} is missing"}] }
    when BasicLTI::BasicOutcomes::Unauthorized,
        BasicLTI::BasicOutcomes::InvalidRequest
      data = { errors: [{message: exception.message}] }
    else
      if status_code.is_a?(Symbol)
        status_code_string = status_code.to_s
      else
        # we want to return a status string of the form "not_found", so take the rails-style "Not Found" and tweak it
        status_code_string = interpret_status(status_code).sub(/\d\d\d /, '').gsub(' ', '').underscore
      end
      data = { errors: [{message: "An error occurred.", error_code: status_code_string}] }
    end
    data
  end

  def rescue_action_locally(exception)
    if api_request? or exception.is_a? RequestError
      # we want api requests to behave the same on error locally as in prod, to
      # ease testing and development. you can still view the backtrace, etc, in
      # the logs.
      rescue_action_in_public(exception)
    else
      super
    end
  end

  def claim_session_course(course, user, state=nil)
    e = course.claim_with_teacher(user)
    session[:claimed_enrollment_uuids] ||= []
    session[:claimed_enrollment_uuids] << e.uuid
    session[:claimed_enrollment_uuids].uniq!
    flash[:notice] = t "#application.notices.first_teacher", "This course is now claimed, and you've been registered as its first teacher."
    if !@current_user && state == :just_registered
      flash[:notice] = t "#application.notices.first_teacher_with_email", "This course is now claimed, and you've been registered as its first teacher. You should receive an email shortly to complete the registration process."
    end
    session[:claimed_course_uuids] ||= []
    session[:claimed_course_uuids] << course.uuid
    session[:claimed_course_uuids].uniq!
    session.delete(:claim_course_uuid)
    session.delete(:course_uuid)
  end

  API_REQUEST_REGEX = %r{\A/api/}
  def api_request?
    @api_request ||= !!request.path.match(API_REQUEST_REGEX)
  end

  def verified_file_request?
    params[:controller] == 'files' && params[:action] == 'show' && params[:verifier].present?
  end

  # Retrieving wiki pages needs to search either using the id or
  # the page title.
  def get_wiki_page
    @wiki = @context.wiki

    @page_name = params[:wiki_page_id] || params[:id] || (params[:wiki_page] && params[:wiki_page][:title])
    if(params[:format] && !['json', 'html'].include?(params[:format]))
      @page_name += ".#{params[:format]}"
      params[:format] = 'html'
    end
    return if @page || !@page_name

    @page = @wiki.find_page(@page_name) if params[:action] != 'create'

    unless @page
      if params[:titleize].present? && !value_to_boolean(params[:titleize])
        @page_name = CGI.unescape(@page_name)
        @page = @wiki.build_wiki_page(@current_user, :title => @page_name)
      else
        @page = @wiki.build_wiki_page(@current_user, :url => @page_name)
      end
    end
  end

  def content_tag_redirect(context, tag, error_redirect_symbol, tag_type=nil)
    url_params = { :module_item_id => tag.id }
    if tag.content_type == 'Assignment'
      redirect_to named_context_url(context, :context_assignment_url, tag.content_id, url_params)
    elsif tag.content_type == 'WikiPage'
      redirect_to polymorphic_url([context, tag.content], url_params)
    elsif tag.content_type == 'Attachment'
      redirect_to named_context_url(context, :context_file_url, tag.content_id, url_params)
    elsif tag.content_type_quiz?
      redirect_to named_context_url(context, :context_quiz_url, tag.content_id, url_params)
    elsif tag.content_type == 'DiscussionTopic'
      redirect_to named_context_url(context, :context_discussion_topic_url, tag.content_id, url_params)
    elsif tag.content_type == 'Rubric'
      redirect_to named_context_url(context, :context_rubric_url, tag.content_id, url_params)
    elsif tag.content_type == 'AssessmentQuestionBank'
      redirect_to named_context_url(context, :context_question_bank_url, tag.content_id, url_params)
    elsif tag.content_type == 'Lti::MessageHandler'
      url_params[:module_item_id] = params[:module_item_id] if params[:module_item_id]
      url_params[:resource_link_fragment] = "ContentTag:#{tag.id}"
      redirect_to named_context_url(context, :context_basic_lti_launch_request_url, tag.content_id, url_params)
    elsif tag.content_type == 'ExternalUrl'
      @tag = tag
      @module = tag.context_module
      log_asset_access(@tag, "external_urls", "external_urls")
      if tag.locked_for? @current_user
        render 'context_modules/lock_explanation'
      else
        tag.context_module_action(@current_user, :read)
        render 'context_modules/url_show'
      end
    elsif tag.content_type == 'ContextExternalTool'
      @tag = tag

      if tag.locked_for? @current_user
        return render 'context_modules/lock_explanation'
      end

      if @tag.context.is_a?(Assignment)
        @assignment = @tag.context
        @resource_title = @assignment.title
        @module_tag = params[:module_item_id] ?
          @context.context_module_tags.not_deleted.find(params[:module_item_id]) :
          @assignment.context_module_tags.first
      else
        @module_tag = @tag
        @resource_title = @tag.title
      end
      @resource_url = @tag.url
      @tool = ContextExternalTool.find_external_tool(tag.url, context, tag.content_id)
      tag.context_module_action(@current_user, :read)
      if !@tool
        flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
        redirect_to named_context_url(context, error_redirect_symbol)
      else
        log_asset_access(@tool, "external_tools", "external_tools", overwrite: false)
        @opaque_id = @tool.opaque_identifier_for(@tag)

        launch_settings = @tool.settings['post_only'] ? {post_only: true, tool_dimensions: tool_dimensions} : {tool_dimensions: tool_dimensions}
        @lti_launch = Lti::Launch.new(launch_settings)

        success_url = case tag_type
        when :assignments
          named_context_url(@context, :context_assignments_url, include_host: true)
        when :modules
          named_context_url(@context, :context_context_modules_url, include_host: true)
        else
          named_context_url(@context, :context_url, include_host: true)
        end
        if tag.new_tab
          @lti_launch.launch_type = 'window'
          @return_url = success_url
        else
          if @context
            @return_url = named_context_url(@context, :context_external_content_success_url, 'external_tool_redirect', include_host: true)
          else
            @return_url = external_content_success_url('external_tool_redirect')
          end
          @redirect_return = true
          js_env(:redirect_return_success_url => success_url,
                 :redirect_return_cancel_url => success_url)
        end

        opts = {
            launch_url: @resource_url,
            link_code: @opaque_id,
            overrides: {'resource_link_title' => @resource_title},
        }
        variable_expander = Lti::VariableExpander.new(@domain_root_account, @context, self,{
                                                        current_user: @current_user,
                                                        current_pseudonym: @current_pseudonym,
                                                        content_tag: @module_tag || tag,
                                                        assignment: @assignment,
                                                        launch: @lti_launch,
                                                        tool: @tool})
        adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context).prepare_tool_launch(@return_url, variable_expander, opts)

        if tag.try(:context_module)
          # if you change this, see also url_show.html.erb
          cu = context_url(@context, :context_context_modules_url)
          cu = "#{cu}/#{tag.context_module.id}"
          add_crumb tag.context_module.name, cu
          add_crumb @tag.title
        end

        if @assignment
          return unless require_user
          add_crumb(@resource_title)
          @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user, @assignment)
          @prepend_template = 'assignments/lti_header' unless render_external_tool_full_width?
          @lti_launch.params = lti_launch_params(adapter)
        else
          @lti_launch.params = adapter.generate_post_payload
        end

        @lti_launch.resource_url = @resource_url
        @lti_launch.link_text = @resource_title
        @lti_launch.analytics_id = @tool.tool_id

        @append_template = 'context_modules/tool_sequence_footer' unless render_external_tool_full_width?
        render Lti::AppUtil.display_template(external_tool_redirect_display_type)
      end
    else
      flash[:error] = t "#application.errors.invalid_tag_type", "Didn't recognize the item type for this tag"
      redirect_to named_context_url(context, error_redirect_symbol)
    end
  end

  def lti_launch_params(adapter)
    adapter.generate_post_payload_for_assignment(@assignment, lti_grade_passback_api_url(@tool), blti_legacy_grade_passback_api_url(@tool), lti_turnitin_outcomes_placement_url(@tool.id))
  end
  private :lti_launch_params

  def external_tool_redirect_display_type
    params['display'] || @tool&.extension_setting(:assignment_selection)&.dig('display_type')
  end
  private :external_tool_redirect_display_type

  def render_external_tool_full_width?
    external_tool_redirect_display_type == 'full_width'
  end
  private :render_external_tool_full_width?

  # pass it a context or an array of contexts and it will give you a link to the
  # person's calendar with only those things checked.
  def calendar_url_for(contexts_to_link_to = nil, options={})
    options[:query] ||= {}
    contexts_to_link_to = Array(contexts_to_link_to)
    if event = options.delete(:event)
      options[:query][:event_id] = event.id
    end
    options[:query][:include_contexts] = contexts_to_link_to.map{|c| c.asset_string}.join(",") unless contexts_to_link_to.empty?
    calendar_url(options[:query])
  end

  # pass it a context or an array of contexts and it will give you a link to the
  # person's files browser for the supplied contexts.
  def files_url_for(contexts_to_link_to = nil, options={})
    options[:query] ||= {}
    contexts_to_link_to = Array(contexts_to_link_to)
    unless contexts_to_link_to.empty?
      options[:anchor] = "#{contexts_to_link_to.first.asset_string}"
    end
    options[:query][:include_contexts] = contexts_to_link_to.map{|c| c.asset_string}.join(",") unless contexts_to_link_to.empty?
    url_for(
      options[:query].merge({
        :controller => 'files',
        :action => "full_index",
        }.merge(options[:anchor].empty? ? {} : {
          :anchor => options[:anchor]
        })
      )
    )
  end
  helper_method :calendar_url_for, :files_url_for

  def conversations_path(params={})
    if @current_user and @current_user.use_new_conversations?
      query_string = params.slice(:context_id, :user_id, :user_name).inject([]) do |res, (k, v)|
        res << "#{k}=#{v}"
        res
      end.join('&')
      "/conversations?#{query_string}"
    else
      hash = params.keys.empty? ? '' : "##{params.to_json.unpack('H*').first}"
      "/conversations#{hash}"
    end
  end
  helper_method :conversations_path

  # escape everything but slashes, see http://code.google.com/p/phusion-passenger/issues/detail?id=113
  FILE_PATH_ESCAPE_PATTERN = Regexp.new("[^#{URI::PATTERN::UNRESERVED}/]")
  def safe_domain_file_url(attachment, host_and_shard=nil, verifier = nil, download = false) # TODO: generalize this
    if !host_and_shard
      host_and_shard = HostUrl.file_host_with_shard(@domain_root_account || Account.default, request.host_with_port)
    end
    host, shard = host_and_shard
    res = "#{request.protocol}#{host}"

    shard.activate do
      # add parameters so that the other domain can create a session that
      # will authorize file access but not full app access.  We need this in
      # case there are relative URLs in the file that point to other pieces
      # of content.
      opts = generate_access_verifier
      opts[:verifier] = verifier if verifier.present?

      if download
        # download "for realz, dude" (see later comments about :download)
        opts[:download_frd] = 1
      else
        # don't set :download here, because file_download_url won't like it. see
        # comment below for why we'd want to set :download
        opts[:inline] = 1
      end

      if @context && Attachment.relative_context?(@context.class.base_class) && @context == attachment.context
        # so yeah, this is right. :inline=>1 wants :download=>1 to go along with
        # it, so we're setting :download=>1 *because* we want to display inline.
        opts[:download] = 1 unless download

        # if the context is one that supports relative paths (which requires extra
        # routes and stuff), then we'll build an actual named_context_url with the
        # params for show_relative
        res += named_context_url(@context, :context_file_url, attachment)
        res += '/' + URI.escape(attachment.full_display_path, FILE_PATH_ESCAPE_PATTERN)
        res += '?' + opts.to_query
      else
        # otherwise, just redirect to /files/:id
        res += file_download_url(attachment, opts.merge(:only_path => true))
      end
    end

    res
  end
  helper_method :safe_domain_file_url

  def feature_enabled?(feature)
    @features_enabled ||= {}
    feature = feature.to_sym
    return @features_enabled[feature] if @features_enabled[feature] != nil
    @features_enabled[feature] ||= begin
      if [:question_banks].include?(feature)
        true
      elsif feature == :twitter
        !!Twitter::Connection.config
      elsif feature == :linked_in
        !!LinkedIn::Connection.config
      elsif feature == :diigo
        !!Diigo::Connection.config
      elsif feature == :google_drive
        Canvas::Plugin.find(:google_drive).try(:enabled?)
      elsif feature == :etherpad
        !!EtherpadCollaboration.config
      elsif feature == :kaltura
        !!CanvasKaltura::ClientV3.config
      elsif feature == :web_conferences
        !!WebConference.config
      elsif feature == :crocodoc
        !!Canvas::Crocodoc.config
      elsif feature == :vericite
        Canvas::Plugin.find(:vericite).try(:enabled?)
      elsif feature == :lockdown_browser
        Canvas::Plugin.all_for_tag(:lockdown_browser).any? { |p| p.settings[:enabled] }
      else
        false
      end
    end
  end
  helper_method :feature_enabled?

  def service_enabled?(service)
    @domain_root_account && @domain_root_account.service_enabled?(service)
  end
  helper_method :service_enabled?

  def feature_and_service_enabled?(feature)
    feature_enabled?(feature) && service_enabled?(feature)
  end
  helper_method :feature_and_service_enabled?

  def temporary_user_code(generate=true)
    if generate
      session[:temporary_user_code] ||= "tmp_#{Digest::MD5.hexdigest("#{Time.now.to_i}_#{rand}")}"
    else
      session[:temporary_user_code]
    end
  end

  def require_account_management(on_root_account = false)
    if (!@context.root_account? && on_root_account) || !@context.is_a?(Account)
      redirect_to named_context_url(@context, :context_url)
      return false
    else
      return false unless authorized_action(@context, @current_user, :manage_account_settings)
    end
  end

  def require_root_account_management
    require_account_management(true)
  end

  def require_site_admin_with_permission(permission)
    require_context_with_permission(Account.site_admin, permission)
  end

  def require_context_with_permission(context, permission)
    unless context.grants_right?(@current_user, permission)
      respond_to do |format|
        format.html do
          if @current_user
            flash[:error] = t "#application.errors.permission_denied", "You don't have permission to access that page"
            redirect_to root_url
          else
            redirect_to_login
          end
        end
        format.json do
          render_json_unauthorized
        end
      end
      return false
    end
  end

  def require_registered_user
    return false if require_user == false
    unless @current_user.registered?
      respond_to do |format|
        format.html { render "shared/registration_incomplete", status: :unauthorized }
        format.json { render :json => { 'status' => 'unauthorized', 'message' => t('#errors.registration_incomplete', 'You need to confirm your email address before you can view this page') }, :status => :unauthorized }
      end
      return false
    end
  end

  def check_incomplete_registration
    if @current_user
      js_env :INCOMPLETE_REGISTRATION => incomplete_registration?, :USER_EMAIL => @current_user.email
    end
  end

  def incomplete_registration?
    @current_user && params[:registration_success] && @current_user.pre_registered?
  end
  helper_method :incomplete_registration?

  def page_views_enabled?
    PageView.page_views_enabled?
  end
  helper_method :page_views_enabled?

  def verified_file_download_url(attachment, context = nil, permission_map_id = nil, *opts)
    verifier = Attachments::Verification.new(attachment).verifier_for_user(@current_user,
        context: context.try(:asset_string), permission_map_id: permission_map_id)
    file_download_url(attachment, { :verifier => verifier }, *opts)
  end
  helper_method :verified_file_download_url

  def user_content(str, cache_key = nil)
    return nil unless str
    return str.html_safe unless str.match(/object|embed|equation_image/)

    UserContent.escape(str, request.host_with_port)
  end
  helper_method :user_content

  def public_user_content(str, context=@context, user=@current_user, is_public=false)
    return nil unless str

    rewriter = UserContent::HtmlRewriter.new(context, user)
    rewriter.set_handler('files') do |match|
      UserContent::FilesHandler.new(
        match: match,
        context: context,
        user: user,
        preloaded_attachments: {},
        is_public: is_public
      ).processed_url
    end
    UserContent.escape(rewriter.translate_content(str), request.host_with_port)
  end
  helper_method :public_user_content

  def find_bank(id, check_context_chain=true)
    bank = @context.assessment_question_banks.active.where(id: id).first || @current_user.assessment_question_banks.active.where(id: id).first
    if bank
      (block_given? ?
        authorized_action(bank, @current_user, :read) :
        bank.grants_right?(@current_user, session, :read)) or return nil
    elsif check_context_chain
      (block_given? ?
        authorized_action(@context, @current_user, :read_question_banks) :
        @context.grants_right?(@current_user, session, :read_question_banks)) or return nil
      bank = @context.inherited_assessment_question_banks.where(id: id).first
    end
    yield if block_given? && (@bank = bank)
    bank
  end

  def prepend_json_csrf?
    requested_json = request.headers['Accept'] =~ %r{application/json}
    request.get? && !requested_json && in_app?
  end

  def in_app?
    !!(@current_user ? @pseudonym_session : session[:session_id])
  end

  def json_as_text?
    (request.headers['CONTENT_TYPE'].to_s =~ %r{multipart/form-data}) &&
    (params[:format].to_s != 'json' || in_app?)
  end

  def params_are_integers?(*check_params)
    begin
      check_params.each{ |p| Integer(params[p]) }
    rescue ArgumentError
      return false
    end
    true
  end

  def destroy_session
    logger.info "Destroying session: #{session[:session_id]}"
    @pseudonym_session.destroy rescue true
    reset_session
  end

  def logout_current_user
    logged_in_user.try(:stamp_logout_time!)
    InstFS.logout(logged_in_user) rescue nil
    destroy_session
  end

  def set_layout_options
    @embedded_view = params[:embedded]
    @headers = false if params[:no_headers]
    (@body_classes ||= []) << 'embedded' if @embedded_view
  end

  def stringify_json_ids?
    request.headers['Accept'] =~ %r{application/json\+canvas-string-ids}
  end

  def json_cast(obj)
    obj = obj.as_json if obj.respond_to?(:as_json) unless obj.is_a?(Hash) || obj.is_a?(Array)
    stringify_json_ids? ? StringifyIds.recursively_stringify_ids(obj) : obj
  end

  def render(options = nil, extra_options = {}, &block)
    set_layout_options
    if options.is_a?(Hash) && options.key?(:json)
      json = options.delete(:json)
      unless json.is_a?(String)
        json_cast(json)
        json = ActiveSupport::JSON.encode(json)
      end

      # prepend our CSRF protection to the JSON response, unless this is an API
      # call that didn't use session auth, or a non-GET request.
      if prepend_json_csrf?
        json = "while(1);#{json}"
      end

      # fix for some browsers not properly handling json responses to multipart
      # file upload forms and s3 upload success redirects -- we'll respond with text instead.
      if options[:as_text] || json_as_text?
        options[:html] = json.html_safe
      else
        options[:json] = json
      end
    end
    super
  end

  # flash is normally only preserved for one redirect; make sure we carry
  # it along in case there are more
  def redirect_to(*)
    flash.keep
    super
  end

  def css_bundles
    @css_bundles ||= []
  end
  helper_method :css_bundles

  def css_bundle(*args)
    opts = (args.last.is_a?(Hash) ? args.pop : {})
    Array(args).flatten.each do |bundle|
      css_bundles << [bundle, opts[:plugin]] unless css_bundles.include? [bundle, opts[:plugin]]
    end
    nil
  end
  helper_method :css_bundle

  def js_bundles; @js_bundles ||= []; end
  helper_method :js_bundles

  # Use this method to place a bundle on the page, note that the end goal here
  # is to only ever include one bundle per page load, so use this with care and
  # ensure that the bundle you are requiring isn't simply a dependency of some
  # other bundle.
  #
  # Bundles are defined in app/coffeescripts/bundles/<bundle>.coffee
  #
  # usage: js_bundle :gradebook
  #
  # Only allows multiple arguments to support old usage of jammit_js
  #
  # Optional :plugin named parameter allows you to specify a plugin which
  # contains the bundle. Example:
  #
  # js_bundle :gradebook, :plugin => :my_feature
  #
  # will look for the bundle in
  # /plugins/my_feature/(optimized|javascripts)/compiled/bundles/ rather than
  # /(optimized|javascripts)/compiled/bundles/
  def js_bundle(*args)
    opts = (args.last.is_a?(Hash) ? args.pop : {})
    Array(args).flatten.each do |bundle|
      js_bundles << [bundle, opts[:plugin]] unless js_bundles.include? [bundle, opts[:plugin]]
    end
    nil
  end
  helper_method :js_bundle

  def get_course_from_section
    if params[:section_id]
      @section = api_find(CourseSection, params.delete(:section_id))
      params[:course_id] = @section.course_id
    end
  end

  def reject_student_view_student
    return unless @current_user && @current_user.fake_student?
    @unauthorized_message ||= t('#application.errors.student_view_unauthorized', "You cannot access this functionality in student view.")
    render_unauthorized_action
  end

  def set_site_admin_context
    @context = Account.site_admin
    add_crumb t('#crumbs.site_admin', "Site Admin"), url_for(Account.site_admin)
  end

  def flash_notices
    @notices ||= begin
      notices = []
      if !browser_supported? && !@embedded_view && !cookies['unsupported_browser_dismissed']
        notices << {:type => 'warning', :content => {html: unsupported_browser}, :classes => 'unsupported_browser'}
      end
      if error = flash[:error]
        flash.delete(:error)
        notices << {:type => 'error', :content => error, :icon => 'warning'}
      end
      if warning = flash[:warning]
        flash.delete(:warning)
        notices << {:type => 'warning', :content => warning, :icon => 'warning'}
      end
      if info = flash[:info]
        flash.delete(:info)
        notices << {:type => 'info', :content => info, :icon => 'info'}
      end
      if notice = (flash[:html_notice] ? {html: flash[:html_notice]} : flash[:notice])
        if flash[:html_notice]
          flash.delete(:html_notice)
        else
          flash.delete(:notice)
        end
        notices << {:type => 'success', :content => notice, :icon => 'check'}
      end
      notices
    end
  end
  helper_method :flash_notices

  def unsupported_browser
    t("Your browser does not meet the minimum requirements for Canvas. Please visit the *Canvas Community* for a complete list of supported browsers.", :wrapper => view_context.link_to('\1', 'https://community.canvaslms.com/docs/DOC-1284'))
  end

  def browser_supported?
    # the user_agent gem likes to (ab)use objects and metaprogramming, so
    # we just do this check once per session. or maybe more than once, if
    # you upgrade your browser and it treats session cookie expiration
    # rules as a suggestion
    key = request.user_agent.to_s.sum # keep cookie size in check. a legitimate collision here would be 1. extremely unlikely and 2. not a big deal
    if key != session[:browser_key]
      session[:browser_key] = key
      session[:browser_supported] = Browser.supported?(request.user_agent)
    end
    session[:browser_supported]
  end

  def mobile_device?
    params[:mobile] || request.user_agent.to_s =~ /ipod|iphone|ipad|Android/i
  end

  def ms_office?
    !!(request.user_agent.to_s =~ /ms-office/) ||
        !!(request.user_agent.to_s =~ %r{Word/\d+\.\d+})
  end

  def profile_data(profile, viewer, session, includes)
    extend Api::V1::UserProfile
    extend Api::V1::Course
    extend Api::V1::Group
    includes ||= []
    data = user_profile_json(profile, viewer, session, includes, profile)
    data[:can_edit] = viewer == profile.user
    data[:can_edit_name] = data[:can_edit] && profile.user.user_can_edit_name?
    data[:can_edit_avatar] = data[:can_edit] && profile.user.avatar_state != :locked
    data[:known_user] = viewer.address_book.known_user(profile.user)
    if data[:known_user] && viewer != profile.user
      common_courses = viewer.address_book.common_courses(profile.user)
      common_groups = viewer.address_book.common_groups(profile.user)
    else
      common_courses = {}
      common_groups = {}
    end
    data[:common_contexts] = common_contexts(common_courses, common_groups, @current_user, session)
    data
  end

  def common_contexts(common_courses, common_groups, current_user, session)
    courses = Course.where(id: common_courses.keys).to_a
    groups = Group.where(id: common_groups.keys).to_a

    common_courses = courses.map do |course|
      course_json(course, current_user, session, ['html_url'], false).merge({
        roles: common_courses[course.id].map { |role| Enrollment.readable_type(role) }
      })
    end

    common_groups = groups.map do |group|
      group_json(group, current_user, session, include: ['html_url']).merge({
        # in the future groups will have more roles and we'll need soemthing similar to
        # the roles.map above in courses
        roles: [t('#group.memeber', "Member")]
      })
    end

    common_courses + common_groups
  end

  def self.batch_jobs_in_actions(opts = {})
    batch_opts = opts.delete(:batch)
    around_action(opts) do |controller, action|
      Delayed::Batch.serial_batch(batch_opts || {}) do
        action.call
      end
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def set_js_rights(objtypes = nil)
    objtypes ||= js_rights if respond_to?(:js_rights)
    if objtypes
      hash = {}
      objtypes.each do |instance_symbol|
        instance_name = instance_symbol.to_s
        obj = instance_variable_get("@#{instance_name}")
        policy = obj.check_policy(@current_user, session) unless obj.nil? || !obj.respond_to?(:check_policy)
        hash["#{instance_name.upcase}_RIGHTS".to_sym] = HashWithIndifferentAccess[policy.map { |right| [right, true] }] unless policy.nil?
      end

      js_env hash
    end
  end

  def set_js_wiki_data(opts = {})
    hash = {}

    hash[:DEFAULT_EDITING_ROLES] = @context.default_wiki_editing_roles if @context.respond_to?(:default_wiki_editing_roles)
    hash[:WIKI_PAGES_PATH] = polymorphic_path([@context, :wiki_pages])
    if opts[:course_home]
      hash[:COURSE_HOME] = true
      hash[:COURSE_TITLE] = @context.name
    end

    if @page
      if @page.grants_any_right?(@current_user, session, :update, :update_content)
        mc_status = setup_master_course_restrictions(@page, @context, user_can_edit: true)
      end

      hash[:WIKI_PAGE] = wiki_page_json(@page, @current_user, session, true, :deep_check_if_needed => true, :master_course_status => mc_status)
      hash[:WIKI_PAGE_REVISION] = (current_version = @page.versions.current) ? StringifyIds.stringify_id(current_version.number) : nil
      hash[:WIKI_PAGE_SHOW_PATH] = named_context_url(@context, :context_wiki_page_path, @page)
      hash[:WIKI_PAGE_EDIT_PATH] = named_context_url(@context, :edit_context_wiki_page_path, @page)
      hash[:WIKI_PAGE_HISTORY_PATH] = named_context_url(@context, :context_wiki_page_revisions_path, @page)
    end

    if @context.is_a?(Course) && @context.grants_right?(@current_user, session, :read)
      hash[:COURSE_ID] = @context.id.to_s
      hash[:MODULES_PATH] = polymorphic_path([@context, :context_modules])
    end

    js_env hash
  end

  def set_js_assignment_data
    rights = [:manage_assignments, :manage_grades, :read_grades, :manage]
    permissions = @context.rights_status(@current_user, *rights)
    permissions[:manage_course] = permissions[:manage]
    permissions[:manage] = permissions[:manage_assignments]
    permissions[:by_assignment_id] = @context.assignments.map do |assignment|
      [assignment.id, {update: assignment.user_can_update?(@current_user, session)}]
    end.to_h

    js_env({
      :URLS => {
        :new_assignment_url => new_polymorphic_url([@context, :assignment]),
        :new_quiz_url => context_url(@context, :context_quizzes_new_url),
        :course_url => api_v1_course_url(@context),
        :sort_url => reorder_course_assignment_groups_url(@context),
        :assignment_sort_base_url => course_assignment_groups_url(@context),
        :context_modules_url => api_v1_course_context_modules_path(@context),
        :course_student_submissions_url => api_v1_course_student_submissions_url(@context)
      },
      :POST_TO_SIS => Assignment.sis_grade_export_enabled?(@context),
      :PERMISSIONS => permissions,
      :HAS_GRADING_PERIODS => @context.grading_periods?,
      :VALID_DATE_RANGE => CourseDateRange.new(@context),
      :assignment_menu_tools => external_tools_display_hashes(:assignment_menu),
      :discussion_topic_menu_tools => external_tools_display_hashes(:discussion_topic_menu),
      :quiz_menu_tools => external_tools_display_hashes(:quiz_menu),
      :current_user_has_been_observer_in_this_course => @context.user_has_been_observer?(@current_user),
      :observed_student_ids => ObserverEnrollment.observed_student_ids(@context, @current_user),
    })

    conditional_release_js_env(includes: :active_rules)

    if @context.grading_periods?
      js_env(:active_grading_periods => GradingPeriod.json_for(@context, @current_user))
    end
  end

  def self.google_drive_timeout
    Setting.get('google_drive_timeout', 30).to_i
  end

  def google_drive_connection
    return @google_drive_connection if @google_drive_connection

    ## @real_current_user first ensures that a masquerading user never sees the
    ## masqueradee's files, but in general you may want to block access to google
    ## docs for masqueraders earlier in the request
    if logged_in_user
      refresh_token, access_token = Rails.cache.fetch(['google_drive_tokens', logged_in_user].cache_key) do
        service = logged_in_user.user_services.where(service: "google_drive").first
        service && [service.token, service.secret]
      end
    else
      refresh_token = session[:oauth_gdrive_refresh_token]
      access_token = session[:oauth_gdrive_access_token]
    end

    @google_drive_connection = GoogleDrive::Connection.new(refresh_token, access_token, ApplicationController.google_drive_timeout)
  end

  def google_drive_client(refresh_token=nil, access_token=nil)
    settings = Canvas::Plugin.find(:google_drive).try(:settings) || {}
    client_secrets = {
      client_id: settings[:client_id],
      client_secret: settings[:client_secret_dec],
      redirect_uri: settings[:redirect_uri]
    }.with_indifferent_access
    GoogleDrive::Client.create(client_secrets, refresh_token, access_token)
  end

  def user_has_google_drive
    @user_has_google_drive ||= google_drive_connection.authorized?
  end

  def self.instance_id
    nil
  end

  def self.region
    nil
  end

  def self.cluster
    nil
  end

  def self.test_cluster_name
    nil
  end

  def self.test_cluster?
    false
  end

  def setup_live_events_context
    ctx = {}

    if @domain_root_account
      ctx[:root_account_uuid] = @domain_root_account.uuid
      ctx[:root_account_id] = @domain_root_account.global_id
      ctx[:root_account_lti_guid] = @domain_root_account.lti_guid
    end

    if @current_pseudonym
      ctx[:user_login] = @current_pseudonym.unique_id
      ctx[:user_account_id] = @current_pseudonym.global_account_id
      ctx[:user_sis_id] = @current_pseudonym.sis_user_id
    end

    ctx[:user_id] = @current_user.global_id if @current_user
    ctx[:real_user_id] = @real_current_user.global_id if @real_current_user
    ctx[:context_type] = @context.class.to_s if @context
    ctx[:context_id] = @context.global_id if @context
    if @context_membership
      ctx[:context_role] =
        if @context_membership.respond_to?(:role)
          @context_membership.role.name
        elsif @context_membership.respond_to?(:type)
          @context_membership.type
        else
          @context_membership.class.to_s
        end
    end

    if tctx = Thread.current[:context]
      ctx[:request_id] = tctx[:request_id]
      ctx[:session_id] = tctx[:session_id]
    end

    ctx[:hostname] = request.host
    ctx[:user_agent] = request.headers['User-Agent']
    ctx[:producer] = 'canvas'

    StringifyIds.recursively_stringify_ids(ctx)
    LiveEvents.set_context(ctx)
  end

  def teardown_live_events_context
    LiveEvents.clear_context!
  end

  # TODO: this belongs in AccountsController but while :course_user_search is still behind a feature flag we
  # have to let UsersController::index own the /accounts/x/users route so it responds as it used to if the
  # feature isn't enabled but `return course_user_search` if the feature is enabled. you can't `return` an
  # action from another controller but you can from a controller you inherit from. Hence why this can be
  # here in ApplicationController but not AccountsController for now. Once we remove the feature flag,
  # we should move this back to AccountsController and just change conf/routes.rb to let
  # AccountsController::users own /accounts/x/users instead UsersController::index
  def course_user_search
    return unless authorized_action(@account, @current_user, :read)
    can_read_course_list = @account.grants_right?(@current_user, session, :read_course_list)
    can_read_roster = @account.grants_right?(@current_user, session, :read_roster)
    can_manage_account = @account.grants_right?(@current_user, session, :manage_account_settings)

    unless can_read_course_list || can_read_roster
      if @redirect_on_unauth
        return redirect_to account_settings_url(@account)
      else
        return render_unauthorized_action
      end
    end

    js_env({
      COURSE_ROLES: Role.course_role_data_for_account(@account, @current_user)
    })
    js_bundle :account_course_user_search
    css_bundle :addpeople
    @page_title = @account.name
    add_crumb '', '?' # the text for this will be set by javascript
    js_env({
      ROOT_ACCOUNT_NAME: @account.root_account.name, # used in AddPeopleApp modal
      ACCOUNT_ID: @account.id,
      'master_courses?' => master_courses?,
      ROOT_ACCOUNT_ID: @account.root_account.id,
      customized_login_handle_name: @account.root_account.customized_login_handle_name,
      delegated_authentication: @account.root_account.delegated_authentication?,
      SHOW_SIS_ID_IN_NEW_USER_FORM: @account.root_account.allow_sis_import && @account.root_account.grants_right?(@current_user, session, :manage_sis),
      PERMISSIONS: {
        can_read_course_list: can_read_course_list,
        can_read_roster: can_read_roster,
        can_create_courses: @account.grants_right?(@current_user, session, :manage_courses),
        can_create_enrollments: @account.grants_any_right?(@current_user, session, :manage_students, :manage_admin_users),
        can_create_users: @account.root_account.grants_right?(@current_user, session, :manage_user_logins),
        analytics: @account.service_enabled?(:analytics),
        can_masquerade: @account.grants_right?(@current_user, session, :become_user),
        can_message_users: @account.grants_right?(@current_user, session, :send_messages),
        can_edit_users: @account.grants_any_right?(@current_user, session, :manage_students, :manage_user_logins)
      }
    })
    render html: '', layout: true
  end
end
