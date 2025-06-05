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

# @API Users
# API for accessing information on the current and other users.
#
# Throughout this API, the `:user_id` parameter can be replaced with `self` as
# a shortcut for the id of the user accessing the API. For instance,
# `users/:user_id/page_views` can be accessed as `users/self/page_views` to
# access the current user's page views.
#
# @model UserDisplay
#     {
#       "id": "UserDisplay",
#       "description": "This mini-object is used for secondary user responses, when we just want to provide enough information to display a user.",
#       "properties": {
#         "id": {
#           "description": "The ID of the user.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "short_name": {
#           "description": "A short name the user has selected, for use in conversations or other less formal places through the site.",
#           "example": "Shelly",
#           "type": "string"
#         },
#         "avatar_image_url": {
#           "description": "If avatars are enabled, this field will be included and contain a url to retrieve the user's avatar.",
#           "example": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "URL to access user, either nested to a context or directly.",
#           "example": "https://school.instructure.com/courses/:course_id/users/:user_id",
#           "type": "string"
#         }
#       }
#     }
#
# @model AnonymousUserDisplay
#     {
#       "id": "AnonymousUserDisplay",
#       "description": "This mini-object is returned in place of UserDisplay when returning student data for anonymous assignments, and includes an anonymous ID to identify a user within the scope of a single assignment.",
#       "properties": {
#         "anonymous_id": {
#           "description": "A unique short ID identifying this user within the scope of a particular assignment.",
#           "example": "xn29Q",
#           "type": "string"
#         },
#         "avatar_image_url": {
#           "description": "A URL to retrieve a generic avatar.",
#           "example": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
#           "type": "string"
#         },
#         "display_name": {
#           "description": "The anonymized display name for the student.",
#           "example": "Student 2",
#           "type": "string"
#         }
#       }
#     }
#
# @model User
#     {
#       "id": "User",
#       "description": "A Canvas user, e.g. a student, teacher, administrator, observer, etc.",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "The ID of the user.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "name": {
#           "description": "The name of the user.",
#           "example": "Sheldon Cooper",
#           "type": "string"
#         },
#         "sortable_name": {
#           "description": "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
#           "example": "Cooper, Sheldon",
#           "type": "string"
#         },
#         "last_name": {
#           "description": "The last name of the user.",
#           "example": "Cooper",
#           "type": "string"
#         },
#         "first_name": {
#           "description": "The first name of the user.",
#           "example": "Sheldon",
#           "type": "string"
#         },
#         "short_name": {
#           "description": "A short name the user has selected, for use in conversations or other less formal places through the site.",
#           "example": "Shelly",
#           "type": "string"
#         },
#         "sis_user_id": {
#           "description": "The SIS ID associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
#           "example": "SHEL93921",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "The id of the SIS import.  This field is only included if the user came from a SIS import and has permissions to manage SIS information.",
#           "example": "18",
#           "type": "integer",
#           "format": "int64"
#         },
#         "integration_id": {
#           "description": "The integration_id associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
#           "example": "ABC59802",
#           "type": "string"
#         },
#         "login_id": {
#           "description": "The unique login id for the user.  This is what the user uses to log in to Canvas.",
#           "example": "sheldon@caltech.example.com",
#           "type": "string"
#         },
#         "avatar_url": {
#           "description": "If avatars are enabled, this field will be included and contain a url to retrieve the user's avatar.",
#           "example": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
#           "type": "string"
#         },
#         "avatar_state": {
#           "description": "Optional: If avatars are enabled and caller is admin, this field can be requested and will contain the current state of the user's avatar.",
#           "example": "approved",
#           "type": "string"
#         },
#         "enrollments": {
#           "description": "Optional: This field can be requested with certain API calls, and will return a list of the users active enrollments. See the List enrollments API for more details about the format of these records.",
#           "type": "array",
#           "items": { "$ref": "Enrollment" }
#         },
#         "email": {
#           "description": "Optional: This field can be requested with certain API calls, and will return the users primary email address.",
#           "example": "sheldon@caltech.example.com",
#           "type": "string"
#         },
#         "locale": {
#           "description": "Optional: This field can be requested with certain API calls, and will return the users locale in RFC 5646 format.",
#           "example": "tlh",
#           "type": "string"
#         },
#         "last_login": {
#           "description": "Optional: This field is only returned in certain API calls, and will return a timestamp representing the last time the user logged in to canvas.",
#           "example": "2012-05-30T17:45:25Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "time_zone": {
#           "description": "Optional: This field is only returned in certain API calls, and will return the IANA time zone name of the user's preferred timezone.",
#           "example": "America/Denver",
#           "type": "string"
#         },
#         "bio": {
#           "description": "Optional: The user's bio.",
#           "example": "I like the Muppets.",
#           "type": "string"
#         },
#         "pronouns": {
#           "description": "Optional: This field is only returned if pronouns are enabled, and will return the pronouns of the user.",
#           "example": "he/him",
#           "type": "string"
#         }
#       }
#     }
#
#
#
class UsersController < ApplicationController
  include SearchHelper
  include SectionTabHelper
  include I18nUtilities
  include CustomColorHelper
  include DashboardHelper
  include Api::V1::Submission
  include ObserverEnrollmentsHelper

  before_action :require_user, only: %i[grades
                                        merge
                                        kaltura_session
                                        ignore_item
                                        ignore_stream_item
                                        close_notification
                                        mark_avatar_image
                                        user_dashboard
                                        toggle_hide_dashcard_color_overlays
                                        masquerade
                                        external_tool
                                        dashboard_sidebar
                                        settings
                                        activity_stream
                                        activity_stream_summary
                                        pandata_events_token
                                        dashboard_cards
                                        user_graded_submissions
                                        show
                                        terminate_sessions
                                        dashboard_stream_items
                                        show_k5_dashboard
                                        bookmark_search
                                        services]
  before_action :require_registered_user, only: [:delete_user_service,
                                                 :create_user_service]
  before_action :reject_student_view_student, only: %i[delete_user_service
                                                       create_user_service
                                                       merge
                                                       user_dashboard
                                                       masquerade]
  skip_before_action :load_user, only: [:create_self_registered_user]
  before_action :require_self_registration, only: %i[new create create_self_registered_user]
  before_action :check_limited_access_for_students, only: %i[create_file set_custom_color]

  def grades
    @user = User.where(id: params[:user_id]).first if params[:user_id].present?
    @user ||= @current_user
    if authorized_action(@user, @current_user, :read_grades)
      crumb_url = polymorphic_url([@current_user]) if @user.grants_right?(@current_user, session, :view_statistics)
      add_crumb(@current_user.short_name, crumb_url)
      add_crumb(t("crumbs.grades", "Grades"), grades_path)

      current_active_enrollments = @user
                                   .enrollments
                                   .current
                                   .preload(:course, :enrollment_state, :scores)
                                   .shard(@user)
                                   .to_a

      @presenter = GradesPresenter.new(current_active_enrollments)

      if @presenter.has_single_enrollment?
        redirect_to course_grades_url(@presenter.single_enrollment.course_id)
        return
      end

      @grading_periods = collected_grading_periods_for_presenter(
        @presenter, params[:course_id], params[:grading_period_id]
      )
      @grades = grades_for_presenter(@presenter, @grading_periods)
      js_env(grades_for_student_url:)

      ActiveRecord::Associations.preload(@observed_enrollments, :course)

      @page_title = t(:page_title, "Grades")
      js_bundle :user_grades
      css_bundle :user_grades
      render stream: can_stream_template?
    end
  end

  def grades_for_student
    enrollment = Enrollment.active.find(params[:enrollment_id])
    return unless authorized_action(enrollment, @current_user, :read_grades)

    grading_period_id = generate_grading_period_id(params[:grading_period_id])
    opts = { grading_period_id: } if grading_period_id

    grade_data = { hide_final_grades: enrollment.course.hide_final_grades? }

    if enrollment.course.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
      grade_data[:unposted_grade] = enrollment.unposted_current_score(opts)
      grade_data[:grade] = enrollment.computed_current_score(opts)
      # since this page is read_only, and enrollment.computed_current_score(opts) is a percentage value,
      # we can convert this into letter-grade
    else
      grade_data[:grade] = enrollment.effective_current_score(opts)
    end
    grading_standard = enrollment.course.grading_standard_or_default
    grade_data[:restrict_quantitative_data] = enrollment.course.restrict_quantitative_data?(@current_user)
    grade_data[:grading_scheme] = grading_standard.data
    grade_data[:points_based_grading_scheme] = grading_standard.points_based?
    grade_data[:scaling_factor] = grading_standard.scaling_factor

    render json: grade_data
  end

  def oauth
    unless feature_and_service_enabled?(params[:service])
      flash[:error] = t("service_not_enabled", "That service has not been enabled")
      return redirect_to(user_profile_url(@current_user))
    end
    return_to_url = params[:return_to] || user_profile_url(@current_user)
    case params[:service]
    when "google_drive"
      redirect_uri = oauth_success_url(service: "google_drive")
      session[:oauth_gdrive_nonce] = SecureRandom.hex
      state = Canvas::Security.create_jwt(redirect_uri:, return_to_url:, nonce: session[:oauth_gdrive_nonce])
      redirect_to GoogleDrive::Client.auth_uri(google_drive_client, state)
    end
  end

  def oauth_success
    oauth_request = nil
    if params[:oauth_token]
      oauth_request = OAuthRequest.where(token: params[:oauth_token], service: params[:service]).first
    elsif params[:code] && params[:state] && params[:service] == "google_drive"

      begin
        drive = google_drive_client
        drive.authorization.code = params[:code]
        drive.authorization.fetch_access_token!

        result = drive.get_about(fields: "user")

        json = Canvas::Security.decode_jwt(params[:state])
        render_unauthorized_action and return unless json["nonce"] && json["nonce"] == session[:oauth_gdrive_nonce]

        session.delete(:oauth_gdrive_nonce)

        if logged_in_user
          UserService.register(
            service: "google_drive",
            service_domain: "drive.google.com",
            token: drive.authorization.refresh_token,
            secret: drive.authorization.access_token,
            user: logged_in_user,
            service_user_id: result.user.permission_id,
            service_user_name: result.user.email_address
          )
        else
          session[:oauth_gdrive_access_token] = drive.authorization.access_token
          session[:oauth_gdrive_refresh_token] = drive.authorization.refresh_token
        end

        flash[:notice] = t("google_drive_added", "Google Drive account successfully added!")
        return redirect_to(json["return_to_url"])
      rescue Signet::AuthorizationError => e
        Canvas::Errors.capture_exception(:oauth, e, :info)
        flash[:error] = t("google_drive_authorization_failure", "Google Drive failed authorization for current user!")
      rescue Google::Apis::Error => e
        Canvas::Errors.capture_exception(:oauth, e, :warn)
        flash[:error] = e.to_s
      end
      return redirect_to(@current_user ? user_profile_url(@current_user) : root_url)
    end

    if !oauth_request || (request.host_with_port == oauth_request.original_host_with_port && oauth_request.user != @current_user)
      flash[:error] = t("oauth_fail", "OAuth Request failed. Couldn't find valid request")
      redirect_to(@current_user ? user_profile_url(@current_user) : root_url)
    elsif request.host_with_port != oauth_request.original_host_with_port
      url = url_for request.parameters.merge(host: oauth_request.original_host_with_port, only_path: false)
      redirect_to url
    else
      return_to(oauth_request.return_url, user_profile_url(@current_user))
    end
  end

  # @API List users in account
  # A paginated list of users associated with this account.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the
  #   results list. Must be at least 3 characters.
  #
  #   Note that the API will prefer matching on canonical user ID if the ID has
  #   a numeric form. It will only search against other fields if non-numeric
  #   in form, or if the numeric value doesn't yield any matches. Queries by
  #   administrative users will search on SIS ID, Integration ID, login ID,
  #   name, or email address
  #
  # @argument enrollment_type [String]
  #   When set, only return users enrolled with the specified course-level base role.
  #   This can be a base role type of 'student', 'teacher',
  #   'ta', 'observer', or 'designer'.
  #
  # @argument sort [String, "username"|"email"|"sis_id"|"integration_id"|"last_login"|"id"]
  #   The column to sort results by. For efficiency, use +id+ if you intend to retrieve
  #   many pages of results. In the future, other sort options may be rate-limited
  #   after 50 pages.
  #
  # @argument order [String, "asc"|"desc"]
  #   The order to sort the given column by.
  #
  # @argument include_deleted_users [Boolean]
  #   When set to true and used with an account context, returns users who have deleted
  #   pseudonyms for the context
  #
  #  @example_request
  #    curl https://<canvas>/api/v1/accounts/self/users?search_term=<search value> \
  #       -X GET \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def api_index
    get_context
    return unless authorized_action(@context, @current_user, :read_roster)

    includes = (params[:include] || []) & %w[avatar_url email last_login time_zone uuid ui_invoked]
    includes << "last_login" if params[:sort] == "last_login" && !includes.include?("last_login")
    include_deleted_users = value_to_boolean(params[:include_deleted_users])
    includes << "deleted_pseudonyms" if include_deleted_users

    search_term = params[:search_term].presence
    if search_term
      users = UserSearch.for_user_in_context(search_term,
                                             @context,
                                             @current_user,
                                             session,
                                             {
                                               order: params[:order],
                                               sort: params[:sort],
                                               enrollment_role_id: params[:role_filter_id],
                                               enrollment_type: params[:enrollment_type],
                                               include_deleted_users:
                                             })
    else
      users = UserSearch.scope_for(@context,
                                   @current_user,
                                   {
                                     order: params[:order],
                                     sort: params[:sort],
                                     enrollment_role_id: params[:role_filter_id],
                                     enrollment_type: params[:enrollment_type],
                                     ui_invoked: includes.include?("ui_invoked"),
                                     temporary_enrollment_recipients: value_to_boolean(params[:temporary_enrollment_recipients]),
                                     temporary_enrollment_providers: value_to_boolean(params[:temporary_enrollment_providers]),
                                     include_deleted_users:
                                   })
      users = users.with_last_login if params[:sort] == "last_login"
    end
    users.preload(:pseudonyms) if includes.include? "deleted_pseudonyms"

    page_opts = { total_entries: nil }
    if includes.include?("ui_invoked")
      page_opts = {} # let Folio calculate total entries
      includes.delete("ui_invoked")
    elsif params[:sort] == "id"
      # for a more efficient way to retrieve many pages in bulk
      users = BookmarkedCollection.wrap(UserSearch::Bookmarker.new(order: params[:order]), users)
    end

    GuardRail.activate(:secondary) do
      users = Api.paginate(users, self, api_v1_account_users_url, page_opts)

      user_json_preloads(users, includes.include?("email"))
      User.preload_last_login(users, @context.resolved_root_account_id) if includes.include?("last_login") && params[:sort] != "last_login"
      render json: users.map { |u| user_json(u, @current_user, session, includes) }
    end
  end

  before_action :require_password_session, only: [:masquerade]
  def masquerade
    @user = api_find(User, params[:user_id])
    return render_unauthorized_action unless @user.can_masquerade?(@real_current_user || @current_user, @domain_root_account)

    if request.post? || params[:stop_acting_as_user] == "true"
      if @user == @real_current_user
        session.delete(:become_user_id)
        session.delete(:enrollment_uuid)
      else
        session[:become_user_id] = params[:user_id]
      end
      return_url = session[:masquerade_return_to]
      session.delete(:masquerade_return_to)
      @current_user.associate_with_shard(@user.shard, :shadow) if PageView.db?
      if %r{.*/users/#{@user.id}/masquerade}.match?(request.referer)
        return_to(return_url, dashboard_url)
      else
        return_to(return_url, request.referer || dashboard_url)
      end
    else
      css_bundle :act_as_modal

      @page_title = t("Act as %{user_name}", user_name: @user.short_name)
      js_env act_as_user_data: {
        user: {
          name: @user.name,
          pronouns: @user.pronouns,
          short_name: @user.short_name,
          id: @user.id,
          avatar_image_url: @user.avatar_image_url,
          sortable_name: @user.sortable_name,
          email: @user.email,
          pseudonyms: @user.all_active_pseudonyms.map do |pseudonym|
            { login_id: pseudonym.unique_id,
              sis_id: pseudonym.sis_user_id,
              integration_id: pseudonym.integration_id }
          end
        }
      }
      render html: '<div id="application"></div><div id="act_as_modal"></div>'.html_safe, layout: "layouts/bare"
    end
  end

  def user_dashboard
    # Use the legacy to do list for non-students until it is ready for other roles
    if planner_enabled? && !@current_user.non_student_enrollment?
      css_bundle :react_todo_sidebar
    end
    session.delete(:parent_registration) if session[:parent_registration]
    check_incomplete_registration
    get_context

    # dont show crumbs on dashboard because it does not make sense to have a breadcrumb
    # trail back to home if you are already home
    clear_crumbs

    @show_footer = true

    if %r{\A/dashboard\z}.match?(request.path)
      return redirect_to(dashboard_url, status: :moved_permanently)
    end

    disable_page_views if @current_pseudonym && @current_pseudonym.unique_id == "pingdom@instructure.com"

    # Reload user settings so we don't get a stale value for K5_USER when switching dashboards
    @current_user.reload
    observed_users_list = observed_users(@current_user, session)
    k5_disabled = k5_disabled?
    k5_user = k5_user?(check_disabled: false)
    js_env({ K5_USER: k5_user && !k5_disabled }, true)

    course_permissions = @current_user.create_courses_permissions(@domain_root_account)
    js_env({
             PREFERENCES: {
               dashboard_view: @current_user.dashboard_view(@domain_root_account),
               hide_dashcard_color_overlays: @current_user.preferences[:hide_dashcard_color_overlays],
               custom_colors: @current_user.custom_colors
             },
             STUDENT_PLANNER_ENABLED: planner_enabled?,
             STUDENT_PLANNER_COURSES: planner_enabled? && map_courses_for_menu(@current_user.courses_with_primary_enrollment),
             STUDENT_PLANNER_GROUPS: planner_enabled? && map_groups_for_planner(@current_user.current_groups),
             ALLOW_ELEMENTARY_DASHBOARD: k5_disabled && k5_user,
             CREATE_COURSES_PERMISSIONS: {
               PERMISSION: course_permissions[:can_create],
               RESTRICT_TO_MCC_ACCOUNT: course_permissions[:restrict_to_mcc],
             },
             OBSERVED_USERS_LIST: observed_users_list,
             CAN_ADD_OBSERVEE: @current_user
                                 .profile
                                 .tabs_available(@current_user, root_account: @domain_root_account)
                                 .any? { |t| t[:id] == UserProfile::TAB_OBSERVEES }
           })

    # prefetch dashboard cards with the right observer url param
    if @current_user.roles(@domain_root_account).include?("observer")
      @cards_prefetch_observed_param = @selected_observed_user&.id
    end

    if k5_user?
      # things needed only for k5 dashboard
      # hide the grades tab if the user does not have active enrollments or if all enrolled courses have the tab hidden
      active_courses = Course.where(id: @current_user.enrollments.active_by_date.select(:course_id), homeroom_course: false)
      calendar_contexts = @current_user.get_preference(:selected_calendar_contexts)
      account_calendar_contexts = @current_user
                                  .enabled_account_calendars
                                  .select(&:enable_as_k5_account?)
                                  .map { |a| { asset_string: a.asset_string, name: a.name } }

      js_env({
               HIDE_K5_DASHBOARD_GRADES_TAB: active_courses.empty? || active_courses.all? { |c| c.tab_hidden?(Course::TAB_GRADES) },
               SELECTED_CONTEXT_CODES: calendar_contexts.is_a?(Array) ? calendar_contexts : [],
               SELECTED_CONTEXTS_LIMIT: @domain_root_account.settings[:calendar_contexts_limit] || 10,
               INITIAL_NUM_K5_CARDS: Rails.cache.read(["last_known_k5_cards_count", @current_user.global_id].cache_key) || 5,
               OPEN_TEACHER_TODOS_IN_NEW_TAB: @current_user.feature_enabled?(:open_todos_in_new_tab),
               ACCOUNT_CALENDAR_CONTEXTS: account_calendar_contexts
             })

      css_bundle :k5_common, :k5_dashboard, :dashboard_card
      css_bundle :k5_font unless use_classic_font?
      js_bundle :k5_dashboard
    else
      # things needed only for classic dashboard
      css_bundle :dashboard
      js_bundle :dashboard
    end

    @announcements = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
    @pending_invitations = @current_user.cached_invitations(include_enrollment_uuid: session[:enrollment_uuid], preload_course: true)

    if @current_user
      content_for_head helpers.auto_discovery_link_tag(:atom, feeds_user_format_path(@current_user.feed_code, :atom), { title: t("user_atom_feed", "User Atom Feed (All Courses)") })
    end

    add_body_class "dashboard-is-planner" if show_planner?
  end

  def dashboard_stream_items
    cancel_cache_buster

    @user = params[:observed_user_id].present? ? api_find(User, params[:observed_user_id]) : @current_user
    @is_observing_student = @current_user != @user
    course_ids = nil
    if @is_observing_student
      course_ids = @current_user.cached_course_ids_for_observed_user(@user)
      return render_unauthorized_action unless course_ids.any?
    end
    courses = course_ids.present? ? api_find_all(Course, course_ids) : nil
    @stream_items = @user.cached_recent_stream_items(contexts: courses)

    if stale?(etag: @stream_items)
      @stream_items = @stream_items.reject { |i| i&.course&.horizon_course? && !i.course.grants_right?(@user, :read_as_admin) }
      render partial: "shared/recent_activity", layout: false
    end
  end

  DASHBOARD_CARD_TABS = [
    Course::TAB_DISCUSSIONS,
    Course::TAB_ASSIGNMENTS,
    Course::TAB_ANNOUNCEMENTS,
    Course::TAB_FILES
  ].freeze

  def dashboard_cards
    opts = {}
    opts[:observee_user] = User.find_by(id: params[:observed_user_id].to_i) || @current_user if params.key?(:observed_user_id)
    dashboard_courses = map_courses_for_menu(@current_user.menu_courses(nil, opts), tabs: DASHBOARD_CARD_TABS)
    published, unpublished = dashboard_courses.partition { |course| course[:published] }
    Rails.cache.write(["last_known_dashboard_cards_published_count", @current_user.global_id].cache_key, published.count)
    Rails.cache.write(["last_known_dashboard_cards_unpublished_count", @current_user.global_id].cache_key, unpublished.count)
    Rails.cache.write(["last_known_k5_cards_count", @current_user.global_id].cache_key, dashboard_courses.count { |c| !c[:isHomeroom] })
    render json: dashboard_courses
  end

  def cached_upcoming_events(user)
    Rails.cache.fetch(["cached_user_upcoming_events", user].cache_key,
                      expires_in: 3.minutes) do
      user.upcoming_events context_codes: ([user.asset_string] + user.cached_context_codes)
    end
  end

  def cached_submissions(user, upcoming_events)
    Rails.cache.fetch(["cached_user_submissions2", user].cache_key,
                      expires_in: 3.minutes) do
      assignments = upcoming_events.select { |e| e.is_a?(Assignment) }
      Shard.partition_by_shard(assignments) do |shard_assignments|
        Submission.active
                  .select(%i[id assignment_id score grade workflow_state updated_at])
                  .where(assignment_id: shard_assignments, user_id: user)
      end
    end
  end

  def prepare_current_user_dashboard_items
    if @current_user
      @upcoming_events =
        cached_upcoming_events(@current_user)
      @current_user_submissions =
        cached_submissions(@current_user, @upcoming_events)
    else
      @upcoming_events = []
    end
  end

  def dashboard_sidebar
    GuardRail.activate(:secondary) do
      @user = params[:observed_user_id].present? ? api_find(User, params[:observed_user_id]) : @current_user
      @is_observing_student = @current_user != @user
      course_ids = nil

      if @is_observing_student
        course_ids = @current_user.cached_course_ids_for_observed_user(@user)
        return render_unauthorized_action unless course_ids.any?
      end

      if (!@user&.has_student_enrollment? || @user.non_student_enrollment?) && !@is_observing_student
        # it's not even using any of this for students/observers observing students - it's just using planner now
        prepare_current_user_dashboard_items
      end

      if (@show_recent_feedback = @user.student_enrollments.active.exists?)
        @recent_feedback = @user.recent_feedback(course_ids:) || []
      end
    end

    render formats: :html, layout: false
  end

  def toggle_hide_dashcard_color_overlays
    @current_user.preferences[:hide_dashcard_color_overlays] =
      !@current_user.preferences[:hide_dashcard_color_overlays]
    @current_user.save!
    render json: {}
  end

  def dashboard_view
    if request.get?
      render json: {
        dashboard_view: @current_user.dashboard_view(@context)
      }
    elsif request.put?
      valid_options = %w[activity cards planner]

      unless valid_options.include?(params[:dashboard_view])
        return render(json: { message: "Invalid Dashboard View Option" }, status: :bad_request)
      end

      @current_user&.dashboard_view = params[:dashboard_view]
      @current_user&.save!
      render json: {}
    end
  end

  include Api::V1::StreamItem

  # @API List the activity stream
  # Returns the current user's global activity stream, paginated.
  #
  # @argument only_active_courses [Boolean]
  #   If true, will only return objects for courses the user is actively participating in
  #
  # There are many types of objects that can be returned in the activity
  # stream. All object types have the same basic set of shared attributes:
  #   !!!javascript
  #   {
  #     'created_at': '2011-07-13T09:12:00Z',
  #     'updated_at': '2011-07-25T08:52:41Z',
  #     'id': 1234,
  #     'title': 'Stream Item Subject',
  #     'message': 'This is the body text of the activity stream item. It is plain-text, and can be multiple paragraphs.',
  #     'type': 'DiscussionTopic|Conversation|Message|Submission|Conference|Collaboration|AssessmentRequest...',
  #     'read_state': false,
  #     'context_type': 'course', // course|group
  #     'course_id': 1,
  #     'group_id': null,
  #     'html_url': "http://..." // URL to the Canvas web UI for this stream item
  #   }
  #
  # In addition, each item type has its own set of attributes available.
  #
  # DiscussionTopic:
  #
  #   !!!javascript
  #   {
  #     'type': 'DiscussionTopic',
  #     'discussion_topic_id': 1234,
  #     'total_root_discussion_entries': 5,
  #     'require_initial_post': true,
  #     'user_has_posted': true,
  #     'root_discussion_entries': {
  #       ...
  #     }
  #   }
  #
  # For DiscussionTopic, the message is truncated at 4kb.
  #
  # Announcement:
  #
  #   !!!javascript
  #   {
  #     'type': 'Announcement',
  #     'announcement_id': 1234,
  #     'total_root_discussion_entries': 5,
  #     'require_initial_post': true,
  #     'user_has_posted': null,
  #     'root_discussion_entries': {
  #       ...
  #     }
  #   }
  #
  # For Announcement, the message is truncated at 4kb.
  #
  # Conversation:
  #
  #   !!!javascript
  #   {
  #     'type': 'Conversation',
  #     'conversation_id': 1234,
  #     'private': false,
  #     'participant_count': 3,
  #   }
  #
  # Message:
  #
  #   !!!javascript
  #   {
  #     'type': 'Message',
  #     'message_id': 1234,
  #     'notification_category': 'Assignment Graded'
  #   }
  #
  # Submission:
  #
  # Returns an {api:Submissions:Submission Submission} with its Course and Assignment data.
  #
  # Conference:
  #
  #   !!!javascript
  #   {
  #     'type': 'Conference',
  #     'web_conference_id': 1234
  #   }
  #
  # Collaboration:
  #
  #   !!!javascript
  #   {
  #     'type': 'Collaboration',
  #     'collaboration_id': 1234
  #   }
  #
  # AssessmentRequest:
  #
  #   !!!javascript
  #   {
  #     'type': 'AssessmentRequest',
  #     'assessment_request_id': 1234
  #   }
  def activity_stream
    if @current_user
      # this endpoint has undocumented params (context_code, submission_user_id and asset_type) to
      # support submission comments in the conversations inbox.
      # please replace this with a more reasonable solution at your earliest convenience
      opts = { paginate_url: :api_v1_user_activity_stream_url }
      opts[:asset_type] = params[:asset_type] if params.key?(:asset_type)
      opts[:context] = Context.find_by_asset_string(params[:context_code]) if params[:context_code]
      opts[:submission_user_id] = params[:submission_user_id] if params.key?(:submission_user_id)
      opts[:only_active_courses] = value_to_boolean(params[:only_active_courses]) if params.key?(:only_active_courses)
      opts[:notification_categories] = params[:notification_categories] if params.key?(:notification_categories)
      api_render_stream(opts)
    else
      render_unauthorized_action
    end
  end

  # @API Activity stream summary
  # Returns a summary of the current user's global activity stream.
  # @argument only_active_courses [Boolean]
  #   If true, will only return objects for courses the user is actively participating in
  #
  # @example_response
  #   [
  #     {
  #       "type": "DiscussionTopic",
  #       "unread_count": 2,
  #       "count": 7
  #     },
  #     {
  #       "type": "Conversation",
  #       "unread_count": 0,
  #       "count": 3
  #     }
  #   ]
  def activity_stream_summary
    if @current_user
      opts = {}
      opts[:only_active_courses] = value_to_boolean(params[:only_active_courses]) if params.key?(:only_active_courses)
      api_render_stream_summary(opts)
    else
      render_unauthorize_action
    end
  end

  def manageable_courses
    get_context
    return unless authorized_action(@context, @current_user, :manage)

    # include concluded enrollments as well as active ones if requested
    include_concluded = params[:include].try(:include?, "concluded")
    limit = 100
    @query = params[:course].try(:[], :name) || params[:term]
    @courses = []
    Shard.with_each_shard(@context.in_region_associated_shards) do
      scope = if @query.present?
                @context.manageable_courses_by_query(@query, include_concluded)
              else
                @context.manageable_courses(include_concluded).limit(limit)
              end
      @courses += scope.select("courses.*,#{Course.best_unicode_collation_key("name")} AS sort_key").order("sort_key").preload(:enrollment_term).to_a
    end

    @courses = @courses.sort_by do |c|
      [
        c.enrollment_term.default_term? ? CanvasSort::First : CanvasSort::Last, # Default term first
        c.enrollment_term.start_at || CanvasSort::First, # Most recent start_at
        Canvas::ICU.collation_key(c.name) # Alphabetical
      ]
    end[0, limit]

    if params[:enforce_manage_grant_requirement]
      @courses.select! do |c|
        c.grants_any_right?(
          @current_user,
          *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
        )
      end
    else
      @courses.select! { |c| c.grants_all_rights?(@current_user, :read_as_admin, :read) }
    end

    current_course = Course.find_by(id: params[:current_course_id]) if params[:current_course_id].present?
    MasterCourses::MasterTemplate.preload_is_master_course(@courses)

    render json: @courses.map { |c|
      {
        label: c.nickname_for(@current_user),
        id: c.id,
        course_code: c.course_code,
        sis_id: c.sis_source_id,
        term: c.enrollment_term.name,
        enrollment_start: c.enrollment_term.start_at,
        account_name: c.enrollment_term.root_account.name,
        account_id: c.enrollment_term.root_account.id,
        start_at: datetime_string(c.start_at, :verbose, nil, true),
        end_at: datetime_string(c.conclude_at, :verbose, nil, true),
        blueprint: MasterCourses::MasterTemplate.is_master_course?(c)
      }.merge(locale_dates_for(c, current_course))
    }
  end

  include Api::V1::TodoItem
  # @API List the TODO items
  # A paginated list of the current user's list of todo items.
  #
  # @argument include[] [String, "ungraded_quizzes"]
  #   "ungraded_quizzes":: Optionally include ungraded quizzes (such as practice quizzes and surveys) in the list.
  #                        These will be returned under a +quiz+ key instead of an +assignment+ key in response elements.
  #
  # There is a limit to the number of items returned.
  #
  # The `ignore` and `ignore_permanently` URLs can be used to update the user's
  # preferences on what items will be displayed.
  # Performing a DELETE request against the `ignore` URL will hide that item
  # from future todo item requests, until the item changes.
  # Performing a DELETE request against the `ignore_permanently` URL will hide
  # that item forever.
  #
  # @example_response
  #   [
  #     {
  #       'type': 'grading',        // an assignment that needs grading
  #       'assignment': { .. assignment object .. },
  #       'ignore': '.. url ..',
  #       'ignore_permanently': '.. url ..',
  #       'html_url': '.. url ..',
  #       'needs_grading_count': 3, // number of submissions that need grading
  #       'context_type': 'course', // course|group
  #       'course_id': 1,
  #       'group_id': null,
  #     },
  #     {
  #       'type' => 'submitting',   // an assignment that needs submitting soon
  #       'assignment' => { .. assignment object .. },
  #       'ignore' => '.. url ..',
  #       'ignore_permanently' => '.. url ..',
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     },
  #     {
  #       'type' => 'submitting',   // a quiz that needs submitting soon
  #       'quiz' => { .. quiz object .. },
  #       'ignore' => '.. url ..',
  #       'ignore_permanently' => '.. url ..',
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     },
  #   ]
  def todo_items
    GuardRail.activate(:secondary) do
      return render_unauthorized_action unless @current_user

      bookmark = Plannable::Bookmarker.new(Assignment, false, [:due_at, :created_at], :id)
      grading_scope = @current_user.assignments_needing_grading(scope_only: true)
                                   .reorder(:due_at, :id).preload(:external_tool_tag, :rubric_association, :rubric, :discussion_topic, :quiz, :duplicate_of)
      submitting_scope = @current_user
                         .assignments_needing_submitting(
                           include_ungraded: true,
                           scope_only: true,
                           course_ids: @current_user.courses.pluck(:id),
                           include_concluded: false
                         )
                         .reorder(:due_at, :id).preload(:external_tool_tag, :rubric_association, :rubric, :discussion_topic, :quiz).eager_load(:duplicate_of)

      grading_collection = BookmarkedCollection.wrap(bookmark, grading_scope)
      grading_collection = BookmarkedCollection.filter(grading_collection) do |assignment|
        assignment.context.grants_right?(@current_user, session, :manage_grades)
      end
      grading_collection = BookmarkedCollection.transform(grading_collection) do |a|
        todo_item_json(a, @current_user, session, "grading")
      end
      submitting_collection = BookmarkedCollection.wrap(bookmark, submitting_scope)
      submitting_collection = BookmarkedCollection.transform(submitting_collection) do |a|
        todo_item_json(a, @current_user, session, "submitting")
      end
      collections = [
        ["grading", grading_collection],
        ["submitting", submitting_collection]
      ]

      if Array(params[:include]).include? "ungraded_quizzes"
        quizzes_bookmark = Plannable::Bookmarker.new(Quizzes::Quiz, false, [:due_at, :created_at], :id)
        quizzes_scope = @current_user
                        .ungraded_quizzes(
                          needing_submitting: true,
                          scope_only: true
                        )
                        .reorder(:due_at, :id)
        quizzes_collection = BookmarkedCollection.wrap(quizzes_bookmark, quizzes_scope)
        quizzes_collection = BookmarkedCollection.transform(quizzes_collection) do |a|
          todo_item_json(a, @current_user, session, "submitting")
        end

        collections << ["quizzes", quizzes_collection]
      end

      paginated_collection = BookmarkedCollection.merge(*collections)
      todos = Api.paginate(paginated_collection, self, api_v1_user_todo_list_items_url)
      render json: todos
    end
  end

  # @API List counts for todo items
  # Counts of different todo items such as the number of assignments needing grading as well as the number of assignments needing submitting.
  #
  # @argument include[] [String, "ungraded_quizzes"]
  #   "ungraded_quizzes":: Optionally include ungraded quizzes (such as practice quizzes and surveys) in the list.
  #                        These will be returned under a +quiz+ key instead of an +assignment+ key in response elements.
  #
  # There is a limit to the number of todo items this endpoint will count.
  # It will only look at the first 100 todo items for the user. If the user has more than 100 todo items this count may not be reliable.
  # The largest reliable number for both counts is 100.
  #
  # @example_response
  #   {
  #     needs_grading_count: 32,
  #     assignments_needing_submitting: 10
  #   }
  def todo_item_count
    GuardRail.activate(:secondary) do
      return render_unauthorized_action unless @current_user

      grading = @current_user.submissions_needing_grading_count
      submitting = @current_user.assignments_needing_submitting(include_ungraded: true, scope_only: true, limit: nil).size
      if Array(params[:include]).include? "ungraded_quizzes"
        submitting += @current_user.ungraded_quizzes(needing_submitting: true, scope_only: true, limit: nil).size
      end
      render json: { needs_grading_count: grading, assignments_needing_submitting: submitting }
    end
  end

  include Api::V1::Assignment
  include Api::V1::CalendarEvent

  # @API List upcoming assignments, calendar events
  # A paginated list of the current user's upcoming events.
  #
  # @example_response
  #   [
  #     {
  #       "id"=>597,
  #       "title"=>"Upcoming Course Event",
  #       "description"=>"Attendance is correlated with passing!",
  #       "start_at"=>"2013-04-27T14:33:14Z",
  #       "end_at"=>"2013-04-27T14:33:14Z",
  #       "location_name"=>"Red brick house",
  #       "location_address"=>"110 Top of the Hill Dr.",
  #       "all_day"=>false,
  #       "all_day_date"=>nil,
  #       "created_at"=>"2013-04-26T14:33:14Z",
  #       "updated_at"=>"2013-04-26T14:33:14Z",
  #       "workflow_state"=>"active",
  #       "context_code"=>"course_12938",
  #       "child_events_count"=>0,
  #       "child_events"=>[],
  #       "parent_event_id"=>nil,
  #       "hidden"=>false,
  #       "url"=>"http://www.example.com/api/v1/calendar_events/597",
  #       "html_url"=>"http://www.example.com/calendar?event_id=597&include_contexts=course_12938"
  #     },
  #     {
  #       "id"=>"assignment_9729",
  #       "title"=>"Upcoming Assignment",
  #       "description"=>nil,
  #       "start_at"=>"2013-04-28T14:47:32Z",
  #       "end_at"=>"2013-04-28T14:47:32Z",
  #       "all_day"=>false,
  #       "all_day_date"=>"2013-04-28",
  #       "created_at"=>"2013-04-26T14:47:32Z",
  #       "updated_at"=>"2013-04-26T14:47:32Z",
  #       "workflow_state"=>"published",
  #       "context_code"=>"course_12942",
  #       "assignment"=>{
  #         "id"=>9729,
  #         "name"=>"Upcoming Assignment",
  #         "description"=>nil,
  #         "points_possible"=>10,
  #         "due_at"=>"2013-04-28T14:47:32Z",
  #         "assignment_group_id"=>2439,
  #         "automatic_peer_reviews"=>false,
  #         "grade_group_students_individually"=>nil,
  #         "grading_standard_id"=>nil,
  #         "grading_type"=>"points",
  #         "group_category_id"=>nil,
  #         "lock_at"=>nil,
  #         "peer_reviews"=>false,
  #         "position"=>1,
  #         "unlock_at"=>nil,
  #         "course_id"=>12942,
  #         "submission_types"=>["none"],
  #         "needs_grading_count"=>0,
  #         "html_url"=>"http://www.example.com/courses/12942/assignments/9729"
  #       },
  #       "url"=>"http://www.example.com/api/v1/calendar_events/assignment_9729",
  #       "html_url"=>"http://www.example.com/courses/12942/assignments/9729"
  #     }
  #   ]
  def upcoming_events
    return render_unauthorized_action unless @current_user

    GuardRail.activate(:secondary) do
      prepare_current_user_dashboard_items

      events = @upcoming_events.map do |e|
        event_json(e, @current_user, session)
      end

      render json: events
    end
  end

  # @API List Missing Submissions
  # A paginated list of past-due assignments for which the student does not have a submission.
  # The user sending the request must either be the student, an admin or a parent observer using the parent app
  #
  # @argument user_id
  #   the student's ID
  #
  # @argument observed_user_id [String]
  #   Return missing submissions for the given observed user. Must be accompanied by course_ids[].
  #   The user making the request must be observing the observed user in all the courses specified by
  #   course_ids[].
  #
  # @argument include[] [String, "planner_overrides"|"course"]
  #   "planner_overrides":: Optionally include the assignment's associated planner override, if it exists, for the current user.
  #                         These will be returned under a +planner_override+ key
  #   "course":: Optionally include the assignments' courses
  #
  # @argument filter[] [String, "submittable"|"current_grading_period"]
  #   "submittable":: Only return assignments that the current user can submit (i.e. filter out locked assignments)
  #   "current_grading_period":: Only return missing assignments that are in the current grading period
  #
  # @argument course_ids[] [String]
  #   Optionally restricts the list of past-due assignments to only those associated with the specified
  #   course IDs. Required if observed_user_id is passed.
  #
  # @returns [Assignment]
  def missing_submissions
    GuardRail.activate(:secondary) do
      user = api_find(User, params[:user_id])
      return unless @current_user && authorized_action(user, @current_user, :read)

      included_course_ids = api_find_all(Course, Array(params[:course_ids])).pluck(:id)

      if params.key?(:observed_user_id)
        return render_unauthorized_action if included_course_ids.empty?

        user = api_find(User, params[:observed_user_id])
        valid_course_ids = @current_user.observer_enrollments.active.where(associated_user_id: params[:observed_user_id]).shard(@current_user).pluck(:course_id)
        return render_unauthorized_action unless (included_course_ids - valid_course_ids).empty?
      end

      filter = Array(params[:filter])
      only_submittable = filter.include?("submittable")
      only_current_grading_period = filter.include?("current_grading_period")

      course_ids = user.participating_student_course_ids
      # participating_student_course_ids returns ids relative to user, but included_course_ids are relative to the current shard
      course_ids.map! { |course_id| Shard.relative_id_for(course_id, user.shard, Shard.current) }
      course_ids = course_ids.select { |id| included_course_ids.include?(id) } unless included_course_ids.empty?

      submissions = Shard.partition_by_shard(course_ids) do |shard_course_ids|
        subs = Submission.active.preload(:assignment)
                         .missing
                         .where(user_id: user.id,
                                assignments: { context_id: shard_course_ids })
                         .where("late_policy_status IS NULL OR late_policy_status != ?", "none")
                         .merge(Assignment.published)
        subs = subs.merge(Assignment.not_locked) if only_submittable
        subs = subs.in_current_grading_period_for_courses(shard_course_ids) if only_current_grading_period
        subs.order(:cached_due_date, :id)
      end
      assignments = Api.paginate(submissions, self, api_v1_user_missing_submissions_url).map(&:assignment)

      includes = Array(params[:include])
      planner_overrides = includes.include?("planner_overrides")
      include_course = includes.include?("course")
      ActiveRecord::Associations.preload(assignments, :context) if include_course
      DatesOverridable.preload_override_data_for_objects(assignments)

      json = assignments.map do |as|
        assmt_json = assignment_json(as, user, session, include_planner_override: planner_overrides)
        assmt_json["course"] = course_json(as.context, user, session, [], nil) if include_course
        assmt_json
      end

      render json:
    end
  end

  def ignore_item
    unless %w[grading submitting reviewing moderation].include?(params[:purpose])
      return render(json: { ignored: false }, status: :bad_request)
    end

    @current_user.ignore_item!(ActiveRecord::Base.find_by_asset_string(params[:asset_string], ["Assignment", "AssessmentRequest", "Quizzes::Quiz", "SubAssignment"]),
                               params[:purpose],
                               params[:permanent] == "1")
    render json: { ignored: true }
  end

  # @API Hide a stream item
  # Hide the given stream item.
  #
  # @example_request
  #    curl https://<canvas>/api/v1/users/self/activity_stream/<stream_item_id> \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       "hidden": true
  #     }
  def ignore_stream_item
    @current_user.shard.activate do # can't just pass in the user's shard to relative_id_for, since local ids will be incorrectly scoped to the current shard, not the user's
      if (item = @current_user.stream_item_instances.where(stream_item_id: Shard.relative_id_for(params[:id], Shard.current, Shard.current)).first)
        item.update_attribute(:hidden, true) # observer handles cache invalidation
      end
    end
    render json: { hidden: true }
  end

  # @API Hide all stream items
  # Hide all stream items for the user
  #
  # @example_request
  #    curl https://<canvas>/api/v1/users/self/activity_stream \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       "hidden": true
  #     }
  def ignore_all_stream_items
    @current_user.shard.activate do # can't just pass in the user's shard to relative_id_for, since local ids will be incorrectly scoped to the current shard, not the user's
      @current_user.stream_item_instances.where(hidden: false).each do |item|
        item.update_attribute(:hidden, true) # observer handles cache invalidation
      end
    end
    render json: { hidden: true }
  end

  # @API Upload a file
  #
  # Upload a file to the user's personal files section.
  #
  # This API endpoint is the first step in uploading a file to a user's files.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Note that typically users will only be able to upload files to their
  # own files section. Passing a user_id of +self+ is an easy shortcut
  # to specify the current user.
  def create_file
    @user = api_find(User, params[:user_id])
    @attachment = @user.attachments.build
    if authorized_action(@attachment, @current_user, :create)
      @context = @user
      api_attachment_preflight(@current_user, request, check_quota: true)
    end
  end

  def close_notification
    @current_user.close_announcement(AccountNotification.find(params[:id]))
    render json: @current_user
  end

  def delete_user_service
    deleted = @current_user.user_services.find(params[:id]).destroy
    if deleted.service == "google_drive"
      Rails.cache.delete(["google_drive_tokens", @current_user].cache_key)
    end
    render json: { deleted: true }
  end

  ServiceCredentials = Struct.new(:service_user_name, :decrypted_password)

  def create_user_service
    user_name = params[:user_service][:user_name]
    password = params[:user_service][:password]
    service = ServiceCredentials.new(user_name, password)
    case params[:user_service][:service]
    when "diigo"
      Diigo::Connection.diigo_get_bookmarks(service)
    when "skype"
      true
    else
      return render json: { errors: true }, status: :bad_request
    end
    @service = UserService.register_from_params(@current_user, params[:user_service])
    render json: @service
  rescue => e
    Canvas::Errors.capture_exception(:user_service, e)
    render json: { errors: true }, status: :bad_request
  end

  def services
    params[:service_types] ||= params[:service_type]
    json = Rails.cache.fetch(["user_services", @current_user, params[:service_type]].cache_key) do
      @services = @current_user.user_services
      if params[:service_types]
        @services = @services.of_type(params[:service_types]&.split(","))
      end
      @services.map { |s| s.as_json(only: %i[service_user_id service_user_url service_user_name service type id]) }
    end
    render json:
  end

  def bookmark_search
    service = @current_user.user_services.where(type: "BookmarkService", service: params[:service_type]).first
    render json: service&.find_bookmarks
  end

  def show
    GuardRail.activate(:secondary) do
      # we _don't_ want to get context if the user is the context
      # so that for missing user context we can 401, but for others we can 404
      get_context(user_scope: User) if params[:account_id] || params[:course_id] || params[:group_id]

      @context_account = @context.is_a?(Account) ? @context : @domain_root_account
      scope = (value_to_boolean(params[:include_deleted_users]) && @context.is_a?(Account)) ? @context.pseudonym_users : (@context&.all_users || User)
      @user = api_find_all(scope, [params[:id]]).first
      return render_unauthorized_action unless @user&.grants_right?(@current_user, session, :read_full_profile)

      @context ||= @user

      add_crumb(t("crumbs.profile", "%{user}'s profile", user: @user.short_name), (@user == @current_user) ? user_profile_path(@current_user) : user_path(@user))

      @group_memberships = @user.cached_current_group_memberships_by_date

      # restrict group memberships view for other users
      if @user != @current_user
        @group_memberships = @group_memberships.select { |m| m.grants_right?(@current_user, session, :read) }
      end

      # course_section and enrollment term will only be used if the enrollment dates haven't been cached yet;
      # maybe should just look at the first enrollment and check if it's cached to decide if we should include
      # them here
      @enrollments = @user.enrollments
                          .shard(@user)
                          .where("enrollments.workflow_state<>'deleted' AND courses.workflow_state<>'deleted'")
                          .eager_load(:course)
                          .preload(:associated_user, :course_section, :enrollment_state, course: { enrollment_term: :enrollment_dates_overrides }).to_a

      # restrict course enrollments view for other users
      if @user != @current_user
        @enrollments = @enrollments.select { |e| e.grants_right?(@current_user, session, :read) }
      end

      @enrollments = @enrollments.sort_by { |e| [e.state_sortable, e.rank_sortable, e.course.name] }
      # pre-populate the reverse association
      @enrollments.each { |e| e.user = @user }

      @show_page_views = !!(page_views_enabled? && @user.grants_right?(@current_user, session, :view_statistics))

      status = @user.deleted? ? 404 : 200
      respond_to do |format|
        format.html do
          @body_classes << "full-width"

          js_permissions = {
            can_manage_sis_pseudonyms: @context_account.root_account.grants_right?(@current_user, :manage_sis),
            can_manage_user_details: @user.grants_right?(@current_user, :manage_user_details)
          }
          if @context_account.root_account.feature_enabled?(:temporary_enrollments)
            js_permissions[:can_read_sis] = @context_account.grants_right?(@current_user, session, :read_sis)
            js_permissions[:can_add_temporary_enrollments] = @context_account.grants_right?(@current_user, session, :temporary_enrollments_add)
            js_permissions[:can_edit_temporary_enrollments] = @context_account.grants_right?(@current_user, session, :temporary_enrollments_edit)
            js_permissions[:can_delete_temporary_enrollments] = @context_account.grants_right?(@current_user, session, :temporary_enrollments_delete)
            js_permissions[:can_view_temporary_enrollments] =
              @context_account.grants_any_right?(@current_user, session, *RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS)
            js_permissions[:can_allow_course_admin_actions] = @context_account.grants_right?(@current_user, session, :allow_course_admin_actions)
            js_permissions[:can_add_ta] = @context_account.grants_right?(@current_user, session, :add_ta_to_course)
            js_permissions[:can_add_student] = @context_account.grants_right?(@current_user, session, :add_student_to_course)
            js_permissions[:can_add_teacher] = @context_account.grants_right?(@current_user, session, :add_teacher_to_course)
            js_permissions[:can_add_designer] = @context_account.grants_right?(@current_user, session, :add_designer_to_course)
            js_permissions[:can_add_observer] = @context_account.grants_right?(@current_user, session, :add_observer_to_course)
          end

          timezones = I18nTimeZone.all.map { |tz| { name: tz.name, name_with_hour_offset: tz.to_s } }
          default_timezone_name = @domain_root_account.try(:default_time_zone)&.name || "Mountain Time (US & Canada)"

          js_env({
                   CONTEXT_USER_DISPLAY_NAME: @user.short_name,
                   USER_ID: @user.id,
                   COURSE_ROLES: Role.course_role_data_for_account(@context_account, @current_user),
                   PERMISSIONS: js_permissions,
                   ROOT_ACCOUNT_ID: @context_account.root_account.id,
                   TIMEZONES: timezones,
                   DEFAULT_TIMEZONE_NAME: default_timezone_name
                 })
          render status:
        end
        format.json do
          includes = %w[locale avatar_url]
          includes << "deleted_pseudonyms" if value_to_boolean(params[:include_deleted_users])
          render json: user_json(@user,
                                 @current_user,
                                 session,
                                 includes,
                                 @current_user.pseudonym.account),
                 status:
        end
      end
    end
  end

  # @API Show user details
  #
  # Shows details for user.
  #
  # Also includes an attribute "permissions", a non-comprehensive list of permissions for the user.
  # Example:
  #   !!!javascript
  #   "permissions": {
  #    "can_update_name": true, // Whether the user can update their name.
  #    "can_update_avatar": false, // Whether the user can update their avatar.
  #    "limit_parent_app_web_access": false // Whether the user can interact with Canvas web from the Canvas Parent app.
  #   }
  #
  # @argument include[] [String, "uuid", "last_login"]
  #   Array of additional information to include on the user record.
  #   "locale", "avatar_url", "permissions", "email", and "effective_locale"
  #   will always be returned
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/self \
  #       -X GET \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def api_show
    @user = api_find(User, params[:id])
    if @user.grants_right?(@current_user, session, :api_show_user)
      includes = api_show_includes
      # would've preferred to pass User.with_last_login as the collection to
      # api_find but the implementation of that scope appears to be incompatible
      # with what api_find does
      if includes.include?("last_login")
        pseudonyms =
          SisPseudonym.for(
            @user,
            @domain_root_account,
            type: :implicit,
            require_sis: false,
            include_all_pseudonyms: true
          )
        @user.last_login = pseudonyms&.filter_map(&:current_login_at)&.max
      end

      render json: user_json(@user, @current_user, session, includes, @domain_root_account),
             status: @user.deleted? ? 404 : 200
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def external_tool
    timing_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    placement = :user_navigation
    @tool = Lti::ToolFinder.from_id!(params[:id], @domain_root_account, placement:)
    @opaque_id = @tool.opaque_identifier_for(@current_user, context: @domain_root_account)
    @resource_type = "user_navigation"

    success_url = user_profile_url(@current_user)
    @return_url = named_context_url(@current_user, :context_external_content_success_url, "external_tool_redirect", { include_host: true })
    @redirect_return = true
    @context = @current_user
    js_env(redirect_return_success_url: success_url,
           redirect_return_cancel_url: success_url)

    @lti_launch = @tool.settings["post_only"] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    opts = {
      resource_type: @resource_type,
      link_code: @opaque_id,
      domain: HostUrl.context_host(@domain_root_account, request.host)
    }

    @tool_form_id = random_lti_tool_form_id
    js_env(LTI_TOOL_FORM_ID: @tool_form_id)

    variable_expander = Lti::VariableExpander.new(@domain_root_account, @context, self, {
                                                    current_user: @current_user,
                                                    current_pseudonym: @current_pseudonym,
                                                    tool: @tool,
                                                    placement:
                                                  })
    Canvas::LiveEvents.asset_access(@tool, "external_tools", @current_user.class.name, nil)
    adapter = if @tool.use_1_3?
                Lti::LtiAdvantageAdapter.new(
                  tool: @tool,
                  user: @current_user,
                  context: @domain_root_account,
                  return_url: @return_url,
                  expander: variable_expander,
                  include_storage_target: !in_lti_mobile_webview?,
                  opts:
                )
              else
                Lti::LtiOutboundAdapter.new(@tool, @current_user, @domain_root_account).prepare_tool_launch(@return_url, variable_expander, opts)
              end

    @lti_launch.params = adapter.generate_post_payload
    @lti_launch.resource_url = @tool.login_or_launch_url(extension_type: placement)
    @lti_launch.link_text = @tool.label_for(placement, I18n.locale)
    @lti_launch.analytics_id = @tool.tool_id
    Lti::LogService.new(tool: @tool, context: @domain_root_account, user: @current_user, session_id: session[:session_id], placement:, launch_type: :direct_link, launch_url: @lti_launch.resource_url).call

    set_active_tab @tool.asset_string
    add_crumb(@current_user.short_name, user_profile_path(@current_user))
    render Lti::AppUtil.display_template
    timing_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    InstStatsd::Statsd.timing("lti.user_external_tool.request_time", timing_end - timing_start, tags: { lti_version: @tool.lti_version })
  end

  def new
    return redirect_to(root_url) if @current_user

    if @domain_root_account.feature_enabled?(:login_registration_ui_identity)
      Rails.logger.debug "Redirecting to register_landing_path"
      return redirect_to(register_landing_path)
    end

    run_login_hooks
    @include_recaptcha = recaptcha_enabled?
    js_env ACCOUNT: account_json(@domain_root_account, nil, session, ["registration_settings"]),
           PASSWORD_POLICY: @domain_root_account.password_policy
    render layout: "bare"
  end

  include Api::V1::User
  include Api::V1::Avatar
  include Api::V1::Account

  # @API Create a user
  # Create and return a new user and pseudonym for an account.
  #
  # [DEPRECATED (for self-registration only)] If you don't have the "Modify
  # login details for users" permission, but self-registration is enabled
  # on the account, you can still use this endpoint to register new users.
  # Certain fields will be required, and others will be ignored (see below).
  #
  # @argument user[name] [String]
  #   The full name of the user. This name will be used by teacher for grading.
  #   Required if this is a self-registration.
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[terms_of_use] [Boolean]
  #   Whether the user accepts the terms of use. Required if this is a
  #   self-registration and this canvas instance requires users to accept
  #   the terms (on by default).
  #
  #   If this is true, it will mark the user as having accepted the terms of use.
  #
  # @argument user[skip_registration] [Boolean]
  #   Automatically mark the user as registered.
  #
  #   If this is true, it is recommended to set <tt>"pseudonym[send_confirmation]"</tt> to true as well.
  #   Otherwise, the user will not receive any messages about their account creation.
  #
  #   The users communication channel confirmation can be skipped by setting
  #   <tt>"communication_channel[skip_confirmation]"</tt> to true as well.
  #
  # @argument pseudonym[unique_id] [Required, String]
  #   User's login ID. If this is a self-registration, it must be a valid
  #   email address.
  #
  # @argument pseudonym[password] [String]
  #   User's password. Cannot be set during self-registration.
  #
  # @argument pseudonym[sis_user_id] [String]
  #   SIS ID for the user's account. To set this parameter, the caller must be
  #   able to manage SIS permissions.
  #
  # @argument pseudonym[integration_id] [String]
  #   Integration ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions. The Integration ID is a secondary
  #   identifier useful for more complex SIS integrations.
  #
  # @argument pseudonym[send_confirmation] [Boolean]
  #   Send user notification of account creation if true.
  #   Automatically set to true during self-registration.
  #
  # @argument pseudonym[force_self_registration] [Boolean]
  #   Send user a self-registration style email if true.
  #   Setting it means the users will get a notification asking them
  #   to "complete the registration process" by clicking it, setting
  #   a password, and letting them in.  Will only be executed on
  #   if the user does not need admin approval.
  #   Defaults to false unless explicitly provided.
  #
  # @argument pseudonym[authentication_provider_id] [String]
  #   The authentication provider this login is associated with. Logins
  #   associated with a specific provider can only be used with that provider.
  #   Legacy providers (LDAP, CAS, SAML) will search for logins associated with
  #   them, or unassociated logins. New providers will only search for logins
  #   explicitly associated with them. This can be the integer ID of the
  #   provider, or the type of the provider (in which case, it will find the
  #   first matching provider).
  #
  # @argument communication_channel[type] [String]
  #   The communication channel type, e.g. 'email' or 'sms'.
  #
  # @argument communication_channel[address] [String]
  #   The communication channel address, e.g. the user's email address.
  #
  # @argument communication_channel[confirmation_url] [Boolean]
  #   Only valid for account admins. If true, returns the new user account
  #   confirmation URL in the response.
  #
  # @argument communication_channel[skip_confirmation] [Boolean]
  #   Only valid for site admins and account admins making requests; If true, the channel is
  #   automatically validated and no confirmation email or SMS is sent.
  #   Otherwise, the user must respond to a confirmation message to confirm the
  #   channel.
  #
  #   If this is true, it is recommended to set <tt>"pseudonym[send_confirmation]"</tt> to true as well.
  #   Otherwise, the user will not receive any messages about their account creation.
  #
  # @argument force_validations [Boolean]
  #   If true, validations are performed on the newly created user (and their associated pseudonym)
  #   even if the request is made by a privileged user like an admin. When set to false,
  #   or not included in the request parameters, any newly created users are subject to
  #   validations unless the request is made by a user with a 'manage_user_logins' right.
  #   In which case, certain validations such as 'require_acceptance_of_terms' and
  #   'require_presence_of_name' are not enforced. Use this parameter to return helpful json
  #   errors while building users with an admin request.
  #
  # @argument enable_sis_reactivation [Boolean]
  #   When true, will first try to re-activate a deleted user with matching sis_user_id if possible.
  #   This is commonly done with user[skip_registration] and communication_channel[skip_confirmation]
  #   so that the default communication_channel is also restored.
  #
  # @argument destination [URL]
  #
  #   If you're setting the password for the newly created user, you can provide this param
  #   with a valid URL pointing into this Canvas installation, and the response will include
  #   a destination field that's a URL that you can redirect a browser to and have the newly
  #   created user automatically logged in. The URL is only valid for a short time, and must
  #   match the domain this request is directed to, and be for a well-formed path that Canvas
  #   can recognize.
  #
  # @argument initial_enrollment_type [String]
  #   `observer` if doing a self-registration with a pairing code. This allows setting the
  #   password during user creation.
  #
  # @argument pairing_code[code] [String]
  #   If provided and valid, will link the new user as an observer to the student's whose
  #   pairing code is given.
  #
  # @returns User
  def create
    create_user
  end

  # @API [DEPRECATED] Self register a user
  # Self register and return a new user and pseudonym for an account.
  #
  # If self-registration is enabled on the account, you can use this
  # endpoint to self register new users.
  #
  # @argument user[name] [Required, String]
  #   The full name of the user. This name will be used by teacher for grading.
  #
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[terms_of_use] [Required, Boolean]
  #   Whether the user accepts the terms of use.
  #
  # @argument pseudonym[unique_id] [Required, String]
  #   User's login ID. Must be a valid email address.
  #
  # @argument communication_channel[type] [String]
  #   The communication channel type, e.g. 'email' or 'sms'.
  #
  # @argument communication_channel[address] [String]
  #   The communication channel address, e.g. the user's email address.
  #
  # @returns User
  def create_self_registered_user
    create_user
  end

  BOOLEAN_PREFS = %i[manual_mark_as_read collapse_global_nav collapse_course_nav hide_dashcard_color_overlays release_notes_badge_disabled comment_library_suggestions_enabled elementary_dashboard_disabled default_to_block_editor].freeze

  # @API Update user settings.
  # Update an existing user's settings.
  #
  # @argument manual_mark_as_read [Boolean]
  #   If true, require user to manually mark discussion posts as read (don't
  #   auto-mark as read).
  #
  # @argument release_notes_badge_disabled [Boolean]
  #   If true, hide the badge for new release notes.
  #
  # @argument collapse_global_nav [Boolean]
  #   If true, the user's page loads with the global navigation collapsed
  #
  # @argument collapse_course_nav [Boolean]
  #   If true, the user's course pages will load with the course navigation
  #   collapsed.
  #
  # @argument hide_dashcard_color_overlays [Boolean]
  #   If true, images on course cards will be presented without being tinted
  #   to match the course color.
  #
  # @argument comment_library_suggestions_enabled [Boolean]
  #   If true, suggestions within the comment library will be shown.
  #
  # @argument elementary_dashboard_disabled [Boolean]
  #   If true, will display the user's preferred class Canvas dashboard
  #   view instead of the canvas for elementary view.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/settings \
  #     -X PUT \
  #     -F 'manual_mark_as_read=true'
  #     -H 'Authorization: Bearer <token>'
  def settings
    user = api_find(User, params[:id])

    case
    when request.get?
      return unless authorized_action(user, @current_user, :read)

      render json: BOOLEAN_PREFS.index_with { |pref| !!user.preferences[pref] }
    when request.put?
      return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

      BOOLEAN_PREFS.each do |pref|
        user.preferences[pref] = value_to_boolean(params[pref]) unless params[pref].nil?
      end

      respond_to do |format|
        format.json do
          if user.save
            render json: BOOLEAN_PREFS.index_with { |pref| !!user.preferences[pref] }
          else
            render(json: user.errors, status: :bad_request)
          end
        end
      end
    end
  end

  def get_new_user_tutorial_statuses
    user = api_find(User, params[:id])
    unless user == @current_user
      return render(json: { message: "This endpoint only works against the current user" }, status: :unauthorized)
    end
    return unless authorized_action(user, @current_user, :manage)

    render_new_user_tutorial_statuses(user)
  end

  def set_new_user_tutorial_status
    user = api_find(User, params[:id])
    unless user == @current_user
      return render(json: { message: "This endpoint only works against the current user" }, status: :unauthorized)
    end

    valid_names = %w[home
                     modules
                     pages
                     assignments
                     quizzes
                     settings
                     files
                     people
                     announcements
                     grades
                     discussions
                     syllabus
                     collaborations
                     import
                     conferences]

    # Check if the page_name is valid
    unless valid_names.include?(params[:page_name])
      return render(json: { message: "Invalid Page Name Provided" }, status: :bad_request)
    end

    statuses = user.new_user_tutorial_statuses
    statuses[params[:page_name]] = value_to_boolean(params[:collapsed])
    user.set_preference(:new_user_tutorial_statuses, statuses)

    respond_to do |format|
      format.json do
        if user.save
          render_new_user_tutorial_statuses(user)
        else
          render(json: user.errors, status: :bad_request)
        end
      end
    end
  end

  # @API Get custom colors
  # Returns all custom colors that have been saved for a user.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/ \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "custom_colors": {
  #       "course_42": "#abc123",
  #       "course_88": "#123abc"
  #     }
  #   }
  #
  def get_custom_colors
    user = api_find(User, params[:id])
    return unless authorized_action(user, @current_user, :read)

    render(json: { custom_colors: user.custom_colors })
  end

  # @API Get custom color
  # Returns the custom colors that have been saved for a user for a given context.
  #
  # The asset_string parameter should be in the format 'context_id', for example
  # 'course_42'.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/<asset_string> \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "hexcode": "#abc123"
  #   }
  def get_custom_color
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, :read)

    if user.custom_colors[params[:asset_string]].nil?
      raise(ActiveRecord::RecordNotFound, "Asset does not have an associated color.")
    end

    render(json: { hexcode: user.custom_colors[params[:asset_string]] })
  end

  # @API Update custom color
  # Updates a custom color for a user for a given context.  This allows
  # colors for the calendar and elsewhere to be customized on a user basis.
  #
  # The asset string parameter should be in the format 'context_id', for example
  # 'course_42'
  #
  # @argument hexcode [String]
  #   The hexcode of the color to set for the context, if you choose to pass the
  #   hexcode as a query parameter rather than in the request body you should
  #   NOT include the '#' unless you escape it first.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/<asset_string> \
  #     -X PUT \
  #     -F 'hexcode=fffeee'
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "hexcode": "#abc123"
  #   }
  def set_custom_color
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

    raise(ActiveRecord::RecordNotFound, "Asset does not exist") unless (context = Context.find_by_asset_string(params[:asset_string]))

    # Check if the hexcode is valid
    unless valid_hexcode?(params[:hexcode])
      return render(json: { message: "Invalid Hexcode Provided" }, status: :bad_request)
    end

    user.shard.activate do
      colors = user.custom_colors
      # translate asset string to be relative to user's shard
      unless params[:hexcode].nil?
        colors[context.asset_string] = normalize_hexcode(params[:hexcode])
      end

      respond_to do |format|
        format.json do
          if user.set_preference(:custom_colors, colors)
            enrollment_types_tags = user.participating_enrollments.pluck(:type).uniq.map { |type| "enrollment_type:#{type}" }
            InstStatsd::Statsd.distributed_increment("user.set_custom_color", tags: enrollment_types_tags)
            render(json: { hexcode: colors[context.asset_string] })
          else
            render(json: user.errors, status: :bad_request)
          end
        end
      end
    end
  end

  # @API Update text editor preference
  # Updates a user's default choice for text editor.  This allows
  # the Choose an Editor propmts to preload the user's preference.
  #
  #
  # @argument text_editor_preference  [String, "block_editor"|"rce"|""]
  #   The identifier for the editor.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/prefered_editor \
  #     -X PUT \
  #     -F 'text_editor_preference=rce'
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "text_editor_preference": "rce"
  #   }
  def set_text_editor_preference
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

    raise ActiveRecord::RecordInvalid if %w[rce block_editor].exclude?(params[:text_editor_preference]) && params[:text_editor_preference] != ""

    params[:text_editor_preference] = nil if params[:text_editor_preference] == ""

    if user.set_preference(:text_editor_preference, params[:text_editor_preference])
      render(json: { text_editor_preference: user.reload.get_preference(:text_editor_preference) })
    else
      render(json: user.errors, status: :bad_request)
    end
  end

  # @API Update files UI version preference
  # Updates a user's default choice for files UI version. This allows
  # the files UI to preload the user's preference.
  #
  # @argument files_ui_version [String, "v1"|"v2"]
  #   The identifier for the files UI version.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/files_ui_version_preference \
  #     -X PUT \
  #     -F 'files_ui_version=v2'
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "files_ui_version": "v2"
  #   }

  def set_files_ui_version_preference
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

    if %w[v1 v2].exclude?(params[:files_ui_version])
      return render(json: { message: "Invalid files_ui_version provided" }, status: :bad_request)
    end

    if user.set_preference(:files_ui_version, params[:files_ui_version])
      render(json: { files_ui_version: user.reload.get_preference(:files_ui_version) })
    else
      render(json: user.errors, status: :bad_request)
    end
  end

  # @API Get dashboard positions
  #
  # Returns all dashboard positions that have been saved for a user.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/dashboard_positions/ \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "dashboard_positions": {
  #       "course_42": 2,
  #       "course_88": 1
  #     }
  #   }
  #
  def get_dashboard_positions
    user = api_find(User, params[:id])
    return unless authorized_action(user, @current_user, :read)

    render(json: { dashboard_positions: user.dashboard_positions })
  end

  # @API Update dashboard positions
  #
  # Updates the dashboard positions for a user for a given context.  This allows
  # positions for the dashboard cards and elsewhere to be customized on a per
  # user basis.
  #
  # The asset string parameter should be in the format 'context_id', for example
  # 'course_42'
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/dashboard_positions/ \
  #     -X PUT \
  #     -F 'dashboard_positions[course_42]=1' \
  #     -F 'dashboard_positions[course_53]=2' \
  #     -F 'dashboard_positions[course_10]=3' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "dashboard_positions": {
  #       "course_10": 3,
  #       "course_42": 1,
  #       "course_53": 2
  #     }
  #   }
  def set_dashboard_positions
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

    params[:dashboard_positions].each do |key, val|
      context = Context.find_by_asset_string(key)
      if context.nil?
        raise(ActiveRecord::RecordNotFound, "Asset #{key} does not exist")
      end
      return unless authorized_action(context, @current_user, :read)

      begin
        position = Integer(val)
        if position.abs > 1_000
          # validate that the value used is less than unreasonable, but without any real effort
          return render(json: { message: "Position #{position} is too high. Your dashboard cards can probably be sorted with numbers 1-5, you could even use a 0." }, status: :bad_request)
        end
      rescue ArgumentError
        render(json: { message: "Invalid position provided" }, status: :bad_request)
      end
      return if performed?
    end

    user.set_dashboard_positions(user.dashboard_positions.merge(params[:dashboard_positions].to_unsafe_h))

    respond_to do |format|
      format.json do
        if user.save
          render(json: { dashboard_positions: user.dashboard_positions })
        else
          render(json: user.errors, status: :bad_request)
        end
      end
    end
  end

  include Pronouns

  # @API Edit a user
  # Modify an existing user. To modify a user's login, see the documentation for logins.
  #
  # @argument user[name] [String]
  #   The full name of the user. This name will be used by teacher for grading.
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[email] [String]
  #   The default email address of the user.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[avatar][token] [String]
  #   A unique representation of the avatar record to assign as the user's
  #   current avatar. This token can be obtained from the user avatars endpoint.
  #   This supersedes the user [avatar] [url] argument, and if both are included
  #   the url will be ignored. Note: this is an internal representation and is
  #   subject to change without notice. It should be consumed with this api
  #   endpoint and used in the user update endpoint, and should not be
  #   constructed by the client.
  #
  # @argument user[avatar][url] [String]
  #   To set the user's avatar to point to an external url, do not include a
  #   token and instead pass the url here. Warning: For maximum compatibility,
  #   please use 128 px square images.
  #
  # @argument user[avatar][state] [String, "none", "submitted", "approved", "locked", "reported", "re_reported"]
  #   To set the state of user's avatar. Only valid for account administrator.
  #
  # @argument user[title] [String]
  #   Sets a title on the user profile. (See {api:ProfileController#settings Get user profile}.)
  #   Profiles must be enabled on the root account.
  #
  # @argument user[bio] [String]
  #   Sets a bio on the user profile. (See {api:ProfileController#settings Get user profile}.)
  #   Profiles must be enabled on the root account.
  #
  # @argument user[pronunciation] [String]
  #   Sets name pronunciation on the user profile. (See {api:ProfileController#settings Get user profile}.)
  #   Profiles and name pronunciation must be enabled on the root account.
  #
  # @argument user[pronouns] [String]
  #   Sets pronouns on the user profile.
  #   Passing an empty string will empty the user's pronouns
  #   Only Available Pronouns set on the root account are allowed
  #   Adding and changing pronouns must be enabled on the root account.
  #
  # @argument user[event] [String, "suspend"|"unsuspend"]
  #   Suspends or unsuspends all logins for this user that the calling user
  #   has permission to
  #
  # @argument override_sis_stickiness [boolean]
  #   Default is true. If false, any fields containing “sticky” changes will not be updated.
  #   See SIS CSV Format documentation for information on which fields can have SIS stickiness
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/133' \
  #        -X PUT \
  #        -F 'user[name]=Sheldon Cooper' \
  #        -F 'user[short_name]=Shelly' \
  #        -F 'user[time_zone]=Pacific Time (US & Canada)' \
  #        -F 'user[avatar][token]=<opaque_token>' \
  #        -H "Authorization: Bearer <token>"
  #
  # @returns User
  def update
    params[:user] ||= {}
    user_params = params[:user]
    @user = if api_request?
              api_find(User, params[:id])
            else
              params[:id] ? api_find(User, params[:id]) : @current_user
            end

    update_email = @user.grants_right?(@current_user, :manage_user_details) && user_params[:email]
    managed_attributes = []
    managed_attributes.push(:name, :short_name, :sortable_name) if @user.grants_right?(@current_user, :rename)
    managed_attributes << :terms_of_use if @user == (@real_current_user || @current_user)
    managed_attributes << :email if update_email

    # we dropped birthdate from user but this will allow backwards compatability and prevent errors
    user_params.delete("birthdate")

    if @domain_root_account.enable_profiles?
      managed_attributes << :bio if @user.grants_right?(@current_user, :manage_user_details)
      managed_attributes << :title if @user.grants_right?(@current_user, :rename)
      managed_attributes << :pronunciation if @user.can_change_pronunciation?(@domain_root_account) && @user.grants_right?(@current_user, :manage_user_details)
    end

    can_admin_change_pronouns = @domain_root_account.can_add_pronouns? && @user.grants_right?(@current_user, :manage_user_details)
    if can_admin_change_pronouns || (@domain_root_account.can_change_pronouns? && @user.grants_right?(@current_user, :change_pronoun))
      managed_attributes << :pronouns
    end

    if @user.grants_right?(@current_user, :manage_user_details)
      managed_attributes.push(:event)
    end

    if @user.grants_right?(@current_user, :update_profile)
      managed_attributes.push(:time_zone, :locale)
    end

    if @user.grants_right?(@current_user, :update_avatar)
      avatar = user_params.delete(:avatar)

      # delete any avatar_image passed, because we only allow updating avatars
      # based on [:avatar][:token].
      user_params.delete(:avatar_image)

      managed_attributes << :avatar_image
      if (token = avatar.try(:[], :token))
        if (av_json = avatar_for_token(@user, token))
          user_params[:avatar_image] = { type: av_json["type"],
                                         url: av_json["url"] }
        end
      elsif (url = avatar.try(:[], :url))
        user_params[:avatar_image] = { url: }
      end

      if (state = avatar.try(:[], :state))
        user_params[:avatar_image] = { state: }
      end
    end

    if managed_attributes.empty? || !user_params.except(*managed_attributes).empty?
      return render_unauthorized_action
    end

    managed_attributes << { avatar_image: strong_anything } if managed_attributes.delete(:avatar_image)

    if params[:override_sis_stickiness] && !value_to_boolean(params[:override_sis_stickiness])
      managed_attributes -= [*@user.stuck_sis_fields]
    end

    user_params = user_params.permit(*managed_attributes)
    new_email = user_params.delete(:email)
    # admins can update avatar images even if they are locked
    admin_avatar_update = user_params[:avatar_image] &&
                          @user.grants_right?(@current_user, :update_avatar) &&
                          @user.grants_right?(@current_user, :manage_user_details)

    includes = %w[locale avatar_url email time_zone]
    includes << "avatar_state" if @user.grants_right?(@current_user, :manage_user_details)

    if (title = user_params.delete(:title))
      @user.profile.title = title
      includes << "title"
    end

    if (bio = user_params.delete(:bio))
      @user.profile.bio = bio
      includes << "bio"
    end

    if (pronunciation = user_params.delete(:pronunciation))
      @user.profile.pronunciation = pronunciation
      includes << "pronunciation"
    end

    if (pronouns = user_params.delete(:pronouns))
      updated_pronoun = match_pronoun(pronouns, @domain_root_account.pronouns)
      if updated_pronoun || pronouns&.empty?
        @user.pronouns = updated_pronoun
      end
      includes << "pronouns"
    end

    if admin_avatar_update
      old_avatar_state = @user.avatar_state
      @user.avatar_state = "submitted"
    end

    # For api requests we don't set session[:require_terms], but if the user needs terms
    # re-accepted and is trying to do it we should let them (used by the mobile app)
    if session[:require_terms] || (api_request? && user_params[:terms_of_use] && @domain_root_account.require_acceptance_of_terms?(@user))
      @user.require_acceptance_of_terms = true
    end

    @user.sortable_name_explicitly_set = user_params[:sortable_name].present?

    user_updated = User.transaction do
      if (event = user_params.delete(:event)) && %w[suspend unsuspend].include?(event) &&
         @user != @current_user
        @user.pseudonyms.active.shard(@user).each do |p|
          next unless p.grants_right?(@current_user, :delete)
          next if p.active? && event == "unsuspend"
          next if p.suspended? && event == "suspend"

          p.update!(workflow_state: (event == "suspend") ? "suspended" : "active")
        end
      end
      @user.update(user_params)
    end

    respond_to do |format|
      if user_updated
        if admin_avatar_update
          avatar_state = (old_avatar_state == :locked) ? old_avatar_state : "approved"
          @user.avatar_state = user_params[:avatar_image][:state] || avatar_state
        end
        @user.profile.save if @user.profile.changed?
        @user.save if admin_avatar_update || update_email
        # User.email= causes a reload to the user object. The saves need to
        # happen before the reload happens or we lose all the hard work from
        # above.
        @user.email = new_email if update_email
        session.delete(:require_terms)
        flash[:notice] = t("user_updated", "User was successfully updated.")
        unless params[:redirect_to_previous].blank?
          return redirect_back fallback_location: user_url(@user)
        end

        format.html { redirect_to user_url(@user) }
        format.json { render json: user_json(@user, @current_user, session, includes, @domain_root_account) }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :bad_request }
      end
    end
  end

  # @API Terminate all user sessions
  #
  # Terminates all sessions for a user. This includes all browser-based
  # sessions and all access tokens, including manually generated ones.
  # The user can immediately re-authenticate to access Canvas again if
  # they have the current credentials. All integrations will need to
  # be re-authorized.
  def terminate_sessions
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, :terminate_sessions)

    now = Time.zone.now
    user.update!(last_logged_out: now)
    user.access_tokens.active.update_all(updated_at: now, permanent_expires_at: now)

    render json: "ok"
  end

  # @API Log users out of all mobile apps
  #
  # Permanently expires any active mobile sessions, forcing them to re-authorize.
  #
  # The route that takes a user id will expire mobile sessions for that user.
  # The route that doesn't take a user id will expire mobile sessions for *all* users
  # in the institution.
  #
  def expire_mobile_sessions
    return unless authorized_action(@domain_root_account, @current_user, :manage_user_logins)

    user = api_find(User, params[:id]) if params.key?(:id)
    AccessToken.delay_if_production.invalidate_mobile_tokens!(@domain_root_account, user:)

    render json: "ok"
  end

  def media_download
    fetcher = MediaSourceFetcher.new(CanvasKaltura::ClientV3.new)
    extension = params[:type]
    media_type = params[:media_type]
    extension ||= params[:format] if media_type.nil?

    url = fetcher.fetch_preferred_source_url(
      media_id: params[:entryId],
      file_extension: extension,
      media_type:
    )
    if url
      if params[:redirect] == "1"
        redirect_to url
      else
        render json: { "url" => url }
      end
    else
      render status: :not_found, plain: t("could_not_find_url", "Could not find download URL")
    end
  end

  def admin_merge
    @user = User.find(params[:user_id])

    return unless authorized_action(@user, @current_user, :merge)

    title = t("Merge Users")

    @page_title = title
    @show_left_side = true
    @context = @domain_root_account

    add_crumb(@domain_root_account.name, account_url(@domain_root_account))
    add_crumb(title)

    page_has_instui_topnav

    account_options_for_merge_users = @current_user.associated_accounts.shard(Shard.current).to_a
    account_options_for_merge_users.push(@domain_root_account) if @domain_root_account && !account_options_for_merge_users.include?(@domain_root_account)
    account_options_for_merge_users = account_options_for_merge_users.sort_by(&:name).uniq.select { |a| a.grants_any_right?(@current_user, session, :manage_user_logins, :read_roster) }

    js_env({ ADMIN_MERGE_ACCOUNT_OPTIONS: account_options_for_merge_users.map { |a| { id: a.id, name: a.name } } })

    render html: '<div id="admin_merge_mount_point"></div>'.html_safe, layout: true
  end

  def user_for_merge
    @user = User.find(params[:user_id])

    return unless authorized_action(@user, @current_user, :merge)

    includes = %w[email]
    enrollments_for_display = @user.enrollments.current.map { |e| t("%{course_name} (%{enrollment_type})", course_name: e.course.name, enrollment_type: e.readable_type) }
    pseudonyms_for_display = @user.pseudonyms.active.map { |p| t("%{unique_id} (%{account_name})", unique_id: p.unique_id, account_name: p.account.name) }
    communication_channels_for_display = @user.communication_channels.unretired.email.map(&:path).uniq

    render json: {
      **user_json(@user, @current_user, session, includes, @domain_root_account),
      enrollments: enrollments_for_display,
      pseudonyms: pseudonyms_for_display,
      communication_channels: communication_channels_for_display
    }
  end

  def admin_split
    @user = User.find(params[:user_id])
    return unless authorized_action(@user, @current_user, :merge)

    merge_data = UserMergeData.active.splitable.where(user_id: @user).shard(@user).preload(:from_user).to_a
    js_env ADMIN_SPLIT_USER: user_display_json(@user),
           ADMIN_SPLIT_URL: api_v1_split_url(@user),
           ADMIN_SPLIT_USERS: merge_data.map { |md| user_display_json(md.from_user) }
  end

  def mark_avatar_image
    if params[:remove]
      if authorized_action(@user, @current_user, :remove_avatar)
        @user.avatar_image = {}
        @user.save
        render json: @user
      end
    else
      unless session[:"reported_#{@user.id}"]
        @user.report_avatar_image!
      end
      session[:"reports_#{@user.id}"] = true
      render json: { reported: true }
    end
  end

  def report_avatar_image
    @user = User.find(params[:user_id])
    key = "reported_#{@user.id}"
    unless session[key]
      session[key] = true
      @user.report_avatar_image!
    end
    render json: { ok: true }
  end

  def update_avatar_image
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :remove_avatar)
      @user.avatar_state = params[:avatar][:state]
      @user.save
      render json: @user.as_json(include_root: false)
    end
  end

  def public_feed
    return unless get_feed_context(only: [:user])

    title = "#{@context.name} Feed"
    link = dashboard_url
    id = user_url(@context)

    @entries = []
    cutoff = 1.week.ago
    @context.courses.each do |context|
      @entries.concat Assignments::ScopedToUser.new(context, @current_user, context.assignments.published.where("assignments.updated_at>?", cutoff)).scope
      @entries.concat context.calendar_events.active.where("updated_at>?", cutoff)
      @entries.concat(DiscussionTopic::ScopedToUser.new(context, @current_user, context.discussion_topics.published.where("discussion_topics.updated_at>?", cutoff)).scope.reject do |dt|
        dt.locked_for?(@current_user, check_policies: true)
      end)
      @entries.concat WikiPages::ScopedToUser.new(context, @current_user, context.wiki_pages.published.where("wiki_pages.updated_at>?", cutoff)).scope
    end

    respond_to do |format|
      format.atom { render plain: AtomFeedHelper.render_xml(title:, link:, id:, entries: @entries, include_context: true, context: @context) }
    end
  end

  def teacher_activity
    @teacher = User.find(params[:user_id])

    if @teacher == @current_user || authorized_action(@teacher, @current_user, :read_reports)
      @courses = {}

      if params[:student_id]
        student = User.find(params[:student_id])
        enrollments = student.student_enrollments.active.preload(:course).shard(student).to_a
        enrollments.each do |enrollment|
          should_include = enrollment.course.user_has_been_instructor?(@teacher) &&
                           enrollment.course.grants_all_rights?(@current_user, :read_reports, :view_all_grades) &&
                           enrollment.course.apply_enrollment_visibility(enrollment.course.all_student_enrollments, @teacher).where(id: enrollment).first
          if should_include
            @courses[enrollment.course] = teacher_activity_report(@teacher, enrollment.course, [enrollment])
          end
        end

        if @courses.all? { |_c, e| e.blank? }
          flash[:error] = t("errors.no_teacher_courses", "There are no courses shared between this teacher and student")
          redirect_to_referrer_or_default(root_url)
        end

      else # implied params[:course_id]
        course = Course.find(params[:course_id])
        if !course.user_has_been_instructor?(@teacher)
          flash[:error] = t("errors.user_not_teacher", "That user is not a teacher in this course")
          redirect_to_referrer_or_default(root_url)
        elsif authorized_action(course, @current_user, :read_reports) && authorized_action(course, @current_user, :view_all_grades)
          enrollments = course.apply_enrollment_visibility(course.all_student_enrollments, @teacher)
          @courses[course] = teacher_activity_report(@teacher, course, enrollments)
        end
      end
    end
  end

  def avatar_image
    cancel_cache_buster
    user_id = User.user_id_from_avatar_key(params[:user_id])

    return redirect_to(User.default_avatar_fallback) unless service_enabled?(:avatars) && user_id.present?

    account_avatar_setting = @domain_root_account.settings[:avatars] || "enabled"
    user_id = Shard.global_id_for(user_id)
    user_shard = Shard.shard_for(user_id)
    url = user_shard.activate do
      Rails.cache.fetch(Cacher.avatar_cache_key(user_id, account_avatar_setting)) do
        user = User.where(id: user_id).first
        if user
          user.avatar_url(nil, account_avatar_setting)
        else
          User.default_avatar_fallback
        end
      end
    end

    redirect_to User.avatar_fallback_url(url, request)
  end

  # @API Merge user into another user
  #
  # Merge a user into another user.
  # To merge users, the caller must have permissions to manage both users. This
  # should be considered irreversible. This will delete the user and move all
  # the data into the destination user.
  #
  # User merge details and caveats:
  # The from_user is the user that was deleted in the user_merge process.
  # The destination_user is the user that remains, that is being split.
  #
  # Avatars:
  # When both users have avatars, only the destination_users avatar will remain.
  # When one user has an avatar, it will end up on the destination_user.
  #
  # Terms of Use:
  # If either user has accepted terms of use, it will be be left as accepted.
  #
  # Communication Channels:
  # All unique communication channels moved to the destination_user.
  # All notification preferences are moved to the destination_user.
  #
  # Enrollments:
  # All unique enrollments are moved to the destination_user.
  # When there is an enrollment that would end up making it so that a user would
  # be observing themselves, the enrollment is not moved over.
  # Everything that is tied to the from_user at the course level relating to the
  # enrollment is also moved to the destination_user.
  #
  # Submissions:
  # All submissions are moved to the destination_user. If there are enrollments
  # for both users in the same course, we prefer submissions that have grades
  # then submissions that have work in them, and if there are no grades or no
  # work, they are not moved.
  #
  # Other notes:
  # Access Tokens are moved on merge.
  # Conversations are moved on merge.
  # Favorites are moved on merge.
  # Courses will commonly use LTI tools. LTI tools reference the user with IDs
  # that are stored on a user object. Merging users deletes one user and moves
  # all records from the deleted user to the destination_user. These IDs are
  # kept for all enrollments, group_membership, and account_users for the
  # from_user at the time of the merge. When the destination_user launches an
  # LTI tool from a course that used to be the from_user's, it doesn't appear as
  # a new user to the tool provider. Instead it will send the stored ids. The
  # destination_user's LTI IDs remain as they were for the courses that they
  # originally had. Future enrollments for the destination_user will use the IDs
  # that are on the destination_user object. LTI IDs that are kept and tracked
  # per context include lti_context_id, lti_id and uuid. APIs that return the
  # LTI ids will return the one for the context that it is called for, except
  # for the user uuid. The user UUID will display the destination_users uuid,
  # and when getting the uuid from an api that is in a context that was
  # recorded from a merge event, an additional attribute is added as past_uuid.
  #
  # When finding users by SIS ids in different accounts the
  # destination_account_id is required.
  #
  # The account can also be identified by passing the domain in destination_account_id.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/merge_into/<destination_user_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/merge_into/accounts/<destination_account_id>/users/<destination_user_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def merge_into
    user = api_find(User, params[:id])
    if authorized_action(user, @current_user, :merge)

      if (account_id = params[:destination_account_id])
        destination_account = Account.find_by_domain(account_id)
        destination_account ||= Account.find(account_id)
      else
        destination_account ||= @domain_root_account
      end

      into_user = api_find(User, params[:destination_user_id], account: destination_account)

      if authorized_action(into_user, @current_user, :merge)
        UserMerge.from(user).into into_user
        render(json: user_json(into_user,
                               @current_user,
                               session,
                               %w[locale],
                               destination_account))
      end
    end
  end

  # @API Split merged users into separate users
  #
  # Merged users cannot be fully restored to their previous state, but this will
  # attempt to split as much as possible to the previous state.
  # To split a merged user, the caller must have permissions to manage all of
  # the users logins. If there are multiple users that have been merged into one
  # user it will split each merge into a separate user.
  # A split can only happen within 180 days of a user merge. A user merge deletes
  # the previous user and may be permanently deleted. In this scenario we create
  # a new user object and proceed to move as much as possible to the new user.
  # The user object will not have preserved the name or settings from the
  # previous user. Some items may have been deleted during a user_merge that
  # cannot be restored, and/or the data has become stale because of other
  # changes to the objects since the time of the user_merge.
  #
  # Split users details and caveats:
  #
  # The from_user is the user that was deleted in the user_merge process.
  # The destination_user is the user that remains, that is being split.
  #
  # Avatars:
  # When both users had avatars, both will be remain.
  # When from_user had an avatar and destination_user did not have an avatar,
  # the destination_user's avatar will be deleted if it still matches what was
  # there are the time of the merge.
  # If the destination_user's avatar was changed at anytime after the merge, it
  # will remain on the destination user.
  # If the from_user had an avatar it will be there after split.
  #
  # Terms of Use:
  # If from_user had not accepted terms of use, they will be prompted again
  # to accept terms of use after the split.
  # If the destination_user had not accepted terms of use, hey will be prompted
  # again to accept terms of use after the split.
  # If neither user had accepted the terms of use, but since the time of the
  # merge had accepted, both will be prompted to accept terms of use.
  # If both had accepted terms of use, this will remain.
  #
  # Communication Channels:
  # All communication channels are restored to what they were prior to the
  # merge. If a communication channel was added after the merge, it will remain
  # on the destination_user.
  # Notification preferences remain with the communication channels.
  #
  # Enrollments:
  # All enrollments from the time of the merge will be moved back to where they
  # were. Enrollments created since the time of the merge that were created by
  # sis_import will go to the user that owns that sis_id used for the import.
  # Other new enrollments will remain on the destination_user.
  # Everything that is tied to the destination_user at the course level relating
  # to an enrollment is moved to the from_user. When both users are in the same
  # course prior to merge this can cause some unexpected items to move.
  #
  # Submissions:
  # Unlike other items tied to a course, submissions are explicitly recorded to
  # avoid problems with grades.
  # All submissions were moved are restored to the spot prior to merge.
  # All submission that were created in a course that was moved in enrollments
  # are moved over to the from_user.
  #
  # Other notes:
  # Access Tokens are moved back on split.
  # Conversations are moved back on split.
  # Favorites that existing at the time of merge are moved back on split.
  # LTI ids are restored to how they were prior to merge.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/split \
  #          -X POST \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def split
    user = api_find(User, params[:id])
    unless UserMergeData.active.splitable.where(user_id: user).shard(user).exists?
      return render json: { message: t("Nothing to split off of this user") }, status: :bad_request
    end

    if authorized_action(user, @current_user, :merge)
      users = SplitUsers.split_db_users(user)
      render json: users.sort_by(&:short_name).map { |u| user_json(u, @current_user, session) }
    end
  end

  # maybe I should document this
  # maybe not
  # basically does the same thing as UserList#users
  def invite_users
    # pass into "users" an array of hashes with "email"
    # e.g. [{"email": "email@example.com"}]
    # also can include an optional "name"

    # returns the original list in :invited_users (with ids) if successfully added, or in :errored_users if not
    get_context
    return unless authorized_action(@context, @current_user, %i[manage_students allow_course_admin_actions])

    root_account = context.root_account
    unless root_account.open_registration? || root_account.grants_right?(@current_user, session, :manage_user_logins)
      return render_unauthorized_action
    end

    invited_users = []
    errored_users = []
    Array(params[:users]).each do |user_hash|
      if user_hash[:email].blank?
        errored_users << user_hash.merge(error: "email required")
        next
      end

      email = user_hash[:email]
      user = User.new(name: user_hash[:name] || email)
      cc = user.communication_channels.build(path: email, path_type: "email")
      cc.user = user
      user.root_account_ids = [@context.root_account.id]
      user.workflow_state = "creation_pending"

      # check just in case
      user_scope =
        Pseudonym
        .active
        .where(account_id: @context.root_account)
        .joins(user: :communication_channels)
        .joins(:account)
        .where("communication_channels.path_type='email' AND LOWER(path) = ?", email.downcase)
      existing_rows =
        user_scope
        .where("communication_channels.workflow_state<>'retired'")
        .pluck("communication_channels.path", :user_id, "users.uuid", :account_id, "users.name", "accounts.name")

      if existing_rows.any?
        existing_users = existing_rows.map do |address, user_id, user_uuid, account_id, user_name, account_name|
          { address:, user_id:, user_token: User.token(user_id, user_uuid), user_name:, account_id:, account_name: }
        end
        unconfirmed_email = user_scope.where(communication_channels: { workflow_state: "unconfirmed" })
        errored_users <<
          if unconfirmed_email.exists?
            user_hash.merge(
              errors: [{ message: "The email address provided conflicts with an existing user's email that is awaiting verification. Please add the user by either SIS ID or Login ID." }],
              existing_users:
            )
          else
            user_hash.merge(
              errors: [{ message: "Matching user(s) already exist" }],
              existing_users:
            )
          end
      else
        # I didn't want a long running transaction for all the users so we get a single transaction
        # per user. This call to save creates causes the cc and user to changing triggering to
        # potential syncs, hence the transaction debouncing
        user_saved = User.transaction do
          user.save
        end
        if user_saved
          invited_users << user_hash.merge(id: user.id, user_token: user.token)
        else
          errored_users << user_hash.merge(user.errors.as_json)
        end
      end
    end
    render json: { invited_users:, errored_users: }
  end

  # @API Get a Pandata Events jwt token and its expiration date
  #
  # Returns a jwt auth and props token that can be used to send events to
  # Pandata.
  #
  # NOTE: This is currently only available to the mobile developer keys.
  #
  # @argument app_key [String]
  #   The pandata events appKey for this mobile app
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/pandata_events_token \
  #          -X POST \
  #          -H 'Authorization: Bearer <token>'
  #          -F 'app_key=MOBILE_APPS_KEY' \
  #
  # @example_response
  #   {
  #     "url": "https://example.com/pandata/events"
  #     "auth_token": "wek23klsdnsoieioeoi3of9deeo8r8eo8fdn",
  #     "props_token": "paowinefopwienpfiownepfiownepfownef",
  #     "expires_at": 1521667783000,
  #   }
  def pandata_events_token
    dk_ids = Setting.get("pandata_events_token_allowed_developer_key_ids", "").split(",")
    token_prefixes = Setting.get("pandata_events_token_prefixes", "ios,android").split(",")

    unless @access_token
      return render json: { message: "Access token required" }, status: :bad_request
    end

    unless dk_ids.include?(@access_token.global_developer_key_id.to_s)
      return render json: { message: "Developer key not authorized" }, status: :forbidden
    end

    service = PandataEvents::CredentialService.new(app_key: params[:app_key], valid_prefixes: token_prefixes)
    props_body = {
      user_id: @current_user.global_id,
      shard: @domain_root_account.shard.id,
      root_account_id: @domain_root_account.local_id,
      root_account_uuid: @domain_root_account.uuid
    }

    expires_at = 1.day.from_now
    render json: {
      url: PandataEvents.endpoint,
      auth_token: service.auth_token(@current_user.global_id, expires_at:, cache: false),
      props_token: service.token(props_body),
      expires_at: expires_at.to_f * 1000
    }
  rescue PandataEvents::Errors::InvalidAppKey
    render json: { message: "Invalid app key" }, status: :bad_request
  end

  # @API Get a users most recently graded submissions
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/graded_submissions \
  #          -X POST \
  #          -H 'Authorization: Bearer <token>'
  #
  # @argument include[] [String, "assignment"]
  #   Associations to include with the group
  # @argument only_current_enrollments [boolean]
  #   Returns submissions for only currently active enrollments
  # @argument only_published_assignments [boolean]
  #   Returns submissions for only published assignments
  #
  # @returns [Submission]
  #
  def user_graded_submissions
    @user = api_find(User, params[:id])
    if authorized_action(@user, @current_user, :read_grades)
      collections = []
      only_current_enrollments = value_to_boolean(params[:only_current_enrollments])
      only_published_assignments = value_to_boolean(params[:only_published_assignments])

      # Plannable Bookmarker enables descending order
      bookmarker = Plannable::Bookmarker.new(Submission, true, :graded_at, :id)
      Shard.with_each_shard(@user.associated_shards) do
        submissions = if only_current_enrollments
                        Submission.joins(assignment: { course: :student_enrollments }).merge(Enrollment.current.for_user(@user))
                      else
                        Submission.all
                      end
        if only_published_assignments
          submissions = submissions.joins(:assignment).merge(Assignment.published)
        end
        submissions = submissions.for_user(@user).graded
        collections << [Shard.current.id, BookmarkedCollection.wrap(bookmarker, submissions)]
      end

      scope = BookmarkedCollection.merge(*collections)
      submissions = Api.paginate(scope, self, api_v1_user_submissions_url)

      includes = params[:include] || []
      render(json: submissions.map { |s| submission_json(s, s.assignment, @current_user, session, nil, includes) })
    end
  end

  def clear_cache
    user = api_find(User, params[:id])
    if user && authorized_action(@domain_root_account, @current_user, :manage_site_settings)
      user.clear_caches
      render json: { status: "ok" }
    end
  end

  def destroy
    @user = api_find(User, params[:id])
    if @user && authorized_action(@domain_root_account, @current_user, :manage_site_settings)
      if @user.destroy
        render json: { deleted: true, status: "ok" }
      else
        render json: { deleted: false, status: :bad_request }
      end
    end
  end

  def show_k5_dashboard
    # reload @current_user to make sure we get a current value for their :elementary_dashboard_disabled preference
    @current_user.reload
    observed_users(@current_user, session) if @current_user.roles(@domain_root_account).include?("observer")
    render json: { show_k5_dashboard: k5_user?, use_classic_font: use_classic_font? }
  end

  protected

  def teacher_activity_report(teacher, course, student_enrollments)
    ids = student_enrollments.map(&:user_id)
    data = {}
    student_enrollments.each { |e| data[e.user.id] = { enrollment: e, ungraded: [] } }

    # find last interactions
    last_comment_dates = SubmissionCommentInteraction.in_course_between(course, teacher.id, ids)
    last_comment_dates.each do |(user_id, _author_id), date| # rubocop:disable Style/HashEachMethods
      next unless (student = data[user_id])

      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end
    scope = ConversationMessage
            .joins(:conversation_message_participants)
            .where("conversation_messages.author_id = ? AND conversation_message_participants.user_id IN (?) AND NOT conversation_messages.generated", teacher, ids)
    # fake_arel can't pass an array in the group by through the scope
    last_message_dates = scope.group(["conversation_message_participants.user_id", "conversation_messages.author_id"]).maximum(:created_at)
    last_message_dates.each do |key, date|
      next unless (student = data[key.first.to_i])

      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end

    # find all ungraded submissions in one query
    ungraded_submissions = course.submissions
                                 .where.not(assignments: { workflow_state: "deleted" })
                                 .eager_load(:assignment)
                                 .where("user_id IN (?) AND #{Submission.needs_grading_conditions}", ids)
                                 .except(:order)
                                 .order(:submitted_at).to_a

    ungraded_submissions.each do |submission|
      next unless (student = data[submission.user_id])

      student[:ungraded] << submission
    end

    Canvas::ICU.collate_by(data.values) { |e| e[:enrollment].user.sortable_name }
  end

  def require_self_registration
    get_context
    @context = @domain_root_account || Account.default unless @context.is_a?(Account)
    @context = @context.root_account
    unless @context.grants_right?(@current_user, session, :manage_user_logins) ||
           @context.self_registration_allowed_for?(params[:user] && params[:user][:initial_enrollment_type])
      flash[:error] = t("no_self_registration", "Self registration has not been enabled for this account")
      respond_to do |format|
        format.html { redirect_to root_url }
        format.json { render json: {}, status: :forbidden }
      end
      false
    end
  end

  private

  def google_drive_client
    settings = Canvas::Plugin.find(:google_drive).try(:settings) || {}
    client_secrets = {
      client_id: settings[:client_id],
      client_secret: settings[:client_secret_dec],
      redirect_uri: settings[:redirect_uri]
    }.with_indifferent_access
    GoogleDrive::Client.create(client_secrets)
  end

  def generate_grading_period_id(period_id)
    # nil and '' will get converted to 0 in the .to_i call
    id = period_id.to_i
    (id == 0) ? nil : id
  end

  def render_new_user_tutorial_statuses(user)
    render(json: { new_user_tutorial_statuses: { collapsed: user.new_user_tutorial_statuses } })
  end

  def authenticate_observee
    Pseudonym.authenticate(params[:observee] || {},
                           [@domain_root_account.id] + @domain_root_account.trusted_account_ids)
  end

  def grades_for_presenter(presenter, grading_periods)
    grades = {
      student_enrollments: {},
      observed_enrollments: {}
    }
    grouped_observed_enrollments = presenter.observed_enrollments.group_by(&:course_id)
    grouped_observed_enrollments.each do |course_id, enrollments|
      grading_period_id = generate_grading_period_id(
        grading_periods.dig(course_id, :selected_period_id)
      )
      grades[:observed_enrollments][course_id] = {}
      grades[:observed_enrollments][course_id] = grades_from_enrollments(
        enrollments,
        grading_period_id:
      )
    end

    presenter.student_enrollments.each do |course, enrollment|
      grading_period_id = generate_grading_period_id(
        grading_periods.dig(course.id, :selected_period_id)
      )
      opts = { grading_period_id: } if grading_period_id
      grades[:student_enrollments][course.id] = if course.grants_any_right?(@user, :manage_grades, :view_all_grades)
                                                  enrollment.computed_current_score(opts)
                                                else
                                                  enrollment.effective_current_score(opts)
                                                end
    end
    grades
  end

  def grades_from_enrollments(enrollments, grading_period_id: nil)
    grades = {}
    opts = { grading_period_id: } if grading_period_id
    enrollments.each do |enrollment|
      grades[enrollment.user_id] = if enrollment.course.grants_any_right?(@user, :manage_grades, :view_all_grades)
                                     enrollment.computed_current_score(opts)
                                   else
                                     enrollment.effective_current_score(opts)
                                   end
    end
    grades
  end

  def collected_grading_periods_for_presenter(presenter, course_id, grading_period_id)
    observer_courses = presenter.observed_enrollments.map(&:course)
    student_courses = presenter.student_enrollments.map(&:first)
    teacher_courses = presenter.teacher_enrollments.map(&:course)
    courses = observer_courses | student_courses | teacher_courses
    grading_periods = {}

    courses.each do |course|
      next unless course.grading_periods?

      course_periods = GradingPeriod.for(course)
      grading_period_specified = grading_period_id &&
                                 course_id && course_id.to_i == course.id

      selected_period_id = if grading_period_specified
                             grading_period_id.to_i
                           else
                             current_period = course_periods.find(&:current?)
                             current_period ? current_period.id : 0
                           end

      grading_periods[course.id] = {
        periods: course_periods,
        selected_period_id:
      }
    end
    grading_periods
  end

  def api_show_includes
    allowed_includes = ["uuid", "last_login"]
    allowed_includes << "avatar_state" if @user.grants_right?(@current_user, :manage_user_details)
    allowed_includes << "confirmation_url" if @domain_root_account.grants_right?(@current_user, :manage_user_logins)
    includes = %w[first_name last_name locale avatar_url permissions email effective_locale]
    includes += Array.wrap(params[:include]) & allowed_includes
    includes
  end

  def create_user
    run_login_hooks
    # Look for an incomplete registration with this pseudonym

    sis_user_id = nil
    integration_id = nil
    params[:pseudonym] ||= {}
    params[:pseudonym][:unique_id].strip! if params[:pseudonym][:unique_id].is_a?(String)

    if @context.grants_right?(@current_user, session, :manage_sis)
      sis_user_id = params[:pseudonym].delete(:sis_user_id)
      integration_id = params[:pseudonym].delete(:integration_id)
    end

    @pseudonym = nil
    @user = nil
    if sis_user_id && value_to_boolean(params[:enable_sis_reactivation])
      perform_sis_reactivation(sis_user_id)
    end

    if @pseudonym.nil?
      @pseudonym = @context.pseudonyms.active_only.by_unique_id(params[:pseudonym][:unique_id]).first
      # Setting it to nil will cause us to try and create a new one, and give user the login already exists error
      @pseudonym = nil if @pseudonym && !["creation_pending", "pending_approval"].include?(@pseudonym.user.workflow_state)
    end

    @user ||= @pseudonym&.user
    @user ||= @context.shard.activate { User.new }

    use_pairing_code = params[:user] && params[:user][:initial_enrollment_type] == "observer" && @domain_root_account.self_registration?
    force_validations = value_to_boolean(params[:force_validations])
    manage_user_logins = @context.grants_right?(@current_user, session, :manage_user_logins)
    self_enrollment = params[:self_enrollment].present?
    allow_non_email_pseudonyms = (!force_validations && manage_user_logins) || (self_enrollment && params[:pseudonym_type] == "username")
    require_password = self_enrollment && allow_non_email_pseudonyms
    allow_password = require_password || manage_user_logins || use_pairing_code

    notify_policy = Users::CreationNotifyPolicy.new(manage_user_logins, params[:pseudonym])

    includes = %w[locale uuid]

    cc_params = params[:communication_channel]

    if cc_params
      cc_type = cc_params[:type] || CommunicationChannel::TYPE_EMAIL
      cc_addr = cc_params[:address] || params[:pseudonym][:unique_id]

      cc_addr = nil if cc_type == CommunicationChannel::TYPE_EMAIL && !EmailAddressValidator.valid?(cc_addr)

      can_manage_students = [Account.site_admin, @context].any? do |role|
        role.grants_right?(@current_user, :manage_students)
      end

      if can_manage_students || use_pairing_code
        skip_confirmation = value_to_boolean(cc_params[:skip_confirmation])
      end

      if can_manage_students && cc_type == CommunicationChannel::TYPE_EMAIL && value_to_boolean(cc_params[:confirmation_url])
        includes << "confirmation_url"
      end

      if CommunicationChannel.trusted_confirmation_redirect?(@domain_root_account, cc_params[:confirmation_redirect])
        cc_confirmation_redirect = cc_params[:confirmation_redirect]
      end
    else
      cc_type = CommunicationChannel::TYPE_EMAIL
      cc_addr = params[:pseudonym].delete(:path) || params[:pseudonym][:unique_id]
      cc_addr = nil unless EmailAddressValidator.valid?(cc_addr)
    end

    if params[:user]
      user_params = params[:user]
                    .permit(:name,
                            :short_name,
                            :sortable_name,
                            :time_zone,
                            :show_user_services,
                            :avatar_image,
                            :subscribe_to_emails,
                            :locale,
                            :bio,
                            :terms_of_use,
                            :self_enrollment_code,
                            :initial_enrollment_type)
      if self_enrollment && user_params[:self_enrollment_code]
        user_params[:self_enrollment_code].strip!
      else
        user_params.delete(:self_enrollment_code)
      end

      @user.attributes = user_params
      accepted_terms = params[:user].delete(:terms_of_use)
      @user.accept_terms if value_to_boolean(accepted_terms)
      includes << "terms_of_use" unless accepted_terms.nil?
    end
    @user.name ||= params[:pseudonym][:unique_id]
    skip_registration = value_to_boolean(params[:user].try(:[], :skip_registration))
    unless @user.registered?
      @user.workflow_state = if require_password || skip_registration
                               # no email confirmation required (self_enrollment_code and password
                               # validations will ensure everything is legit)
                               "registered"
                             elsif notify_policy.is_self_registration? && @user.registration_approval_required?
                               "pending_approval"
                             else
                               "pre_registered"
                             end
      @user.root_account_ids = [@domain_root_account.id]
    end
    @recaptcha_errors = nil
    if force_validations || !manage_user_logins
      @user.require_acceptance_of_terms = @domain_root_account.terms_required?
      @user.require_presence_of_name = true
      @user.require_self_enrollment_code = self_enrollment
      @user.validation_root_account = @domain_root_account
      @recaptcha_errors = validate_recaptcha(params["g-recaptcha-response"])
    end

    @invalid_observee_creds = nil
    @invalid_observee_code = nil
    if @user.initial_enrollment_type == "observer"
      @pairing_code = find_observer_pairing_code(params[:pairing_code]&.[](:code))
      if @pairing_code.nil?
        @invalid_observee_code = ObserverPairingCode.new
        @invalid_observee_code.errors.add("code", "invalid")
      else
        @observee = @pairing_code.user
        # If the user is using a valid pairing code, we don't need recaptcha
        # Just clear out any errors it may have generated
        @recaptcha_errors = nil
      end
    end

    @pseudonym ||= @user.pseudonyms.build(account: @context)
    @pseudonym.account.email_pseudonyms = !allow_non_email_pseudonyms
    @pseudonym.require_password = require_password
    # pre-populate the reverse association
    @pseudonym.user = @user

    pseudonym_params = if params[:pseudonym]
                         params[:pseudonym].permit(:password, :password_confirmation, :unique_id)
                       else
                         {}
                       end
    # don't require password_confirmation on api calls
    pseudonym_params[:password_confirmation] = pseudonym_params[:password] if api_request?
    # don't allow password setting for new users that are not self-enrolling
    # in a course (they need to go the email route)
    unless allow_password
      pseudonym_params.delete(:password)
      pseudonym_params.delete(:password_confirmation)
    end
    password_provided = @pseudonym.new_record? && pseudonym_params.key?(:password)
    if password_provided && @user.workflow_state == "pre_registered"
      @user.workflow_state = "registered"
    end
    if params[:pseudonym][:authentication_provider_id]
      @pseudonym.authentication_provider = @context
                                           .authentication_providers.active
                                           .find(params[:pseudonym][:authentication_provider_id])
    end
    @pseudonym.attributes = pseudonym_params
    @pseudonym.sis_user_id = sis_user_id
    @pseudonym.integration_id = integration_id

    @pseudonym.account = @context
    @pseudonym.workflow_state = "active"
    if cc_addr.present?
      @cc =
        @user.communication_channels.where(path_type: cc_type).by_path(cc_addr).first ||
        @user.communication_channels.build(path_type: cc_type, path: cc_addr)
      @cc.user = @user
      @cc.workflow_state = skip_confirmation ? "active" : "unconfirmed" unless @cc.workflow_state == "confirmed"
      @cc.confirmation_redirect = cc_confirmation_redirect
    end

    save_user = @recaptcha_errors.nil? && @user.valid? && @pseudonym.valid? && (@invalid_observee_creds.nil? & @invalid_observee_code.nil?)

    message_sent = User.transaction do
      handle_instructure_identity(save_user)
      if save_user
        # saving the user takes care of the @pseudonym and @cc, so we can't call
        # save_without_session_maintenance directly. we don't want to auto-log-in
        # unless the user is registered/pre_registered (if the latter, he still
        # needs to confirm his email and set a password, otherwise he can't get
        # back in once his session expires)
        if @current_user
          @pseudonym.send(:skip_session_maintenance=, true)
        else # automagically logged in
          PseudonymSession.new(@pseudonym).save unless @pseudonym.new_record?
        end

        @user.save!

        if @observee && !@user.as_observer_observation_links.where(user_id: @observee, root_account: @context).exists?
          UserObservationLink.create_or_restore(student: @observee, observer: @user, root_account: @context)
          @pairing_code&.destroy
        end

        if notify_policy.is_self_registration?
          registration_params = params.fetch(:user, {}).merge(remote_ip: request.remote_ip, cookies:)
          @user.new_registration(registration_params)
        end
        notify_policy.dispatch!(@user, @pseudonym, @cc) if @cc && !skip_confirmation
      end
    end

    if save_user
      data = if api_request?
               user_json(@user, @current_user, session, includes)
             else
               { user: @user, pseudonym: @pseudonym, channel: @cc, message_sent:, course: @user.self_enrollment_course }
             end

      # if they passed a destination, and it matches the current canvas installation,
      # add a session_token to it for the newly created user and return it
      begin
        if params[:destination] && password_provided &&
           _routes.recognize_path(params[:destination]) &&
           (uri = URI.parse(params[:destination])) &&
           uri.host == request.host &&
           uri.port == request.port

          # add session_token to the query
          qs = URI.decode_www_form(uri.query || "")
          qs.delete_if { |(k, _v)| k == "session_token" }
          qs << ["session_token", SessionToken.new(@pseudonym.id)]
          uri.query = URI.encode_www_form(qs)

          data["destination"] = uri.to_s
        end
      rescue ActionController::RoutingError, URI::InvalidURIError
        # ignore
      end

      if !data.key?("destination") && (oauth = session[:oauth2])
        provider = Canvas::OAuth::Provider.new(oauth[:client_id], oauth[:redirect_uri], oauth[:scopes], oauth[:purpose])
        data["destination"] = Canvas::OAuth::Provider.confirmation_redirect(self, provider, @user).to_s
      end

      render(json: data)
    else
      errors = {
        errors: {
          user: @user.errors.as_json[:errors],
          pseudonym: @pseudonym ? @pseudonym.errors.as_json[:errors] : {},
          observee: @invalid_observee_creds ? @invalid_observee_creds.errors.as_json[:errors] : {},
          pairing_code: @invalid_observee_code ? @invalid_observee_code.errors.as_json[:errors] : {},
          recaptcha: @recaptcha_valid ? nil : @recaptcha_errors
        }
      }
      render json: errors, status: :bad_request
    end
  end

  def handle_instructure_identity(will_be_saving_user) end

  def perform_sis_reactivation(sis_user_id)
    @pseudonym = @context.pseudonyms.where(sis_user_id:, workflow_state: "deleted").first
    if @pseudonym
      @pseudonym.workflow_state = "active"
      @pseudonym.save!
      @user = @pseudonym.user
      @user.workflow_state = "registered"
      @user.update_account_associations
      if params[:user]&.dig(:skip_registration) && params[:communication_channel]&.dig(:skip_confirmation)
        cc = CommunicationChannel.where(user_id: @user.id, path_type: :email).order(updated_at: :desc).first
        if cc
          cc.pseudonym = @pseudonym
          cc.workflow_state = "active"
          cc.save!
        end
      end
    end
  end

  def find_observer_pairing_code(pairing_code)
    ObserverPairingCode.active.where(code: pairing_code).first
  end

  def validate_recaptcha(recaptcha_response)
    # if there is no recaptcha key or recaptcha is disabled, don't do anything
    return nil unless recaptcha_enabled?
    # Authenticated API requests do not require a captcha
    return nil unless @access_token.nil?

    response = CanvasHttp.post("https://www.google.com/recaptcha/api/siteverify", form_data: {
                                 secret: DynamicSettings.find(tree: :private)["recaptcha_server_key"],
                                 response: recaptcha_response
                               })

    if response && response.code == "200"
      parsed = JSON.parse(response.body)
      return { errors: parsed["error-codes"] } unless parsed["success"]
      return { errors: ["invalid-hostname"] } unless parsed["hostname"] == request.host

      nil
    else
      raise "Error connecting to recaptcha #{response}"
    end
  end

  def locale_dates_for(course, current_course)
    return { start_at_locale: nil, end_at_locale: nil } unless current_course&.locale.present?

    I18n.with_locale(current_course.locale) do
      {
        start_at_locale: datetime_string(course.start_at, :verbose, nil, true),
        end_at_locale: datetime_string(course.conclude_at, :verbose, nil, true)
      }
    end
  end
end
