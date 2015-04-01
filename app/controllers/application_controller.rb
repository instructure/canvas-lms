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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  def self.promote_view_path(path)
    self.view_paths = self.view_paths.to_ary.reject{ |p| p.to_s == path }
    prepend_view_path(path)
  end

  attr_accessor :active_tab
  attr_reader :context

  include Api
  include LocaleSelection
  include Api::V1::User
  include Api::V1::WikiPage
  include LegalInformationHelper
  around_filter :set_locale

  helper :all

  include AuthenticationMethods
  protect_from_forgery
  # load_user checks masquerading permissions, so this needs to be cleared first
  before_filter :clear_cached_contexts
  before_filter :load_account, :load_user
  before_filter ::Filters::AllowAppProfiling
  before_filter :check_pending_otp
  before_filter :set_user_id_header
  before_filter :set_time_zone
  before_filter :set_page_view
  before_filter :require_reacceptance_of_terms
  before_filter :clear_policy_cache
  after_filter :log_page_view
  after_filter :discard_flash_if_xhr
  after_filter :cache_buster
  # Yes, we're calling this before and after so that we get the user id logged
  # on events that log someone in and log someone out.
  after_filter :set_user_id_header
  before_filter :fix_xhr_requests
  before_filter :init_body_classes
  after_filter :set_response_headers
  after_filter :update_enrollment_last_activity_at
  include Tour

  add_crumb(proc {
    title = I18n.t('links.dashboard', 'My Dashboard')
    crumb = <<-END
      <i class="icon-home standalone-icon"
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
  def js_env(hash = {})
    return {} if api_request?
    # set some defaults
    unless @js_env
      @js_env = {
        :current_user_id => @current_user.try(:id),
        :current_user => user_display_json(@current_user, :profile),
        :current_user_roles => @current_user.try(:roles, @domain_root_account),
        :files_domain => HostUrl.file_host(@domain_root_account || Account.default, request.host_with_port),
        :DOMAIN_ROOT_ACCOUNT_ID => @domain_root_account.try(:global_id),
        :use_new_styles => use_new_styles?,
        :k12 => k12?,
        :use_high_contrast => @current_user.try(:prefers_high_contrast?),
        :SETTINGS => {
          open_registration: @domain_root_account.try(:open_registration?)
        }
      }
      @js_env[:lolcalize] = true if ENV['LOLCALIZE']
    end

    hash.each do |k,v|
      if @js_env[k]
        raise "js_env key #{k} is already taken"
      else
        @js_env[k] = v
      end
    end
    @js_env[:IS_LARGE_ROSTER] = true if !@js_env[:IS_LARGE_ROSTER] && @context.respond_to?(:large_roster?) && @context.large_roster?
    @js_env[:context_asset_string] = @context.try(:asset_string) if !@js_env[:context_asset_string]
    @js_env[:ping_url] = polymorphic_url([:api_v1, @context, :ping]) if @context.is_a?(Course)
    @js_env[:TIMEZONE] = Time.zone.tzinfo.identifier if !@js_env[:TIMEZONE]
    @js_env[:CONTEXT_TIMEZONE] = @context.time_zone.tzinfo.identifier if !@js_env[:CONTEXT_TIMEZONE] && @context.respond_to?(:time_zone) && @context.time_zone.present?
    @js_env[:LOCALE] = I18n.qualified_locale if !@js_env[:LOCALE]
    @js_env[:TOURS] = tours_to_run
    @js_env
  end
  helper_method :js_env

  def external_tools_display_hashes(type, context=@context, custom_settings=[])
    return [] if context.is_a?(Group)

    context = context.account if context.is_a?(User)
    tools = ContextExternalTool.all_tools_for(context, {:type => type,
      :root_account => @domain_root_account, :current_user => @current_user})

    extension_settings = [:icon_url] + custom_settings
    tools.map do |tool|
      hash = {
          :title => tool.label_for(type),
          :base_url => named_context_url(context, :context_external_tool_path, tool, :launch_type => type)
      }
      extension_settings.each do |setting|
        hash[setting] = tool.extension_setting(type, setting)
      end
      hash
    end
  end

  def k12?
    @domain_root_account && @domain_root_account.feature_enabled?('k12')
  end
  helper_method 'k12?'

  def use_new_styles?
    @domain_root_account && @domain_root_account.feature_enabled?(:use_new_styles)
  end
  helper_method 'use_new_styles?'

  def multiple_grading_periods?
    @domain_root_account && @domain_root_account.feature_enabled?(:multiple_grading_periods)
  end
  helper_method 'multiple_grading_periods?'

  # Reject the request by halting the execution of the current handler
  # and returning a helpful error message (and HTTP status code).
  #
  # @param [String] cause
  #   The reason the request is rejected for.
  # @param [Optional, Fixnum|Symbol, Default :bad_request] status
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
      opts[-1][:only_path] = true
    end
    self.send name, *opts
  end

  protected

  def assign_localizer
    I18n.localizer = lambda {
      infer_locale :context => @context,
                   :user => @current_user,
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
    if @current_user && !@current_user.time_zone.blank?
      Time.zone = @current_user.time_zone
      if Time.zone && Time.zone.name == "UTC" && @current_user.time_zone && @current_user.time_zone.name.match(/\s/)
        Time.zone = @current_user.time_zone.name.split(/\s/)[1..-1].join(" ") rescue nil
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
    true
  end

  def files_domain?
    !!@files_domain
  end

  def check_pending_otp
    if session[:pending_otp] && !(params[:action] == 'otp_login' && request.post?)
      reset_session
      redirect_to login_url
    end
  end

  def user_url(*opts)
    opts[0] == @current_user && !@current_user.grants_right?(@current_user, session, :view_statistics) ?
      user_profile_url(@current_user) :
      super
  end

  def tab_enabled?(id)
    return true unless @context && @context.respond_to?(:tabs_available)
    tabs = @context.tabs_available(@current_user,
                                   :session => session,
                                   :include_hidden_unused => true,
                                   :root_account => @domain_root_account)
    valid = tabs.any?{|t| t[:id] == id }
    render_tab_disabled unless valid
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
  # if authorized_action(object, @current_user, session, :update)
  #   render
  # end
  def authorized_action(object, actor, rights)
    can_do = object.grants_any_right?(actor, session, *Array(rights))
    render_unauthorized_action unless can_do
    can_do
  end
  alias :authorized_action? :authorized_action

  def render_unauthorized_action
    respond_to do |format|
      @needs_login = (!@current_user && !@files_domain)
      run_login_hooks if @needs_login

      @show_left_side = false
      clear_crumbs
      params = request.path_parameters
      params[:format] = nil
      @headers = !!@current_user if @headers != false
      @files_domain = @account_domain && @account_domain.host_type == 'files'
      format.html {
        store_location
        return if !@current_user && initiate_delegated_login(request.host_with_port)
        if @context.is_a?(Course) && @context_enrollment
          start_date = @context_enrollment.enrollment_dates.map(&:first).compact.min if @context_enrollment.state_based_on_date == :inactive
          if @context.claimed?
            @unauthorized_message = t('#application.errors.unauthorized.unpublished', "This course has not been published by the instructor yet.")
            @unauthorized_reason = :unpublished
          elsif start_date && start_date > Time.now.utc
            @unauthorized_message = t('#application.errors.unauthorized.not_started_yet', "The course you are trying to access has not started yet.  It will start %{date}.", :date => TextHelper.date_string(start_date))
            @unauthorized_reason = :unpublished
          end
        end

        @is_delegated = delegated_authentication_url?
        render "shared/unauthorized", status: :unauthorized
      }
      format.zip { redirect_to(url_for(params)) }
      format.json { render_json_unauthorized }
    end
    response.headers["Pragma"] = "no-cache"
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
  end

  def delegated_authentication_url?
    @domain_root_account.delegated_authentication? &&
    !@domain_root_account.ldap_authentication? &&
    !params[:canvas_login]
  end

  # To be used as a before_filter, requires controller or controller actions
  # to have their urls scoped to a context in order to be valid.
  # So /courses/5/assignments or groups/1/assignments would be valid, but
  # not /assignments
  def require_context
    get_context
    if !@context
      if request.path.match(/\A\/profile/)
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
    return require_context && authorized_action(@context, @current_user, :read)
  end

  helper_method :clean_return_to

  MAX_ACCOUNT_LINEAGE_TO_SHOW_IN_CRUMBS = 3

  # Can be used as a before_filter, or just called from controller code.
  # Assigns the variable @context to whatever context the url is scoped
  # to.  So /courses/5/assignments would have a @context=Course.find(5).
  # Also assigns @context_membership to the membership type of @current_user
  # if @current_user is a member of the context.
  def get_context
    unless @context
      if params[:course_id]
        @context = api_find(Course.active, params[:course_id])
        params[:context_id] = params[:course_id]
        params[:context_type] = "Course"
        if @context && session[:enrollment_uuid_course_id] == @context.id
          session[:enrollment_uuid_count] ||= 0
          if session[:enrollment_uuid_count] > 4
            session[:enrollment_uuid_count] = 0
            self.extend(TextHelper)
            flash[:html_notice] = mt "#application.notices.need_to_accept_enrollment", "You'll need to [accept the enrollment invitation](%{url}) before you can fully participate in this course.", :url => course_url(@context)
          end
          session[:enrollment_uuid_count] += 1
        end
        @context_enrollment = @context.enrollments.where(user_id: @current_user).sort_by{|e| [e.state_sortable, e.rank_sortable, e.id] }.first if @context && @current_user
        @context_membership = @context_enrollment
      elsif params[:account_id] || (self.is_a?(AccountsController) && params[:account_id] = params[:id])
        @context = api_find(Account, params[:account_id])
        params[:context_id] = @context.id
        params[:context_type] = "Account"
        @context_enrollment = @context.account_users.where(user_id: @current_user.id).first if @context && @current_user
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
      elsif request.path.match(/\A\/profile/) || request.path == '/' || request.path.match(/\A\/dashboard\/files/) || request.path.match(/\A\/calendar/) || request.path.match(/\A\/assignments/) || request.path.match(/\A\/files/)
        @context = @current_user
        @context_membership = @context
      end

      assign_localizer if @context.present?

      unless api_request?
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
          crumb_url = named_context_url(@context, :context_url) if @context.grants_right?(@current_user, :read)
          add_crumb(@context.short_name, crumb_url)
        end

        set_badge_counts_for(@context, @current_user, @current_enrollment)
      end
    end
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
    only_contexts = ActiveRecord::Base.parse_asset_string_list(params[:only_contexts])
    if @context && @context.is_a?(User)
      # we already know the user can read these courses and groups, so skip
      # the grants_right? check to avoid querying for the various memberships
      # again.
      courses = @context.enrollments.current.shard(@context).select { |e| e.state_based_on_date == :active }.map(&:course).uniq
      groups = opts[:include_groups] ? @context.current_groups.with_each_shard.reject{|g| g.context_type == "Course" &&
          g.context.concluded?} : []
      if only_contexts.present?
        # find only those courses and groups passed in the only_contexts
        # parameter, but still scoped by user so we know they have rights to
        # view them.
        course_ids = only_contexts.select { |c| c.first == "Course" }.map(&:last)
        courses = course_ids.empty? ? [] : courses.select { |c| course_ids.include?(c.id) }
        group_ids = only_contexts.select { |c| c.first == "Group" }.map(&:last)
        groups = group_ids.empty? ? [] : groups.select { |g| group_ids.include?(g.id) } if opts[:include_groups]
      end

      if opts[:favorites_first]
        favorite_course_ids = @context.favorite_context_ids("Course")
        courses = courses.sort_by {|c| [favorite_course_ids.include?(c.id) ? 0 : 1, Canvas::ICU.collation_key(c.name)]}
      end

      @contexts.concat courses
      @contexts.concat groups
    end
    if params[:include_contexts]
      params[:include_contexts].split(",").each do |include_context|
        # don't load it again if we've already got it
        next if @contexts.any? { |c| c.asset_string == include_context }
        context = Context.find_by_asset_string(include_context)
        @contexts << context if context && context.grants_right?(@current_user, :read)
      end
    end
    @contexts = @contexts.uniq
    Course.require_assignment_groups(@contexts)
    @context_enrollment = @context.membership_for_user(@current_user) if @context.respond_to?(:membership_for_user)
    @context_membership = @context_enrollment
  end

  def set_badge_counts_for(context, user, enrollment=nil)
    return if @js_env && @js_env[:badge_counts].present?
    return unless context.present? && user.present?
    return unless context.respond_to?(:content_participation_counts) # just Course and Group so far
    js_env(:badge_counts => badge_counts_for(context, user, enrollment))
  end

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

  # Retrieves all assignments for all contexts held in the @contexts variable.
  # Also retrieves submissions and sorts the assignments based on
  # their due dates and submission status for the given user.
  def get_sorted_assignments
    @courses = @contexts.select{ |c| c.is_a?(Course) }
    @just_viewing_one_course = @context.is_a?(Course) && @courses.length == 1
    @context_codes = @courses.map(&:asset_string)
    @context = @courses.first

    if @just_viewing_one_course

      # fake assignment used for checking if the @current_user can read unpublished assignments
      fake = @context.assignments.scoped.new
      fake.workflow_state = 'unpublished'

      assignment_scope = :active_assignments
      if !fake.grants_right?(@current_user, session, :read)
        # user should not see unpublished assignments
        assignment_scope = :published_assignments
      end

      @groups = @context.assignment_groups.active
      @assignments = AssignmentGroup.visible_assignments(@current_user, @context, @groups)
    else
      assignments_and_groups = Shard.partition_by_shard(@courses) do |courses|
        [[Assignment.published.for_course(courses).all,
         AssignmentGroup.active.for_course(courses).order(:position).all]]
      end
      @assignments = assignments_and_groups.map(&:first).flatten
      @groups = assignments_and_groups.map(&:last).flatten
    end
    @assignment_groups = @groups

    @courses.each { |course| log_course(course) }

    if @current_user
      @submissions = @current_user.submissions.with_each_shard
      @submissions.each{ |s| s.mute if s.muted_assignment? }
    else
      @submissions = []
    end

    @assignments.map! {|a| a.overridden_for(@current_user)}
    sorted = SortsAssignments.by_due_date({
      :assignments => @assignments,
      :user => @current_user,
      :session => session,
      :upcoming_limit => 1.week.from_now,
      :submissions => @submissions
    })

    @past_assignments = sorted.past
    @undated_assignments = sorted.undated
    @ungraded_assignments = sorted.ungraded
    @upcoming_assignments = sorted.upcoming
    @future_assignments = sorted.future
    @overdue_assignments = sorted.overdue

    condense_assignments if requesting_main_assignments_page?

    categorized_assignments.each(&:sort!)
  end

  def categorized_assignments
    [
      @assignments,
      @upcoming_assignments,
      @past_assignments,
      @ungraded_assignments,
      @undated_assignments,
      @future_assignments
    ]
  end

  def condense_assignments
    num_weeks = @future_assignments.length > 5 ? 2 : 4
    @future_assignments = SortsAssignments.up_to(@future_assignments, num_weeks.weeks.from_now)
    num_weeks = @past_assignments.length < 5 ? 2 : 4
    @past_assignments = SortsAssignments.down_to(@past_assignments, num_weeks.weeks.ago)

    @overdue_assignments = SortsAssignments.down_to(@overdue_assignments, 4.weeks.ago)
    @ungraded_assignments = SortsAssignments.down_to(@ungraded_assignments, 4.weeks.ago)
  end

  def log_course(course)
    log_asset_access("assignments:#{course.asset_string}", "assignments", "other")
  end

  def requesting_main_assignments_page?
    request.path.match(/\A\/assignments/)
  end

  # Calculates the file storage quota for @context
  def get_quota
    quota_params = Attachment.get_quota(@context)
    @quota = quota_params[:quota]
    @quota_used = quota_params[:quota_used]
  end

  # Renders a quota exceeded message if the @context's quota is exceeded
  def quota_exceeded(redirect=nil)
    redirect ||= root_url
    get_quota
    if response.body.size + @quota_used > @quota
      if @context.is_a?(Account)
        error = t "#application.errors.quota_exceeded_account", "Account storage quota exceeded"
      elsif @context.is_a?(Course)
        error = t "#application.errors.quota_exceeded_course", "Course storage quota exceeded"
      elsif @context.is_a?(Group)
        error = t "#application.errors.quota_exceeded_group", "Group storage quota exceeded"
      elsif @context.is_a?(User)
        error = t "#application.errors.quota_exceeded_user", "User storage quota exceeded"
      else
        error = t "#application.errors.quota_exceeded", "Storage quota exceeded"
      end
      respond_to do |format|
        flash[:error] = error unless request.format.to_s == "text/plain"
        format.html {redirect_to redirect }
        format.json {render :json => {:errors => {:base => error}} }
        format.text {render :json => {:errors => {:base => error}} }
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
      if Context::ContextTypes.const_defined?(@context_type)
        @context_class = Context::ContextTypes.const_get(@context_type)
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
    flash.discard if request.xhr? || request.format.to_s == 'text/plain'
  end

  def cancel_cache_buster
    @cancel_cache_buster = true
  end

  def cache_buster
    # Annoying problem.  If I set the cache-control to anything other than "no-cache, no-store"
    # then the local cache is used when the user clicks the 'back' button.  I don't know how
    # to tell the browser to ALWAYS check back other than to disable caching...
    return true if @cancel_cache_buster || request.xhr? || api_request?
    response.headers["Pragma"] = "no-cache"
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
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
    if (@developer_key && params[:user_request]) || (!@developer_key && @current_user && !request.xhr? && request.get?)
      generate_page_view
    end
  end

  def require_reacceptance_of_terms
    if session[:require_terms] && !api_request? && request.get?
      render "shared/terms_required", status: :unauthorized
      false
    end
  end

  def clear_policy_cache
    AdheresToPolicy::Cache.clear
  end

  def generate_page_view(user=@current_user)
    attributes = { :user => user, :developer_key => @developer_key, :real_user => @real_current_user }
    @page_view = PageView.generate(request, attributes)
    @page_view.user_request = true if params[:user_request] || (user && !request.xhr? && request.get?)
    @page_before_render = Time.now.utc
  end

  def generate_new_page_view
    return true if !page_views_enabled?

    generate_page_view
    @page_view.generated_by_hand = true
  end

  def disable_page_views
    @log_page_views = false
    true
  end

  def update_enrollment_last_activity_at
    activity = Enrollment::RecentActivity.new(@context_enrollment, @context)
    activity.record_for_access(response)
  end

  # Asset accesses are used for generating usage statistics.  This is how
  # we say, "the user just downloaded this file" or "the user just
  # viewed this wiki page".  We can then after-the-fact build statistics
  # and reports from these accesses.  This is currently being used
  # to generate access reports per student per course.
  def log_asset_access(asset, asset_category, asset_group=nil, level=nil, membership_type=nil)
    user = @current_user
    user ||= User.where(id: session['file_access_user_id']).first if session['file_access_user_id'].present?
    return unless user && @context && asset
    return if asset.respond_to?(:new_record?) && asset.new_record?
    @accessed_asset = {
      :user => user,
      :code => asset.is_a?(String) ? asset : asset.asset_string,
      :group_code => asset_group.is_a?(String) ? asset_group : (asset_group.asset_string rescue 'unknown'),
      :category => asset_category,
      :membership_type => membership_type || (@context_membership && @context_membership.class.to_s rescue nil),
      :level => level
    }
  end

  def log_page_view
    return true if !page_views_enabled?

    user = @current_user || (@accessed_asset && @accessed_asset[:user])
    if user && @log_page_views != false
      updated_fields = params.slice(:interaction_seconds)
      if request.xhr? && params[:page_view_id] && !updated_fields.empty? && !(@page_view && @page_view.generated_by_hand)
        @page_view = PageView.find_for_update(params[:page_view_id])
        if @page_view
          response.headers["X-Canvas-Page-View-Id"] = @page_view.id.to_s if @page_view.id
          @page_view.do_update(updated_fields)
          @page_view_update = true
        end
      end
      # If we're logging the asset access, and it's either a participatory action
      # or it's not an update to an already-existing page_view.  We check to make sure
      # it's not an update because if the page_view already existed, we don't want to
      # double-count it as multiple views when it's really just a single view.

      if @accessed_asset && (@accessed_asset[:level] == 'participate' || !@page_view_update)
        @access = AssetUserAccess.where(user_id: user.id, asset_code: @accessed_asset[:code]).first_or_initialize
        @accessed_asset[:level] ||= 'view'
        access_context = @context.is_a?(UserProfile) ? @context.user : @context
        @access.log access_context, @accessed_asset

        if @page_view.nil? && page_views_enabled? && %w{participate submit}.include?(@accessed_asset[:level])
          generate_page_view(user)
        end

        if @page_view
          @page_view.participated = %w{participate submit}.include?(@accessed_asset[:level])
          @page_view.asset_user_access = @access
        end

        @page_view_update = true
      end
      if @page_view && !request.xhr? && request.get? && (response.content_type || "").to_s.match(/html/)
        @page_view.render_time ||= (Time.now.utc - @page_before_render) rescue nil
        @page_view_update = true
      end
      if @page_view && @page_view_update
        @page_view.context = @context if !@page_view.context_id
        @page_view.account_id = @domain_root_account.id
        @page_view.store
        RequestContextGenerator.store_page_view_meta(@page_view)
      end
    else
      @page_view.destroy if @page_view && !@page_view.new_record?
    end
  rescue => e
    logger.error "Pageview error!"
    raise e if Rails.env.development?
    true
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

    if config.consider_all_requests_local || local_request?
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

      unless exception.respond_to?(:skip_error_report?) && exception.skip_error_report?
        error_info = {
          :url => request.url,
          :user => @current_user,
          :user_agent => request.headers['User-Agent'],
          :request_context_id => RequestContextGenerator.request_id,
          :account => @domain_root_account,
          :request_method => request.request_method_symbol,
          :format => request.format,
        }.merge(ErrorReport.useful_http_env_stuff_from_request(request))

        error = if @domain_root_account
          @domain_root_account.shard.activate do
            ErrorReport.log_exception(type, exception, error_info)
          end
        else
          ErrorReport.log_exception(type, exception, error_info)
        end
      end

      if api_request?
        rescue_action_in_api(exception, error, response_code)
      else
        render_rescue_action(exception, error, status, status_code)
      end
    rescue => e
      # error generating the error page? failsafe.
      render_optional_error_file response_code_for_rescue(exception)
      ErrorReport.log_exception(:default, e)
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
    else
      request.format = :html
      template = exception.error_template if exception.respond_to?(:error_template)
      unless template
        erbfile = "#{status.to_s[0,3]}_message.html.erb"
        erbpath = File.join('app', 'views', 'shared', 'errors', erbfile)
        erbfile = "500_message.html.erb" unless File.exists?(erbpath)
        template = "shared/errors/#{erbfile}"
      end

      @status_code = status_code
      message = exception.is_a?(RequestError) ? exception.message : nil
      render :template => template,
        :layout => 'application',
        :status => status,
        :locals => {
          :error => error,
          :exception => exception,
          :status => status,
          :message => message,
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
    when ActionController::ParameterMissing
      data = { errors: [{message: "#{exception.param} is missing"}] }
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

  def local_request?
    false
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

  # Had to overwrite this method so we can say you don't need to have an
  # authenticity_token if the request is coming from an api request.
  # we also check for the session token not being set at all here, to catch
  # those who have cookies disabled.
  def verify_authenticity_token
    token = params[request_forgery_protection_token].try(:gsub, " ", "+")
    params[request_forgery_protection_token] = token if token

    if    protect_against_forgery? &&
          !request.get? &&
          !api_request?
      if cookies[:_csrf_token].nil? && session.empty? && !request.xhr? && !api_request?
        # the session should have the token stored by now, but doesn't? sounds
        # like the user doesn't have cookies enabled.
        redirect_to(login_url(:needs_cookies => '1'))
        return false
      else
        raise(ActionController::InvalidAuthenticityToken) unless CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(session, cookies, form_authenticity_param) ||
          CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(session, cookies, request.headers['X-CSRF-Token'])
      end
    end
    Rails.logger.warn("developer_key id: #{@developer_key.id}") if @developer_key
    return true
  end

  def form_authenticity_token
    masked_authenticity_token
  end

  API_REQUEST_REGEX = %r{\A/api/v\d}
  LTI_API_REQUEST_REGEX = %r{\A/api/lti/}

  def api_request?
    @api_request ||= !!request.path.match(API_REQUEST_REGEX) || !!request.path.match(LTI_API_REQUEST_REGEX)
  end

  def session_loaded?
    session.send(:loaded?) rescue false
  end

  # Retrieving wiki pages needs to search either using the id or
  # the page title.
  def get_wiki_page
    @wiki = @context.wiki
    @wiki.check_has_front_page

    @page_name = params[:wiki_page_id] || params[:id] || (params[:wiki_page] && params[:wiki_page][:title])
    if(params[:format] && !['json', 'html'].include?(params[:format]))
      @page_name += ".#{params[:format]}"
      params[:format] = 'html'
    end
    return if @page || !@page_name

    @page = @wiki.find_page(@page_name) if params[:action] != 'create'

    unless @page
      if params[:titleize].present? && !value_to_boolean(params[:titleize])
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
    elsif tag.content_type == 'Lti::MessageHandler'
      url_params[:resource_link_fragment] = "ContentTag:#{tag.id}"
      redirect_to named_context_url(context, :context_basic_lti_launch_request_url, tag.content_id, url_params)
    elsif tag.content_type == 'ExternalUrl'
      @tag = tag
      @module = tag.context_module
      log_asset_access(@tag, "external_urls", "external_urls")
      tag.context_module_action(@current_user, :read) unless tag.locked_for? @current_user
      render 'context_modules/url_show'
    elsif tag.content_type == 'ContextExternalTool'
      @tag = tag
      if @tag.context.is_a?(Assignment)
        @assignment = @tag.context
        @resource_title = @assignment.title
        @module_tag = @context.context_module_tags.not_deleted.find(params[:module_item_id]) if params[:module_item_id]
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
        log_asset_access(@tool, "external_tools", "external_tools")
        @opaque_id = @tool.opaque_identifier_for(@tag)

        @lti_launch = Lti::Launch.new

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
          @return_url = external_content_success_url('external_tool_redirect')
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
                                                        content_tag: tag,
                                                        assignment: @assignment,
                                                        tool: @tool})
        adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context).prepare_tool_launch(@return_url, variable_expander, opts)

        if tag.try(:context_module)
          add_crumb tag.context_module.name, context_url(@context, :context_context_modules_url)
        end

        if @assignment
          return unless require_user
          add_crumb(@resource_title)
          @prepend_template = 'assignments/description'
          @lti_launch.params = adapter.generate_post_payload_for_assignment(@assignment, lti_grade_passback_api_url(@tool), blti_legacy_grade_passback_api_url(@tool))
        else
          @lti_launch.params = adapter.generate_post_payload
        end

        @lti_launch.resource_url = @resource_url
        @lti_launch.link_text = @resource_title
        @lti_launch.analytics_id = @tool.tool_id

        @append_template = 'context_modules/tool_sequence_footer'
        render ExternalToolsController::TOOL_DISPLAY_TEMPLATES['default']
      end
    else
      flash[:error] = t "#application.errors.invalid_tag_type", "Didn't recognize the item type for this tag"
      redirect_to named_context_url(context, error_redirect_symbol)
    end
  end

  # pass it a context or an array of contexts and it will give you a link to the
  # person's calendar with only those things checked.
  def calendar_url_for(contexts_to_link_to = nil, options={})
    options[:query] ||= {}
    options[:anchor] ||= {}
    contexts_to_link_to = Array(contexts_to_link_to)
    if event = options.delete(:event)
      options[:query][:event_id] = event.id
    end
    if !contexts_to_link_to.empty? && options[:anchor].is_a?(Hash)
      options[:anchor][:show] = contexts_to_link_to.collect{ |c|
        "group_#{c.class.to_s.downcase}_#{c.id}"
      }.join(',')
      options[:anchor] = options[:anchor].to_json
    end
    options[:query][:include_contexts] = contexts_to_link_to.map{|c| c.asset_string}.join(",") unless contexts_to_link_to.empty?
    calendar_url(
      options[:query].merge(options[:anchor].empty? ? {} : {
        :anchor => options[:anchor].unpack('H*').first # calendar anchor is hex encoded
      })
    )
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
      ts, sig = @current_user && @current_user.access_verifier

      # add parameters so that the other domain can create a session that
      # will authorize file access but not full app access.  We need this in
      # case there are relative URLs in the file that point to other pieces
      # of content.
      opts = { :user_id => @current_user.try(:id), :ts => ts, :sf_verifier => sig }
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
      elsif feature == :yo
        Canvas::Plugin.find(:yo).try(:enabled?)
      elsif feature == :twitter
        !!Twitter::Connection.config
      elsif feature == :linked_in
        !!LinkedIn::Connection.config
      elsif feature == :diigo
        !!Diigo::Connection.config
      elsif feature == :google_docs
        !!GoogleDocs::Connection.config
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

  def show_new_dashboard?
    @current_user && @current_user.preferences[:new_dashboard]
  end

  def temporary_user_code(generate=true)
    if generate
      session[:temporary_user_code] ||= "tmp_#{Digest::MD5.hexdigest("#{Time.now.to_i.to_s}_#{rand.to_s}")}"
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
    unless Account.site_admin.grants_right?(@current_user, permission)
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

  def verified_file_download_url(attachment, context = nil, *opts)
    verifier = Attachments::Verification.new(attachment).verifier_for_user(@current_user, context.try(:asset_string))
    file_download_url(attachment, { :verifier => verifier }, *opts)
  end
  helper_method :verified_file_download_url

  def user_content(str, cache_key = nil)
    return nil unless str
    return str.html_safe unless str.match(/object|embed|equation_image/)

    UserContent.escape(str, request.host_with_port)
  end
  helper_method :user_content

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
    @pseudonym_session
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
    @current_user.try(:stamp_logout_time!)
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
    stringify_json_ids? ? Api.recursively_stringify_json_ids(obj) : obj
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
        options[:text] = json
        options[:content_type] = "text/html"
      else
        options[:json] = json
      end
    end
    super
  end

  def jammit_css_bundles; @jammit_css_bundles ||= []; end
  helper_method :jammit_css_bundles

  def jammit_css(*args)
    opts = (args.last.is_a?(Hash) ? args.pop : {})
    Array(args).flatten.each do |bundle|
      jammit_css_bundles << [bundle, opts[:plugin]] unless jammit_css_bundles.include? [bundle, opts[:plugin]]
    end
    nil
  end
  helper_method :jammit_css

  def js_bundles; @js_bundles ||= []; end
  helper_method :js_bundles

  # Use this method to place a bundle on the page, note that the end goal here
  # is to only ever include one bundle per page load, so use this with care and
  # ensure that the bundle you are requiring isn't simply a dependency of some
  # other bundle.
  #
  # Bundles are defined in app/coffeescripts/bundles/<bundle>.coffee
  #
  # usage: js_bundle :gradebook2
  #
  # Only allows multiple arguments to support old usage of jammit_js
  #
  # Optional :plugin named parameter allows you to specify a plugin which
  # contains the bundle. Example:
  #
  # js_bundle :gradebook2, :plugin => :my_feature
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
    t("Your browser does not meet the minimum requirements for Canvas. Please visit the *Canvas Guides* for a complete list of supported browsers.", :wrapper => view_context.link_to('\1', 'http://guides.instructure.com/s/2204/m/4214/l/41056-which-browsers-does-canvas-support'))
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

  def profile_data(profile, viewer, session, includes)
    extend Api::V1::UserProfile
    extend Api::V1::Course
    extend Api::V1::Group
    includes ||= []
    data = user_profile_json(profile, viewer, session, includes, profile)
    data[:can_edit] = viewer == profile.user
    data[:can_edit_name] = data[:can_edit] && profile.user.user_can_edit_name?
    known_user = viewer.load_messageable_user(profile.user)
    common_courses = []
    common_groups = []
    if viewer != profile.user
      if known_user
        common_courses = known_user.common_courses.map do |course_id, roles|
          next if course_id.zero?
          c = course_json(Course.find(course_id), @current_user, session, ['html_url'], false)
          c[:roles] = roles.map { |role| Enrollment.readable_type(role) }
          c
        end.compact
        common_groups = known_user.common_groups.map do |group_id, roles|
          next if group_id.zero?
          g = group_json(Group.find(group_id), @current_user, session, :include => ['html_url'])
          # in the future groups will have more roles and we'll need soemthing similar to
          # the roles.map above in courses
          g[:roles] = [t('#group.memeber', "Member")]
          g
        end.compact
      end
    end
    data[:common_contexts] = [] + common_courses + common_groups
    data[:known_user] = known_user
    data
  end

  def self.batch_jobs_in_actions(opts = {})
    batch_opts = opts.delete(:batch)
    around_filter(opts) do |controller, action|
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
      hash[:WIKI_PAGE] = wiki_page_json(@page, @current_user, session)
      hash[:WIKI_PAGE_REVISION] = (current_version = @page.versions.current) ? Api.stringify_json_id(current_version.number) : nil
      hash[:WIKI_PAGE_SHOW_PATH] = named_context_url(@context, :context_wiki_page_path, @page)
      hash[:WIKI_PAGE_EDIT_PATH] = named_context_url(@context, :edit_context_wiki_page_path, @page)
      hash[:WIKI_PAGE_HISTORY_PATH] = named_context_url(@context, :context_wiki_page_revisions_path, @page)

      if @context.is_a?(Course) && @context.grants_right?(@current_user, :read)
        hash[:COURSE_ID] = @context.id
        hash[:MODULES_PATH] = polymorphic_path([@context, :context_modules])
      end
    end

    js_env hash
  end

  def google_docs_connection
    ## @real_current_user first ensures that a masquerading user never sees the
    ## masqueradee's files, but in general you may want to block access to google
    ## docs for masqueraders earlier in the request
    if logged_in_user
      service_token, service_secret = Rails.cache.fetch(['google_docs_tokens', logged_in_user].cache_key) do
        service = logged_in_user.user_services.where(service: "google_docs").first
        service && [service.token, service.secret]
      end
      raise GoogleDocs::NoTokenError unless service_token && service_secret
      google_docs = GoogleDocs::Connection.new(service_token, service_secret)
    else
      google_docs = GoogleDocs::Connection.new(session[:oauth_gdocs_access_token_token], session[:oauth_gdocs_access_token_secret])
    end
    google_docs
  end

  def google_drive_connection
    return unless Canvas::Plugin.find(:google_drive).try(:settings)
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

    GoogleDocs::DriveConnection.new(refresh_token, access_token) if refresh_token && access_token
  end

  def google_service_connection
    google_drive_connection || google_docs_connection
  end

  def google_drive_user_client
    if logged_in_user
      refresh_token, access_token = Rails.cache.fetch(['google_drive_tokens', logged_in_user].cache_key) do
        service = logged_in_user.user_services.where(service: "google_drive").first
        service && [service.token, service.access_token]
      end
    else
      refresh_token = session[:oauth_gdrive_refresh_token]
      access_token = session[:oauth_gdrive_access_token]
    end
    google_drive_client(refresh_token, access_token)
  end

  def google_drive_client(refresh_token=nil, access_token=nil)
    client_secrets = Canvas::Plugin.find(:google_drive).try(:settings)
    GoogleDrive::Client.create(client_secrets, refresh_token, access_token)
  end


  def twitter_connection
    if @current_user
      service = @current_user.user_services.where(service: "twitter").first
      return Twitter::Connection.new(service.token, service.secret)
    else
      return Twitter::Connection.new(session[:oauth_twitter_access_token_token], session[:oauth_twitter_access_token_secret])
    end
  end

  def self.region
    nil
  end

  def show_request_delete_account
    false
  end
  helper_method :show_request_delete_account

  def request_delete_account_link
    nil
  end
  helper_method :request_delete_account_link
end

