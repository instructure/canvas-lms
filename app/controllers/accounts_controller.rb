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

require 'csv'

# @API Accounts
#
# API for accessing account data.
#
# @model Account
#     {
#       "id": "Account",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the Account object",
#           "example": 2,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The display name of the account",
#           "example": "Canvas Account",
#           "type": "string"
#         },
#         "uuid": {
#           "description": "The UUID of the account",
#           "example": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SqHUPb7jZY5",
#           "type": "string"
#         },
#         "parent_account_id": {
#           "description": "The account's parent ID, or null if this is the root account",
#           "example": 1,
#           "type": "integer"
#         },
#         "root_account_id": {
#           "description": "The ID of the root account, or null if this is the root account",
#           "example": 1,
#           "type": "integer"
#         },
#         "default_storage_quota_mb": {
#           "description": "The storage quota for the account in megabytes, if not otherwise specified",
#           "example": 500,
#           "type": "integer"
#         },
#         "default_user_storage_quota_mb": {
#           "description": "The storage quota for a user in the account in megabytes, if not otherwise specified",
#           "example": 50,
#           "type": "integer"
#         },
#         "default_group_storage_quota_mb": {
#           "description": "The storage quota for a group in the account in megabytes, if not otherwise specified",
#           "example": 50,
#           "type": "integer"
#         },
#         "default_time_zone": {
#           "description": "The default time zone of the account. Allowed time zones are {http://www.iana.org/time-zones IANA time zones} or friendlier {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.",
#           "example": "America/Denver",
#           "type": "string"
#         },
#         "sis_account_id": {
#           "description": "The account's identifier in the Student Information System. Only included if the user has permission to view SIS information.",
#           "example": "123xyz",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "The account's identifier in the Student Information System. Only included if the user has permission to view SIS information.",
#           "example": "123xyz",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "The id of the SIS import if created through SIS. Only included if the user has permission to manage SIS information.",
#           "example": "12",
#           "type": "integer"
#         },
#         "lti_guid": {
#           "description": "The account's identifier that is sent as context_id in LTI launches.",
#           "example": "123xyz",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "The state of the account. Can be 'active' or 'deleted'.",
#           "example": "active",
#           "type": "string"
#         }
#       }
#     }
#
# @model TermsOfService
#     {
#       "id": "TermsOfService",
#       "description": "",
#       "properties":
#       {
#         "id": {
#           "description": "Terms Of Service id",
#           "example": 1,
#           "type": "integer"
#         },
#         "terms_type": {
#           "description": "The given type for the Terms of Service",
#           "enum":
#           [
#             "default",
#             "custom",
#             "no_terms"
#           ],
#           "example": "default",
#           "type": "string"
#         },
#         "passive": {
#           "description": "Boolean dictating if the user must accept Terms of Service",
#           "example": false,
#           "type": "boolean"
#         },
#         "account_id": {
#           "description": "The id of the root account that owns the Terms of Service",
#           "example": 1,
#           "type": "integer"
#         },
#         "content": {
#           "description": "Content of the Terms of Service",
#           "example": "To be or not to be that is the question",
#           "type": "string"
#         }
#       }
#     }
#
# @model HelpLink
#     {
#       "id": "HelpLink",
#       "description": "",
#       "properties":
#       {
#         "id": {
#           "description": "The ID of the help link",
#           "example": "instructor_question",
#           "type": "string"
#         },
#         "text": {
#           "description": "The name of the help link",
#           "example": "Ask Your Instructor a Question",
#           "type": "string"
#         },
#         "subtext": {
#           "description": "The description of the help link",
#           "example": "Questions are submitted to your instructor",
#           "type": "string"
#         },
#         "url": {
#           "description": "The URL of the help link",
#           "example": "#teacher_feedback",
#           "type": "string"
#         },
#         "type": {
#           "description": "The type of the help link",
#           "enum":
#           [
#             "default",
#             "custom"
#           ],
#           "example": "default",
#           "type": "string"
#         },
#         "available_to": {
#           "description": "The roles that have access to this help link",
#           "example": ["user", "student", "teacher", "admin", "observer", "unenrolled"],
#           "type": "array",
#           "items": { "type": "string" }
#         }
#       }
#     }
#
# @model HelpLinks
#     {
#       "id": "HelpLinks",
#       "description": "",
#       "properties":
#       {
#         "help_link_name": {
#           "description": "Help link button title",
#           "example": "Help And Policies",
#           "type": "string"
#         },
#         "help_link_icon": {
#           "description": "Help link button icon",
#           "example": "help",
#           "type": "string"
#         },
#         "custom_help_links": {
#           "description": "Help links defined by the account. Could include default help links.",
#           "type": "array",
#           "items": { "$ref": "HelpLink" },
#           "example": [
#             {
#               "id": "link1",
#               "text": "Custom Link!",
#               "subtext": "Something something.",
#               "url": "https://google.com",
#               "type": "custom",
#               "available_to": [
#                 "user",
#                 "student",
#                 "teacher",
#                 "admin",
#                 "observer",
#                 "unenrolled"
#               ]
#             }
#           ]
#         },
#         "default_help_links": {
#           "description": "Default help links provided when account has not set help links of their own.",
#           "type": "array",
#           "items": { "$ref": "HelpLink" },
#           "example": [
#             {
#               "available_to": [
#                 "student"
#               ],
#               "text": "Ask Your Instructor a Question",
#               "subtext": "Questions are submitted to your instructor",
#               "url": "#teacher_feedback",
#               "type": "default",
#               "id": "instructor_question"
#             },
#             {
#               "available_to": [
#                 "user",
#                 "student",
#                 "teacher",
#                 "admin",
#                 "observer",
#                 "unenrolled"
#               ],
#               "text": "Search the Canvas Guides",
#               "subtext": "Find answers to common questions",
#               "url": "http://community.canvaslms.com/community/answers/guides",
#               "type": "default",
#               "id": "search_the_canvas_guides"
#             },
#             {
#               "available_to": [
#                 "user",
#                 "student",
#                 "teacher",
#                 "admin",
#                 "observer",
#                 "unenrolled"
#               ],
#               "text": "Report a Problem",
#               "subtext": "If Canvas misbehaves, tell us about it",
#               "url": "#create_ticket",
#               "type": "default",
#               "id": "report_a_problem"
#             }
#           ]
#         }
#       }
#     }

class AccountsController < ApplicationController
  before_action :require_user, :only => [:index, :terms_of_service, :help_links]
  before_action :reject_student_view_student
  before_action :get_context
  before_action :rce_js_env, only: [:settings]

  include Api::V1::Account
  include CustomSidebarLinksHelper

  INTEGER_REGEX = /\A[+-]?\d+\z/
  SIS_ASSINGMENT_NAME_LENGTH_DEFAULT = 255

  # @API List accounts
  # A paginated list of accounts that the current user can view or manage.
  # Typically, students and even teachers will get an empty list in response,
  # only account admins can view the accounts that they are in.
  #
  # @argument include[] [String, "lti_guid"|"registration_settings"|"services"]
  #   Array of additional information to include.
  #
  #   "lti_guid":: the 'tool_consumer_instance_guid' that will be sent for this account on LTI launches
  #   "registration_settings":: returns info about the privacy policy and terms of use
  #   "services":: returns services and whether they are enabled (requires account management permissions)
  #
  # @returns [Account]
  def index
    respond_to do |format|
      format.html do
        @accounts = @current_user ? @current_user.adminable_accounts : []
      end
      format.json do
        if @current_user
          @accounts = Api.paginate(@current_user.all_paginatable_accounts, self, api_v1_accounts_url)
        else
          @accounts = []
        end
        ActiveRecord::Associations::Preloader.new.preload(@accounts, :root_account)

        # originally had 'includes' instead of 'include' like other endpoints
        includes = params[:include] || params[:includes]
        render :json => @accounts.map { |a| account_json(a, @current_user, session, includes || [], false) }
      end
    end
  end

  # @API List accounts for course admins
  # A paginated list of accounts that the current user can view through their
  # admin course enrollments. (Teacher, TA, or designer enrollments).
  # Only returns "id", "name", "workflow_state", "root_account_id" and "parent_account_id"
  #
  # @returns [Account]
  def course_accounts
    if @current_user
      account_ids = Rails.cache.fetch(['admin_enrollment_course_account_ids', @current_user].cache_key) do
        Account.joins(:courses => :enrollments).merge(
          @current_user.enrollments.admin.shard(@current_user).except(:select, :joins)
        ).select("accounts.id").distinct.pluck(:id).map{|id| Shard.global_id_for(id)}
      end
      course_accounts = BookmarkedCollection.wrap(Account::Bookmarker, Account.where(:id => account_ids))
      @accounts = Api.paginate(course_accounts, self, api_v1_course_accounts_url)
    else
      @accounts = []
    end
    ActiveRecord::Associations::Preloader.new.preload(@accounts, :root_account)
    render :json => @accounts.map { |a| account_json(a, @current_user, session, params[:includes] || [], true) }
  end

  # @API Get a single account
  # Retrieve information on an individual account, given by id or sis
  # sis_account_id.
  #
  # @returns Account
  def show
    return unless authorized_action(@account, @current_user, :read)
    respond_to do |format|
      format.html do
        if @account.feature_enabled?(:course_user_search)
          @redirect_on_unauth = true
          return course_user_search
        end
        if value_to_boolean(params[:theme_applied])
          flash[:notice] = t("Your custom theme has been successfully applied.")
        end
        return redirect_to account_settings_url(@account) if @account.site_admin? || !@account.grants_right?(@current_user, :read_course_list)
        js_env(:ACCOUNT_COURSES_PATH => account_courses_path(@account, :format => :json))
        include_crosslisted_courses = value_to_boolean(params[:include_crosslisted_courses])
        load_course_right_side(:include_crosslisted_courses => include_crosslisted_courses)
        @courses = @account.fast_all_courses(:term => @term, :limit => @maximum_courses_im_gonna_show,
          :hide_enrollmentless_courses => @hide_enrollmentless_courses,
          :only_master_courses => @only_master_courses,
          :order => sort_order,
          :include_crosslisted_courses => include_crosslisted_courses)
        ActiveRecord::Associations::Preloader.new.preload(@courses, :enrollment_term)
        build_course_stats
      end
      format.json { render :json => account_json(@account, @current_user, session, params[:includes] || [],
                                                 !@account.grants_right?(@current_user, session, :manage)) }
    end
  end

  # @API Permissions
  # Returns permission information for the calling user and the given account.
  # You may use `self` as the account id to check permissions against the domain root account.
  # The caller must have an account role or admin (teacher/TA/designer) enrollment in a course
  # in the account.
  #
  # See also the {api:CoursesController#permissions Course} and {api:GroupsController#permissions Group}
  # counterparts.
  #
  # @argument permissions[] [String]
  #   List of permissions to check against the authenticated user.
  #   Permission names are documented in the {api:RoleOverridesController#add_role Create a role} endpoint.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/self/permissions \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'permissions[]=manage_account_memberships' \
  #       -d 'permissions[]=become_user'
  #
  # @example_response
  #   {'manage_account_memberships': 'false', 'become_user': 'true'}
  def permissions
    return unless authorized_action(@account, @current_user, :read)
    permissions = Array(params[:permissions]).map(&:to_sym)
    render json: @account.rights_status(@current_user, session, *permissions)
  end

  # @API Get the sub-accounts of an account
  #
  # List accounts that are sub-accounts of the given account.
  #
  # @argument recursive [Boolean] If true, the entire account tree underneath
  #   this account will be returned (though still paginated). If false, only
  #   direct sub-accounts of this account will be returned. Defaults to false.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/<account_id>/sub_accounts \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Account]
  def sub_accounts
    return unless authorized_action(@account, @current_user, :read)
    recursive = value_to_boolean(params[:recursive])
    if recursive
      @accounts = PaginatedCollection.build do |pager|
        per_page = pager.per_page
        current_page = [pager.current_page.to_i, 1].max
        sub_accounts = @account.sub_accounts_recursive(per_page + 1, (current_page - 1) * per_page)

        if sub_accounts.length > per_page
          sub_accounts.pop
          pager.next_page = current_page + 1
        end

        pager.replace sub_accounts
      end
    else
      @accounts = @account.sub_accounts.order(:id)
    end

    @accounts = Api.paginate(@accounts, self, api_v1_sub_accounts_url,
                             :total_entries => recursive ? nil : @accounts.count)

    ActiveRecord::Associations::Preloader.new.preload(@accounts, [:root_account, :parent_account])
    render :json => @accounts.map { |a| account_json(a, @current_user, session, []) }
  end

  # @API Get the Terms of Service
  #
  # Returns the terms of service for that account
  #
  # @returns TermsOfService
  def terms_of_service
    keys = %w(id terms_type passive account_id)
    tos = @account.root_account.terms_of_service
    res = tos.attributes.slice(*keys)
    res['content'] = tos.terms_of_service_content&.content
    render :json => res
  end

  # @API Get help links
  #
  # Returns the help links for that account
  #
  # @returns HelpLinks
  def help_links
    render :json => {} unless @account == @domain_root_account
    help_links = edit_help_links_env
    links = {
      help_link_name: help_links[:help_link_name],
      help_link_icon: help_links[:help_link_icon],
      custom_help_links: help_links[:CUSTOM_HELP_LINKS],
      default_help_links: help_links[:DEFAULT_HELP_LINKS],
    }
    render :json => links
  end

  include Api::V1::Course

  # @API List active courses in an account
  # Retrieve a paginated list of courses in this account.
  #
  # @argument with_enrollments [Boolean]
  #   If true, include only courses with at least one enrollment.  If false,
  #   include only courses with no enrollments.  If not present, do not filter
  #   on course enrollment status.
  #
  # @argument enrollment_type[] [String, "teacher"|"student"|"ta"|"observer"|"designer"]
  #   If set, only return courses that have at least one user enrolled in
  #   in the course with one of the specified enrollment types.
  #
  # @argument published [Boolean]
  #   If true, include only published courses.  If false, exclude published
  #   courses.  If not present, do not filter on published status.
  #
  # @argument completed [Boolean]
  #   If true, include only completed courses (these may be in state
  #   'completed', or their enrollment term may have ended).  If false, exclude
  #   completed courses.  If not present, do not filter on completed status.
  #
  # @argument blueprint [Boolean]
  #   If true, include only blueprint courses. If false, exclude them.
  #   If not present, do not filter on this basis.
  #
  # @argument blueprint_associated [Boolean]
  #   If true, include only courses that inherit content from a blueprint course.
  #   If false, exclude them. If not present, do not filter on this basis.
  #
  # @argument by_teachers[] [Integer]
  #   List of User IDs of teachers; if supplied, include only courses taught by
  #   one of the referenced users.
  #
  # @argument by_subaccounts[] [Integer]
  #   List of Account IDs; if supplied, include only courses associated with one
  #   of the referenced subaccounts.
  #
  # @argument hide_enrollmentless_courses [Boolean]
  #   If present, only return courses that have at least one enrollment.
  #   Equivalent to 'with_enrollments=true'; retained for compatibility.
  #
  # @argument state[] ["created"|"claimed"|"available"|"completed"|"deleted"|"all"]
  #   If set, only return courses that are in the given state(s). By default,
  #   all states but "deleted" are returned.
  #
  # @argument enrollment_term_id [Integer]
  #   If set, only includes courses from the specified term.
  #
  # @argument search_term [String]
  #   The partial course name, code, or full ID to match and return in the results list. Must be at least 3 characters.
  #
  # @argument include[] [String, "syllabus_body"|"term"|"course_progress"|"storage_quota_used_mb"|"total_students"|"teachers"|"account_name"|"concluded"]
  #   - All explanations can be seen in the {api:CoursesController#index Course API index documentation}
  #   - "sections", "needs_grading_count" and "total_scores" are not valid options at the account level
  #
  # @argument sort [String, "course_name"|"sis_course_id"|"teacher"|"account_name"]
  #   The column to sort results by.
  #
  # @argument order [String, "asc"|"desc"]
  #   The order to sort the given column by.
  #
  # @argument search_by [String, "course"|"teacher"]
  #   The filter to search by. "course" searches for course names, course codes,
  #   and SIS IDs. "teacher" searches for teacher names
  #
  # @returns [Course]
  def courses_api
    return unless authorized_action(@account, @current_user, :read_course_list)

    params[:state] ||= %w{created claimed available completed}
    params[:state] = %w{created claimed available completed deleted} if Array(params[:state]).include?('all')
    if value_to_boolean(params[:published])
      params[:state] -= %w{created claimed completed deleted}
    elsif !params[:published].nil? && !value_to_boolean(params[:published])
      params[:state] -= %w{available}
    end

    sortable_name_col = User.sortable_name_order_by_clause('users')

    order = if params[:sort] == 'course_name'
              "#{Course.best_unicode_collation_key('courses.name')}"
            elsif params[:sort] == 'sis_course_id'
              "courses.sis_source_id"
            elsif params[:sort] == 'teacher'
              "(SELECT #{sortable_name_col} FROM #{User.quoted_table_name}
                JOIN #{Enrollment.quoted_table_name} on users.id = enrollments.user_id
                WHERE enrollments.workflow_state <> 'deleted'
                AND enrollments.type = 'TeacherEnrollment'
                AND enrollments.course_id = courses.id
                ORDER BY #{sortable_name_col} LIMIT 1)"
            # leaving subaccount as an option for backwards compatibility
            elsif params[:sort] == 'subaccount' || params[:sort] == 'account_name'
              "(SELECT #{Account.best_unicode_collation_key('accounts.name')} FROM #{Account.quoted_table_name}
                WHERE accounts.id = courses.account_id)"
            elsif params[:sort] == 'term'
              "(SELECT #{EnrollmentTerm.best_unicode_collation_key('enrollment_terms.name')}
                FROM #{EnrollmentTerm.quoted_table_name}
                WHERE enrollment_terms.id = courses.enrollment_term_id)"
            else
              "id"
            end

    if params[:sort] && params[:order]
      order += (params[:order] == "desc" ? " DESC, id DESC" : ", id")
    end

    opts = { :include_crosslisted_courses => value_to_boolean(params[:include_crosslisted_courses]) }
    @courses = @account.associated_courses(opts).order(Arel.sql(order)).where(:workflow_state => params[:state])

    if params[:hide_enrollmentless_courses] || value_to_boolean(params[:with_enrollments])
      @courses = @courses.with_enrollments
    elsif !params[:with_enrollments].nil? && !value_to_boolean(params[:with_enrollments])
      @courses = @courses.without_enrollments
    end

    if params[:enrollment_type].is_a?(Array)
      @courses = @courses.with_enrollment_types(params[:enrollment_type])
    end

    if value_to_boolean(params[:completed])
      @courses = @courses.completed
    elsif !params[:completed].nil? && !value_to_boolean(params[:completed])
      @courses = @courses.not_completed
    end

    if value_to_boolean(params[:blueprint])
      @courses = @courses.master_courses
    elsif !params[:blueprint].nil?
      @courses = @courses.not_master_courses
    end

    if value_to_boolean(params[:blueprint_associated])
      @courses = @courses.associated_courses
    elsif !params[:blueprint_associated].nil?
      @courses = @courses.not_associated_courses
    end

    if params[:by_teachers].is_a?(Array)
      teacher_ids = Api.map_ids(params[:by_teachers], User, @domain_root_account, @current_user).map(&:to_i)
      @courses = @courses.by_teachers(teacher_ids)
    end

    if params[:by_subaccounts].is_a?(Array)
      account_ids = Api.map_ids(params[:by_subaccounts], Account, @domain_root_account, @current_user).map(&:to_i)
      @courses = @courses.by_associated_accounts(account_ids)
    end

    if params[:enrollment_term_id]
      term = api_find(@account.root_account.enrollment_terms, params[:enrollment_term_id])
      @courses = @courses.for_term(term)
    end

    if params[:search_term]
      search_term = params[:search_term]
      SearchTermHelper.validate_search_term(search_term)

      if params[:search_by] == "teacher"
        @courses = @courses.where("EXISTS (?)", TeacherEnrollment.active.joins(:user).where(
          ActiveRecord::Base.wildcard('users.name', params[:search_term])
        ).where("enrollments.course_id=courses.id"))
      else
        name = ActiveRecord::Base.wildcard('courses.name', search_term)
        code = ActiveRecord::Base.wildcard('courses.course_code', search_term)

        if @account.grants_any_right?(@current_user, :read_sis, :manage_sis)
          sis_source = ActiveRecord::Base.wildcard('courses.sis_source_id', search_term)
          @courses = @courses.merge(Course.where(:id => search_term).or(Course.where(code)).or(Course.where(name)).or(Course.where(sis_source)))
        else
          @courses = @courses.merge(Course.where(:id => search_term).or(Course.where(code)).or(Course.where(name)))
        end
      end
    end

    includes = Set.new(Array(params[:include]))
    # We only want to return the permissions for single courses and not lists of courses.
    # sections, needs_grading_count, and total_score not valid as enrollments are needed
    includes -= ['permissions', 'sections', 'needs_grading_count', 'total_scores']

    page_opts = {}
    page_opts[:total_entries] = nil if params[:search_term] # doesn't calculate a total count

    all_precalculated_permissions = nil
    Shackles.activate(:slave) do
      @courses = Api.paginate(@courses, self, api_v1_account_courses_url, page_opts)

      ActiveRecord::Associations::Preloader.new.preload(@courses, [:account, :root_account, course_account_associations: :account])
      preload_teachers(@courses) if includes.include?("teachers")
      ActiveRecord::Associations::Preloader.new.preload(@courses, [:enrollment_term]) if includes.include?("term") || includes.include?('concluded')

      if includes.include?("total_students")
        student_counts = StudentEnrollment.not_fake.where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')").
          where(:course_id => @courses).group(:course_id).distinct.count(:user_id)
        @courses.each {|c| c.student_count = student_counts[c.id] || 0 }
      end
      all_precalculated_permissions = @current_user.precalculate_permissions_for_courses(@courses, [:read_sis, :manage_sis])
    end

    render :json => @courses.map { |c| course_json(c, @current_user, session, includes, nil,
      precalculated_permissions: all_precalculated_permissions&.dig(c.global_id)) }
  end

  # Delegated to by the update action (when the request is an api_request?)
  def update_api
    if authorized_action(@account, @current_user, [:manage_account_settings, :manage_storage_quotas])
      account_params = params[:account].present? ? strong_account_params.to_unsafe_h : {}
      includes = Array(params[:includes]) || []
      unauthorized = false

      if params[:account].key?(:sis_account_id)
        sis_id = params[:account].delete(:sis_account_id)
        if @account.root_account.grants_right?(@current_user, session, :manage_sis) && !@account.root_account?
          @account.sis_source_id = sis_id.presence
        else
          if @account.root_account?
            @account.errors.add(:unauthorized, t('Cannot set sis_account_id on a root_account.'))
          else
            @account.errors.add(:unauthorized, t('To change sis_account_id the user must have manage_sis permission.'))
          end
          unauthorized = true
        end
      end

      if params[:account][:services]
        if authorized_action(@account, @current_user, :manage_account_settings)
          params[:account][:services].slice(*Account.services_exposed_to_ui_hash(nil, @current_user, @account).keys).each do |key, value|
            @account.set_service_availability(key, value_to_boolean(value))
          end
          includes << 'services'
          params[:account].delete :services
        end
      end

      # Set default Dashboard View
      set_default_dashboard_view(params.dig(:account, :settings)&.delete(:default_dashboard_view))

      # account settings (:manage_account_settings)
      account_settings = account_params.slice(:name, :default_time_zone, :settings)
      unless account_settings.empty?
        if @account.grants_right?(@current_user, session, :manage_account_settings)
          if account_settings[:settings]
            account_settings[:settings].slice!(*permitted_api_account_settings)
            ensure_sis_max_name_length_value!(account_settings)
          end
          @account.errors.add(:name, t(:account_name_required, 'The account name cannot be blank')) if account_params.has_key?(:name) && account_params[:name].blank?
          @account.errors.add(:default_time_zone, t(:unrecognized_time_zone, "'%{timezone}' is not a recognized time zone", :timezone => account_params[:default_time_zone])) if account_params.has_key?(:default_time_zone) && ActiveSupport::TimeZone.new(account_params[:default_time_zone]).nil?
        else
          account_settings.each {|k, v| @account.errors.add(k.to_sym, t(:cannot_manage_account, 'You are not allowed to manage account settings'))}
          unauthorized = true
        end
      end

      # quotas (:manage_account_quotas)
      quota_settings = account_params.slice(:default_storage_quota_mb, :default_user_storage_quota_mb,
                                                      :default_group_storage_quota_mb)
      unless quota_settings.empty?
        if @account.grants_right?(@current_user, session, :manage_storage_quotas)
          [:default_storage_quota_mb, :default_user_storage_quota_mb, :default_group_storage_quota_mb].each do |quota_type|
            next unless quota_settings.has_key?(quota_type)

            quota_value = quota_settings[quota_type].to_s.strip
            if INTEGER_REGEX !~ quota_value.to_s
              @account.errors.add(quota_type, t(:quota_integer_required, 'An integer value is required'))
            else
              @account.errors.add(quota_type, t(:quota_must_be_positive, 'Value must be positive')) if quota_value.to_i < 0
              @account.errors.add(quota_type, t(:quota_too_large, 'Value too large')) if quota_value.to_i >= 2**62 / 1.megabytes
            end
          end
        else
          quota_settings.each {|k, v| @account.errors.add(k.to_sym, t(:cannot_manage_quotas, 'You are not allowed to manage quota settings'))}
          unauthorized = true
        end
      end

      if unauthorized
        # Attempt to modify something without sufficient permissions
        render :json => @account.errors, :status => :unauthorized
      else
        success = @account.errors.empty?
        success &&= @account.update_attributes(account_settings.merge(quota_settings)) rescue false

        if success
          # Successfully completed
          update_user_dashboards
          render :json => account_json(@account, @current_user, session, includes)
        else
          # Failed (hopefully with errors)
          render :json => @account.errors, :status => :bad_request
        end
      end
    end
  end

  # @API Update an account
  # Update an existing account.
  #
  # @argument account[name] [String]
  #   Updates the account name
  #
  # @argument account[sis_account_id] [String]
  #   Updates the account sis_account_id
  #   Must have manage_sis permission and must not be a root_account.
  #
  # @argument account[default_time_zone] [String]
  #   The default time zone of the account. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument account[default_storage_quota_mb] [Integer]
  #   The default course storage quota to be used, if not otherwise specified.
  #
  # @argument account[default_user_storage_quota_mb] [Integer]
  #   The default user storage quota to be used, if not otherwise specified.
  #
  # @argument account[default_group_storage_quota_mb] [Integer]
  #   The default group storage quota to be used, if not otherwise specified.
  #
  # @argument account[settings][restrict_student_past_view][value] [Boolean]
  #   Restrict students from viewing courses after end date
  #
  # @argument account[settings][restrict_student_past_view][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument account[settings][restrict_student_future_view][value] [Boolean]
  #   Restrict students from viewing courses before start date
  #
  # @argument account[settings][restrict_student_future_view][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument account[settings][lock_all_announcements][value] [Boolean]
  #   Disable comments on announcements
  #
  # @argument account[settings][lock_all_announcements][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument account[settings][usage_rights_required][value] [Boolean]
  #   Copyright and license information must be provided for files before they are published.
  #
  # @argument account[settings][usage_rights_required][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument account[settings][restrict_student_future_listing][value] [Boolean]
  #   Restrict students from viewing future enrollments in course list
  #
  # @argument account[settings][restrict_student_future_listing][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument account[services] [Hash]
  #   Give this a set of keys and boolean values to enable or disable services matching the keys
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/<account_id> \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'account[name]=New account name' \
  #     -d 'account[default_time_zone]=Mountain Time (US & Canada)' \
  #     -d 'account[default_storage_quota_mb]=450'
  #
  # @returns Account
  def update
    return update_api if api_request?
    if authorized_action(@account, @current_user, :manage_account_settings)
      respond_to do |format|
        if @account.root_account?
          terms_attrs = params[:account][:terms_of_service]
          @account.update_terms_of_service(terms_attrs) if terms_attrs.present?
          if @account.feature_enabled?(:slack_notifications)
            slack_api_key = params[:account].dig(:slack, :slack_api_key)
            if slack_api_key.present?
              encrypted_slack_key, salt = Canvas::Security.encrypt_password(slack_api_key.to_s, 'instructure_slack_encrypted_key')
              @account.settings[:encrypted_slack_key] = encrypted_slack_key
              @account.settings[:encrypted_slack_key_salt] = salt
            end
          end
        end

        pronouns = params[:account].delete :pronouns
        if pronouns && !@account.site_admin? && @account.root_account? && @account.feature_enabled?(:account_pronouns)
          @account.pronouns = pronouns
        end

        custom_help_links = params[:account].delete :custom_help_links
        if custom_help_links
          sorted_help_links = custom_help_links.to_unsafe_h.select{|_k, h| h['state'] != 'deleted' && h['state'] != 'new'}.sort_by{|_k, h| _k.to_i}
          sorted_help_links.map! do |index_with_hash|
            hash = index_with_hash[1].to_hash.with_indifferent_access
            hash.delete('state')
            hash.assert_valid_keys ["text", "subtext", "url", "available_to", "type", "id"]
            hash
          end
          @account.settings[:custom_help_links] = @account.help_links_builder.process_links_before_save(sorted_help_links)
          @account.settings[:new_custom_help_links] = true
        end

        params[:account][:turnitin_host] = validated_turnitin_host(params[:account][:turnitin_host])
        enable_user_notes = params[:account].delete :enable_user_notes
        allow_sis_import = params[:account].delete :allow_sis_import
        params[:account].delete :default_user_storage_quota_mb unless @account.root_account? && !@account.site_admin?
        unless @account.grants_right? @current_user, :manage_storage_quotas
          [:storage_quota, :default_storage_quota, :default_storage_quota_mb,
           :default_user_storage_quota, :default_user_storage_quota_mb,
           :default_group_storage_quota, :default_group_storage_quota_mb].each { |key| params[:account].delete key }
        end
        if params[:account][:services]
          params[:account][:services].slice(*Account.services_exposed_to_ui_hash(nil, @current_user, @account).keys).each do |key, value|
            @account.set_service_availability(key, value == '1')
          end
          params[:account].delete :services
        end

        # If the setting is present (update is called from 2 different settings forms, one for notifications)
        if params[:account][:settings] && params[:account][:settings][:outgoing_email_default_name_option].present?
          # If set to default, remove the custom name so it doesn't get saved
          params[:account][:settings][:outgoing_email_default_name] = '' if params[:account][:settings][:outgoing_email_default_name_option] == 'default'
        end

        if @account.grants_right?(@current_user, :manage_site_settings)
          google_docs_domain = params[:account][:settings].try(:delete, :google_docs_domain)
          if @account.feature_enabled?(:google_docs_domain_restriction) &&
             @account.root_account? &&
             !@account.site_admin?
            @account.settings[:google_docs_domain] = google_docs_domain.present? ? google_docs_domain : nil
          end

          @account.enable_user_notes = enable_user_notes if enable_user_notes
          @account.allow_sis_import = allow_sis_import if allow_sis_import && @account.root_account?
          if @account.site_admin? && params[:account][:settings]
            # these shouldn't get set for the site admin account
            params[:account][:settings].delete(:enable_alerts)
            params[:account][:settings].delete(:enable_eportfolios)
            params[:account][:settings].delete(:include_integration_ids_in_gradebook_exports)
          end
        else
          # must have :manage_site_settings to update these
          [ :admins_can_change_passwords,
            :admins_can_view_notifications,
            :enable_alerts,
            :enable_eportfolios,
            :enable_profiles,
            :enable_turnitin,
            :include_integration_ids_in_gradebook_exports,
            :show_scheduler,
            :global_includes,
            :gmail_domain
          ].each do |key|
            params[:account][:settings].try(:delete, key)
          end
        end

        if params[:account][:settings] && params[:account][:settings].has_key?(:trusted_referers)
          if trusted_referers = params[:account][:settings].delete(:trusted_referers)
            @account.trusted_referers = trusted_referers if @account.root_account?
          end
        end

        # don't accidentally turn the default help link name into a custom one and thereby break i18n
        help_link_name = params.dig(:account, :settings, :help_link_name)
        params[:account][:settings][:help_link_name] = nil if help_link_name == default_help_link_name

        ensure_sis_max_name_length_value!(params[:account]) if params[:account][:settings]

        if sis_id = params[:account].delete(:sis_source_id)
          if !@account.root_account? && sis_id != @account.sis_source_id && @account.root_account.grants_right?(@current_user, session, :manage_sis)
            if sis_id == ''
              @account.sis_source_id = nil
            else
              @account.sis_source_id = sis_id
            end
          end
        end

        @account.process_external_integration_keys(params[:account][:external_integration_keys], @current_user)

        can_edit_email = params[:account][:settings].try(:delete, :edit_institution_email)
        if @account.root_account? && !can_edit_email.nil?
          @account[:settings][:edit_institution_email] = value_to_boolean(can_edit_email)
        end

        remove_ip_filters = params[:account].delete(:remove_ip_filters)
        params[:account][:ip_filters] = [] if remove_ip_filters

        # Set default Dashboard view
        set_default_dashboard_view(params.dig(:account, :settings)&.delete(:default_dashboard_view))

        if @account.update_attributes(strong_account_params)
          update_user_dashboards
          format.html { redirect_to account_settings_url(@account) }
          format.json { render :json => @account }
        else
          flash[:error] = t(:update_failed_notice, "Account settings update failed")
          format.html { redirect_to account_settings_url(@account) }
          format.json { render :json => @account.errors, :status => :bad_request }
        end
      end
    end
  end

  def reports_tab
    if authorized_action(@account, @current_user, :read_reports)
      @available_reports = AccountReport.available_reports
      @root_account = @account.root_account
      @account.shard.activate do
        scope = @account.account_reports.active.where("report_type=name").most_recent
        @last_complete_reports = AccountReport.from("unnest('{#{@available_reports.keys.join(',')}}'::text[]) report_types (name),
                LATERAL (#{scope.complete.to_sql}) account_reports ").
          order("report_types.name").
          preload(:attachment).
          index_by(&:report_type)
        @last_reports = AccountReport.from("unnest('{#{@available_reports.keys.join(',')}}'::text[]) report_types (name),
                LATERAL (#{scope.to_sql}) account_reports ").
          order("report_types.name").
          index_by(&:report_type)
      end
      render :layout => false
    end
  end

  def terms_of_service_custom_content
    TermsOfService.ensure_terms_for_account(@domain_root_account)
    render plain: @domain_root_account.terms_of_service.terms_of_service_content&.content
  end

  def settings
    if authorized_action(@account, @current_user, :read)
      load_course_right_side
      @account_users = @account.account_users.active
      @account_user_permissions_cache = AccountUser.create_permissions_cache(@account_users, @current_user, session)
      ActiveRecord::Associations::Preloader.new.preload(@account_users, user: :communication_channels)
      order_hash = {}
      @account.available_account_roles.each_with_index do |role, idx|
        order_hash[role.id] = idx
      end
      @account_users = @account_users.select(&:user).sort_by{|au| [order_hash[au.role_id] || CanvasSort::Last, Canvas::ICU.collation_key(au.user.sortable_name)] }
      @alerts = @account.alerts

      @account_roles = @account.available_account_roles.sort_by(&:display_sort_index).map{|role| {:id => role.id, :label => role.label}}
      @course_roles = @account.available_course_roles.sort_by(&:display_sort_index).map{|role| {:id => role.id, :label => role.label}}

      @announcements = @account.announcements.order(:created_at).paginate(page: params[:page], per_page: 50)
      @external_integration_keys = ExternalIntegrationKey.indexed_keys_for(@account)
      js_env({
        APP_CENTER: { enabled: Canvas::Plugin.find(:app_center).enabled? },
        LTI_LAUNCH_URL: account_tool_proxy_registration_path(@account),
        EXTERNAL_TOOLS_CREATE_URL: url_for(controller: :external_tools, action: :create, account_id: @context.id),
        TOOL_CONFIGURATION_SHOW_URL: account_show_tool_configuration_url(account_id: @context.id, developer_key_id: ':developer_key_id'),
        MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED: @account.root_account.feature_enabled?(:membership_service_for_lti_tools),
        CONTEXT_BASE_URL: "/accounts/#{@context.id}",
        MASKED_APP_CENTER_ACCESS_TOKEN: @account.settings[:app_center_access_token].try(:[], 0...5),
        NEW_FEATURES_UI: @account.root_account.feature_enabled?(:new_features_ui),
        PERMISSIONS: {
          :create_tool_manually => @account.grants_right?(@current_user, session, :create_tool_manually),
          :manage_feature_flags => @account.grants_right?(@current_user, session, :manage_feature_flags)
        },
        CSP: {
          :enabled => @account.csp_enabled?,
          :inherited => @account.csp_inherited?,
          :settings_locked => @account.csp_locked?,
        }
      })
      js_env(edit_help_links_env, true)
    end
  end

  # Admin Tools page controls
  # => Log Auditing
  # => Add/Change Quota
  # = Restoring Content
  def admin_tools
    if !@account.can_see_admin_tools_tab?(@current_user)
      return render_unauthorized_action
    end

    authentication_logging = @account.grants_any_right?(@current_user, :view_statistics, :manage_user_logins)
    grade_change_logging = @account.grants_right?(@current_user, :view_grade_changes)
    course_logging = @account.grants_right?(@current_user, :view_course_changes)
    mutation_logging = @account.feature_enabled?(:mutation_audit_log) &&
      @account.grants_right?(@current_user, :manage_account_settings)
    if authentication_logging || grade_change_logging || course_logging || mutation_logging
      logging = {
        authentication: authentication_logging,
        grade_change: grade_change_logging,
        course: course_logging,
        mutation: mutation_logging,
      }
    end
    logging ||= false

    js_env :ACCOUNT_ID => @account.id
    js_env :PERMISSIONS => {
       restore_course: @account.grants_right?(@current_user, session, :undelete_courses),
       # Permission caching issue makes explicitly checking the account setting
       # an easier option.
       view_messages: (@account.settings[:admins_can_view_notifications] &&
                       @account.grants_right?(@current_user, session, :view_notifications)) ||
                      Account.site_admin.grants_right?(@current_user, :read_messages),
       logging: logging
      }
  end

  def confirm_delete_user
    raise ActiveRecord::RecordNotFound unless @account.root_account?
    @user = api_find(User, params[:user_id])

    unless @account.user_account_associations.where(user_id: @user).exists?
      flash[:error] = t(:no_user_message, "No user found with that id")
      redirect_to account_url(@account)
      return
    end

    @context = @account
    render_unauthorized_action unless @user.allows_user_to_remove_from_account?(@account, @current_user)
  end

  # @API Delete a user from the root account
  #
  # Delete a user record from a Canvas root account. If a user is associated
  # with multiple root accounts (in a multi-tenant instance of Canvas), this
  # action will NOT remove them from the other accounts.
  #
  # WARNING: This API will allow a user to remove themselves from the account.
  # If they do this, they won't be able to make API calls or log into Canvas at
  # that account.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/3/users/5 \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  #       -X DELETE
  #
  # @returns User
  def remove_user
    raise ActiveRecord::RecordNotFound unless @account.root_account?
    @user = api_find(User, params[:user_id])
    raise ActiveRecord::RecordNotFound unless @account.user_account_associations.where(user_id: @user).exists?
    if @user.allows_user_to_remove_from_account?(@account, @current_user)
      @user.remove_from_root_account(@account, updating_user: @current_user)
      flash[:notice] = t(:user_deleted_message, "%{username} successfully deleted", :username => @user.name)
      respond_to do |format|
        format.html { redirect_to account_users_url(@account) }
        format.json { render :json => @user || {} }
      end
    else
      render_unauthorized_action
    end
  end

  def turnitin_confirmation
    if authorized_action(@account, @current_user, :manage_account_settings)
      host = validated_turnitin_host(params[:turnitin_host])
      begin
        turnitin = Turnitin::Client.new(
          params[:turnitin_account_id],
          params[:turnitin_shared_secret],
          host
        )
        render :json => { :success => turnitin.testSettings }
      rescue
        render :json => { :success => false }
      end
    end
  end

  def load_course_right_side(opts = {})
    @root_account = @account.root_account
    @maximum_courses_im_gonna_show = 50
    @term = nil
    if params[:enrollment_term_id].present?
      @term = @root_account.enrollment_terms.active.find(params[:enrollment_term_id]) rescue nil
      @term ||= @root_account.enrollment_terms.active[-1]
    end
    associated_courses = @account.associated_courses(opts).active
    associated_courses = associated_courses.for_term(@term) if @term
    @associated_courses_count = associated_courses.count
    @hide_enrollmentless_courses = params[:hide_enrollmentless_courses] == "1"
    @only_master_courses = (params[:only_master_courses] == "1")
    @courses_sort_orders = [
      {
        key: "name_asc",
        label: -> { t("A - Z") },
        col: Course.best_unicode_collation_key("courses.name"),
        direction: "ASC"
      },
      {
        key: "name_desc",
        label: -> { t("Z - A") },
        col: Course.best_unicode_collation_key("courses.name"),
        direction: "DESC"
      },
      {
        key: "created_at_desc",
        label: -> { t("Newest - Oldest") },
        col: "courses.created_at",
        direction: "DESC"
      },
      {
        key: "created_at_asc",
        label: -> { t("Oldest - Newest") },
        col: "courses.created_at",
        direction: "ASC"
      }
    ].freeze
  end
  protected :load_course_right_side

  def statistics
    if authorized_action(@account, @current_user, :view_statistics)
      add_crumb(t(:crumb_statistics, "Statistics"), statistics_account_url(@account))
      if @account.grants_right?(@current_user, :read_course_list)
        @recently_started_courses = @account.all_courses.recently_started
        @recently_ended_courses = @account.all_courses.recently_ended
        if @account == Account.default
          @recently_created_courses = @account.all_courses.recently_created
        end
      end
      if @account.grants_right?(@current_user, :read_roster)
        @recently_logged_users = @account.all_users.recently_logged_in
      end
      @counts_report = @account.report_snapshots.detailed.order(:created_at).last.try(:data)
    end
  end

  def statistics_graph
    if authorized_action(@account, @current_user, :view_statistics)
      @items = @account.report_snapshots.progressive.last.try(:report_value_over_time, params[:attribute])
      respond_to do |format|
        format.json { render :json => @items }
        format.csv {
          res = CSV.generate do |csv|
            csv << ['Timestamp', 'Value']
            @items.each do |item|
              csv << [item[0]/1000, item[1]]
            end
          end
          cancel_cache_buster
          # TODO i18n
          send_data(
            res,
            :type => "text/csv",
            :filename => "#{params[:attribute].titleize} Report for #{@account.name}.csv",
            :disposition => "attachment"
          )
        }
      end
    end
  end

  def avatars
    if authorized_action(@account, @current_user, :manage_admin_users)
      @users = @account.all_users(nil)
      @avatar_counts = {
        :all => format_avatar_count(@users.with_avatar_state('any').count),
        :reported => format_avatar_count(@users.with_avatar_state('reported').count),
        :re_reported => format_avatar_count(@users.with_avatar_state('re_reported').count),
        :submitted => format_avatar_count(@users.with_avatar_state('submitted').count)
      }
      if params[:avatar_state]
        @users = @users.with_avatar_state(params[:avatar_state])
        @avatar_state = params[:avatar_state]
      else
        if @domain_root_account && @domain_root_account.settings[:avatars] == 'enabled_pending'
          @users = @users.with_avatar_state('submitted')
          @avatar_state = 'submitted'
        else
          @users = @users.with_avatar_state('reported')
          @avatar_state = 'reported'
        end
      end
      @users = Api.paginate(@users, self, account_avatars_url)
    end
  end

  def sis_import
    if authorized_action(@account, @current_user, [:import_sis, :manage_sis])
      return redirect_to account_settings_url(@account) if !@account.allow_sis_import || !@account.root_account?
      @current_batch = @account.current_sis_batch
      @last_batch = @account.sis_batches.order('created_at DESC').first
      @terms = @account.enrollment_terms.active
      respond_to do |format|
        format.html
        format.json { render :json => @current_batch }
      end
    end
  end

  def courses_redirect
    redirect_to course_url(params[:id])
  end

  def courses
    if authorized_action(@context, @current_user, :read)
      order = sort_order # must be done on master because it persists in user preferences
      Shackles.activate(:slave) do
        load_course_right_side
        @courses = []
        @query = (params[:course] && params[:course][:name]) || params[:term]
        if @context && @context.is_a?(Account) && @query
          @courses = @context.courses_name_like(@query, :order => order, :term => @term,
            :hide_enrollmentless_courses => @hide_enrollmentless_courses,
            :only_master_courses => @only_master_courses)
        end
      end
      respond_to do |format|
        format.html {
          return redirect_to @courses.first if @courses.length == 1
          Shackles.activate(:slave) do
            build_course_stats
          end
        }
        format.json  {
          cancel_cache_buster
          expires_in 30.minutes
          render :json => @courses.map{ |c| {:label => c.name, :id => c.id, :term => c.enrollment_term.name} }
        }
      end
    end
  end

  def build_course_stats
    courses_to_fetch_users_for = @courses

    templates = MasterCourses::MasterTemplate.active.for_full_course.where(:course_id => @courses).to_a
    if templates.any?
      MasterCourses::MasterTemplate.preload_index_data(templates)
      @master_template_index = templates.index_by(&:course_id)
      courses_to_fetch_users_for = courses_to_fetch_users_for.reject{|c| @master_template_index[c.id]} # don't fetch the counts for the master/blueprint courses
    end

    teachers = TeacherEnrollment.for_courses_with_user_name(courses_to_fetch_users_for).where.not(:enrollments => {:workflow_state => %w{rejected deleted}})
    course_to_student_counts = StudentEnrollment.student_in_claimed_or_available.where(:course_id => courses_to_fetch_users_for).group(:course_id).distinct.count(:user_id)
    courses_to_teachers = teachers.inject({}) do |result, teacher|
      result[teacher.course_id] ||= []
      result[teacher.course_id] << teacher
      result
    end
    courses_to_fetch_users_for.each do |course|
      course.student_count = course_to_student_counts[course.id] || 0
      course_teachers = courses_to_teachers[course.id] || []
      course.teacher_names = course_teachers.uniq(&:user_id).map(&:user_name)
    end
  end
  protected :build_course_stats

  # TODO Refactor add_account_user and remove_account_user actions into
  # AdminsController. see https://redmine.instructure.com/issues/6634
  def add_account_user
    if role_id = params[:role_id]
      role = Role.get_role_by_id(role_id)
      raise ActiveRecord::RecordNotFound unless role
    else
      role = Role.get_built_in_role('AccountAdmin')
    end

    list = UserList.new(params[:user_list],
                        root_account: @context.root_account,
                        search_method: @context.user_list_search_mode_for(@current_user),
                        current_user: @current_user)
    users = list.users
    admins = users.map do |user|
      admin = @context.account_users.where(user_id: user.id, role_id: role.id).first_or_initialize
      admin.user = user
      admin.workflow_state = 'active'
      return unless authorized_action(admin, @current_user, :create)
      admin
    end

    account_users = admins.map do |admin|
      if admin.new_record? || admin.workflow_state_changed?
        admin.save!
        if admin.user.registered?
          admin.account_user_notification!
        else
          admin.account_user_registration!
        end
      end

      { :enrollment => {
          :id => admin.id,
          :name => admin.user.name,
          :role_id => admin.role_id,
          :membership_type => AccountUser.readable_type(admin.role.name),
          :workflow_state => 'active',
          :user_id => admin.user.id,
          :type => 'admin',
          :email => admin.user.email
      }}
    end
    render :json => account_users
  end

  def remove_account_user
    admin = @context.account_users.find(params[:id])
    if authorized_action(admin, @current_user, :destroy)
      admin.destroy
      respond_to do |format|
        format.html { redirect_to account_settings_url(@context, :anchor => "tab-users") }
        format.json { render :json => admin }
      end
    end
  end

  def validated_turnitin_host(input_host)
    if input_host.present?
      _, turnitin_uri = CanvasHttp.validate_url(input_host)
      turnitin_uri.host
    else
      nil
    end
  end

  def process_external_integration_keys(account = @account)
    account.process_external_integration_keys(params[:account][:external_integration_keys], @current_user)
  end

  def set_default_dashboard_view(new_view)
    if new_view != @account.default_dashboard_view
      if authorized_action(@account, @current_user, :manage_account_settings)
        # NOTE: Only _sets_ the property. It's up to the caller to `save` it
        @account.default_dashboard_view = new_view
      end
    end
  end

  def update_user_dashboards
    return unless value_to_boolean(params.dig(:account, :settings, :force_default_dashboard_view))
    @account.update_user_dashboards
  end

  def format_avatar_count(count = 0)
    count > 99 ? "99+" : count
  end
  private :format_avatar_count

  private

  def ensure_sis_max_name_length_value!(account_settings)
    sis_name_length_setting = account_settings[:settings][:sis_assignment_name_length_input]
    return if sis_name_length_setting.nil?
    value = sis_name_length_setting[:value]
    if value.to_i.to_s == value.to_s && value.to_i <= SIS_ASSINGMENT_NAME_LENGTH_DEFAULT && value.to_i >= 0
      sis_name_length_setting[:value] = value
    else
      sis_name_length_setting[:value] = SIS_ASSINGMENT_NAME_LENGTH_DEFAULT
    end
  end


  PERMITTED_SETTINGS_FOR_UPDATE = [:admins_can_change_passwords, :admins_can_view_notifications,
                                   :allow_invitation_previews, :allow_sending_scores_in_emails,
                                   :author_email_in_notifications, :canvadocs_prefer_office_online,
                                   :consortium_parent_account, :consortium_can_create_own_accounts, :can_add_pronouns,
                                   :shard_per_account, :consortium_autocreate_web_of_trust,
                                   :consortium_autocreate_reverse_trust,
                                   :default_storage_quota, :default_storage_quota_mb,
                                   :default_group_storage_quota, :default_group_storage_quota_mb,
                                   :default_user_storage_quota, :default_user_storage_quota_mb, :default_time_zone,
                                   :edit_institution_email, :enable_alerts, :enable_eportfolios, :enable_course_catalog,
                                   {:enable_offline_web_export => [:value]}.freeze,
                                   :enable_profiles, :enable_gravatar, :enable_turnitin, :equella_endpoint,
                                   :equella_teaser, :external_notification_warning, :global_includes,
                                   :google_docs_domain, :help_link_icon, :help_link_name,
                                   :include_integration_ids_in_gradebook_exports,
                                   :include_students_in_global_survey, :license_type,
                                   {:lock_all_announcements => [:value, :locked]}.freeze,
                                   :login_handle_name, :mfa_settings, :no_enrollments_can_create_courses,
                                   :open_registration, :outgoing_email_default_name,
                                   :prevent_course_renaming_by_teachers, :restrict_quiz_questions,
                                   {:restrict_student_future_listing => [:value, :locked]}.freeze,
                                   {:restrict_student_future_view => [:value, :locked]}.freeze,
                                   {:restrict_student_past_view => [:value, :locked]}.freeze,
                                   :self_enrollment, :show_scheduler, :sis_app_token, :sis_app_url,
                                   {:sis_assignment_name_length => [:value]}.freeze,
                                   {:sis_assignment_name_length_input => [:value]}.freeze,
                                   {:sis_default_grade_export => [:value]}.freeze,
                                   :sis_name,
                                   {:sis_require_assignment_due_date => [:value]}.freeze,
                                   {:sis_syncing => [:value, :locked]}.freeze,
                                   :strict_sis_check, :storage_quota, :students_can_create_courses,
                                   :sub_account_includes, :teachers_can_create_courses, :trusted_referers,
                                   :turnitin_host, :turnitin_account_id, :users_can_edit_name,
                                   {:usage_rights_required => [:value, :locked] }.freeze,
                                   :app_center_access_token, :default_dashboard_view, :force_default_dashboard_view].freeze

  def permitted_account_attributes
    [:name, :turnitin_account_id, :turnitin_shared_secret, :include_crosslisted_courses,
      :turnitin_host, :turnitin_comments, :turnitin_pledge, :turnitin_originality,
      :default_time_zone, :parent_account, :default_storage_quota,
      :default_storage_quota_mb, :storage_quota, :default_locale,
      :default_user_storage_quota_mb, :default_group_storage_quota_mb, :integration_id, :brand_config_md5,
      :settings => PERMITTED_SETTINGS_FOR_UPDATE, :ip_filters => strong_anything
    ]
  end

  def permitted_api_account_settings
    [:restrict_student_past_view,
      :restrict_student_future_view,
      :restrict_student_future_listing,
      :lock_all_announcements,
      :sis_assignment_name_length_input]
  end

  def strong_account_params
    # i'm doing this instead of normal params because we do too much hackery to the weak params, especially in plugins
    # and it breaks when we enforce inherited weak parameters (because we're not actually editing request.parameters anymore)
    params.require(:account).permit(*permitted_account_attributes)
  end

  def sort_order
    load_course_right_side unless @courses_sort_orders.present?

    if !params[:courses_sort_order].nil?
      @current_user.preferences[:course_sort] = params[:courses_sort_order]
      @current_user.save!
    end

    order = @courses_sort_orders.find do |ord|
      ord[:key] == @current_user.preferences[:course_sort]
    end


    order && "#{order[:col]} #{order[:direction]}"
  end

  def edit_help_links_env
    # @domain_root_account may be cached; load settings from @account to ensure they're up to date
    return {} unless @account == @domain_root_account
    {
      help_link_name: @account.settings[:help_link_name] || default_help_link_name,
      help_link_icon: @account.settings[:help_link_icon] || 'help',
      CUSTOM_HELP_LINKS: @account.help_links || [],
      DEFAULT_HELP_LINKS: @account.help_links_builder.instantiate_links(@account.help_links_builder.default_links)
    }
  end

end
