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
#         },
#         "self_registration_type": {
#           "description": "The type of self registration allowed",
#           "example": ["none", "observer", "all"],
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
#               ],
#               "is_featured": true,
#               "is_new": false,
#               "feature_headline": "Check this out!"
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
#               "id": "instructor_question",
#               "is_featured": false,
#               "is_new": true,
#               "feature_headline": ""
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
#               "url": "https://community.canvaslms.com/t5/Guides/ct-p/guides",
#               "type": "default",
#               "id": "search_the_canvas_guides",
#               "is_featured": false,
#               "is_new": false,
#               "feature_headline": ""
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
#               "id": "report_a_problem",
#               "is_featured": false,
#               "is_new": false,
#               "feature_headline": ""
#             }
#           ]
#         }
#       }
#     }

class AccountsController < ApplicationController
  before_action :require_user, only: %i[index
                                        help_links
                                        manually_created_courses_account
                                        account_calendar_settings
                                        environment]
  before_action :reject_student_view_student
  before_action :get_context
  before_action :rce_js_env, only: [:settings]

  include Api::V1::Account
  include CustomSidebarLinksHelper
  include DefaultDueTimeHelper

  INTEGER_REGEX = /\A[+-]?\d+\z/
  SIS_ASSINGMENT_NAME_LENGTH_DEFAULT = 255
  EPORTFOLIO_MODERATION_PER_PAGE = 100

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
        @accounts = (@current_user&.all_paginatable_accounts || []).paginate(per_page: 100)
      end
      format.json do
        @accounts = if @current_user
                      Api.paginate(@current_user.all_paginatable_accounts, self, api_v1_accounts_url)
                    else
                      []
                    end
        ActiveRecord::Associations.preload(@accounts, :root_account)

        # originally had 'includes' instead of 'include' like other endpoints
        includes = params[:include] || params[:includes]
        render json: @accounts.map { |a| account_json(a, @current_user, session, includes || [], false) }
      end
    end
  end

  # @API Get accounts that admins can manage
  # A paginated list of accounts where the current user has permission to create
  # or manage courses. List will be empty for students and teachers as only admins
  # can view which accounts they are in.
  #
  # @returns [Account]
  def manageable_accounts
    @accounts = @current_user ? @current_user.adminable_accounts : []
    @all_accounts = Set.new
    @accounts.each do |a|
      if a.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin, :create_courses)
        @all_accounts << a
        @all_accounts.merge Account.active.sub_accounts_recursive(a.id)
      end
    end
    @all_accounts = Api.paginate(@all_accounts, self, api_v1_manageable_accounts_url)
    render json: @all_accounts.map { |a| account_json(a, @current_user, session, [], false) }
  end

  # @API Get accounts that users can create courses in
  # A paginated list of accounts where the current user has permission to create
  # courses.
  #
  # @returns [Account]
  def course_creation_accounts
    return render json: [] unless @current_user

    accounts = @current_user.adminable_accounts || []
    accounts = accounts.select { |a| a.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin, :manage_courses_add) }
    sub_accounts = []
    # Load and handle ids from now on to avoid excessive memory usage
    accounts.each { |a| sub_accounts.concat Account.active.sub_account_ids_recursive(a.id) }
    accounts = accounts.pluck(:id)
    accounts.push(sub_accounts).flatten!

    @current_user.course_creating_student_enrollment_accounts.each do |a|
      accounts << a.root_account.manually_created_courses_account.id if a.root_account.students_can_create_courses?

      next unless a.root_account.students_can_create_courses_anywhere? ||
                  @current_user.active_k5_enrollments?(root_account: a.root_account) ||
                  a.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin, :create_courses)

      accounts << a.id
    end

    @current_user.course_creating_teacher_enrollment_accounts.each do |a|
      accounts << a.root_account.manually_created_courses_account.id if a.root_account.teachers_can_create_courses?

      next unless a.root_account.teachers_can_create_courses_anywhere? ||
                  @current_user.active_k5_enrollments?(root_account: a.root_account) ||
                  a.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin, :create_courses)

      accounts << a.id
    end

    user_enrollments = @current_user.enrollments.active.pluck(:root_account_id)
    @current_user.root_account_ids.each do |id|
      next if user_enrollments.include? id

      a = Account.find(id)
      accounts << a.manually_created_courses_account.id if a.no_enrollments_can_create_courses?
    end

    accounts = Api.paginate(accounts.uniq, self, api_v1_course_creation_accounts_url)
    # Fetch actual accounts now, after pagination, in a single transaction
    account_active_records = Account.where(id: accounts)
    accounts_json = accounts.map do |a|
      a = account_active_records.find { |ar| ar.id == a }
      account_json(a, @current_user, session, [], false)
    end
    render json: accounts_json
  end

  # @API List accounts for course admins
  # A paginated list of accounts that the current user can view through their
  # admin course enrollments. (Teacher, TA, or designer enrollments).
  # Only returns "id", "name", "workflow_state", "root_account_id" and "parent_account_id"
  #
  # @returns [Account]
  def course_accounts
    if @current_user
      account_ids = Rails.cache.fetch(["admin_enrollment_course_account_ids", @current_user].cache_key) do
        Account.joins(courses: :enrollments).merge(
          @current_user.enrollments.admin.shard(@current_user).except(:select, :joins)
        ).select("accounts.id").distinct.pluck(:id).map { |id| Shard.global_id_for(id) }
      end
      course_accounts = ShardedBookmarkedCollection.build(Account::Bookmarker, Account.where(id: account_ids), always_use_bookmarks: true)
      @accounts = Api.paginate(course_accounts, self, api_v1_course_accounts_url)
    else
      @accounts = []
    end
    ActiveRecord::Associations.preload(@accounts, :root_account)
    render json: @accounts.map { |a| account_json(a, @current_user, session, params[:includes] || [], true) }
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
        @redirect_on_unauth = true
        return course_user_search
      end
      format.json do
        render json: account_json(@account,
                                  @current_user,
                                  session,
                                  params[:includes] || [],
                                  !@account.grants_right?(@current_user, session, :manage))
      end
    end
  end

  # @API Settings
  # Returns a JSON object containing a subset of settings for the specified account.
  # It's possible an empty set will be returned if no settings are applicable.
  # The caller must be an Account admin with the manage_account_settings permission.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/<account_id>/settings \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {"microsoft_sync_enabled": true, "microsoft_sync_login_attribute_suffix": false}
  def show_settings
    return unless authorized_action(@account, @current_user, :manage_account_settings)

    public_attrs = %i[microsoft_sync_enabled
                      microsoft_sync_tenant
                      microsoft_sync_login_attribute
                      microsoft_sync_login_attribute_suffix
                      microsoft_sync_remote_attribute]

    render json: public_attrs.index_with { |key| @account.settings[key] }.compact
  end

  # @API List environment settings
  #
  # Return a hash of global settings for the root account
  # This is the same information supplied to the web interface as +ENV.SETTINGS+.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/settings/environment' \
  #     -H "Authorization: Bearer <token>"
  #
  # @example_response
  #
  #   { "calendar_contexts_limit": true, open_registration: false, ...}
  #
  def environment
    render json: cached_js_env_account_settings
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
    @accounts = if recursive
                  PaginatedCollection.build do |pager|
                    per_page = pager.per_page
                    current_page = [pager.current_page.to_i, 1].max
                    sub_accounts = Account.active.offset((current_page - 1) * per_page).limit(per_page + 1).sub_accounts_recursive(@account.id)

                    if sub_accounts.length > per_page
                      sub_accounts.pop
                      pager.next_page = current_page + 1
                    end

                    pager.replace sub_accounts
                  end
                else
                  @account.sub_accounts.order(:id)
                end

    @accounts = Api.paginate(@accounts,
                             self,
                             api_v1_sub_accounts_url,
                             total_entries: recursive ? nil : @accounts.count)

    ActiveRecord::Associations.preload(@accounts, [:root_account, :parent_account])
    render json: @accounts.map { |a| account_json(a, @current_user, session, []) }
  end

  # @API Get the Terms of Service
  #
  # Returns the terms of service for that account
  #
  # @returns TermsOfService
  def terms_of_service
    keys = %w[id terms_type passive account_id]
    tos = @account.root_account.terms_of_service
    res = tos.attributes.slice(*keys)
    res["content"] = tos.terms_of_service_content&.content
    res["self_registration_type"] = @account.self_registration_type
    render json: res
  end

  # @API Get help links
  #
  # Returns the help links for that account
  #
  # @returns HelpLinks
  def help_links
    render json: {} unless @account == @domain_root_account
    help_links = edit_help_links_env
    links = {
      help_link_name: help_links[:help_link_name],
      help_link_icon: help_links[:help_link_icon],
      custom_help_links: help_links[:CUSTOM_HELP_LINKS],
      default_help_links: help_links[:DEFAULT_HELP_LINKS],
    }
    render json: links
  end

  # @API Get the manually-created courses sub-account for the domain root account
  #
  # @returns Account
  def manually_created_courses_account
    account = @domain_root_account.manually_created_courses_account
    read_only = !account.grants_right?(@current_user, session, :read)
    render json: account_json(account, @current_user, session, [], read_only)
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
  # @argument public [Boolean]
  #   If true, include only public courses. If false, exclude them.
  #   If not present, do not filter on this basis.
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
  # @argument starts_before [Optional, Date]
  #   If set, only return courses that start before the value (inclusive)
  #   or their enrollment term starts before the value (inclusive)
  #   or both the course's start_at and the enrollment term's start_at are set to null.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument ends_after [Optional, Date]
  #   If set, only return courses that end after the value (inclusive)
  #   or their enrollment term ends after the value (inclusive)
  #   or both the course's end_at and the enrollment term's end_at are set to null.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument homeroom [Optional, Boolean]
  #   If set, only return homeroom courses.
  #
  # @returns [Course]
  def courses_api
    return unless authorized_action(@account, @current_user, :read_course_list)

    starts_before = CanvasTime.try_parse(params[:starts_before])
    ends_after = CanvasTime.try_parse(params[:ends_after])

    params[:state] ||= %w[created claimed available completed]
    params[:state] = %w[created claimed available completed deleted] if Array(params[:state]).include?("all")
    if value_to_boolean(params[:published])
      params[:state] -= %w[created claimed completed deleted]
    elsif !params[:published].nil? && !value_to_boolean(params[:published])
      params[:state] -= %w[available]
    end

    sortable_name_col = User.sortable_name_order_by_clause("users")

    order = case params[:sort]
            when "course_name"
              Course.best_unicode_collation_key("courses.name").to_s
            when "sis_course_id"
              "courses.sis_source_id"
            when "teacher"
              "(SELECT #{sortable_name_col} FROM #{User.quoted_table_name}
                JOIN #{Enrollment.quoted_table_name} on users.id = enrollments.user_id
                WHERE enrollments.workflow_state <> 'deleted'
                AND enrollments.type = 'TeacherEnrollment'
                AND enrollments.course_id = courses.id
                ORDER BY #{sortable_name_col} LIMIT 1)"
            # leaving subaccount as an option for backwards compatibility
            when "subaccount", "account_name"
              "(SELECT #{Account.best_unicode_collation_key("accounts.name")} FROM #{Account.quoted_table_name}
                WHERE accounts.id = courses.account_id)"
            when "term"
              "(SELECT #{EnrollmentTerm.best_unicode_collation_key("enrollment_terms.name")}
                FROM #{EnrollmentTerm.quoted_table_name}
                WHERE enrollment_terms.id = courses.enrollment_term_id)"
            else
              "id"
            end

    if params[:sort] && params[:order]
      order += ((params[:order] == "desc") ? " DESC, id DESC" : ", id")
    end

    opts = { include_crosslisted_courses: value_to_boolean(params[:include_crosslisted_courses]) }
    @courses = @account.associated_courses(opts).order(Arel.sql(order)).where(workflow_state: params[:state])

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

    if value_to_boolean(params[:public])
      @courses = @courses.public_courses
    elsif !params[:public].nil?
      @courses = @courses.not_public_courses
    end

    if value_to_boolean(params[:homeroom])
      @courses = @courses.homeroom
    end

    if starts_before || ends_after
      @courses = @courses.joins(:enrollment_term)
      if starts_before
        @courses = @courses.where("
        (courses.start_at IS NULL AND enrollment_terms.start_at IS NULL)
        OR courses.start_at <= ? OR enrollment_terms.start_at <= ?",
                                  starts_before,
                                  starts_before)
      end
      if ends_after
        @courses = @courses.where("
        (courses.conclude_at IS NULL AND enrollment_terms.end_at IS NULL)
        OR courses.conclude_at >= ? OR enrollment_terms.end_at >= ?",
                                  ends_after,
                                  ends_after)
      end
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
        @courses =
          @courses.where(
            TeacherEnrollment.active.joins(:user).where(
              ActiveRecord::Base.wildcard("users.name", params[:search_term])
            ).where(
              "enrollments.workflow_state NOT IN ('rejected', 'inactive', 'completed', 'deleted') AND enrollments.course_id=courses.id"
            ).arel.exists
          )
      else
        name = ActiveRecord::Base.wildcard("courses.name", search_term)
        code = ActiveRecord::Base.wildcard("courses.course_code", search_term)
        or_clause = Course.where(code).or(Course.where(name))

        if search_term =~ Api::ID_REGEX && Api::MAX_ID_RANGE.cover?(search_term.to_i)
          or_clause = Course.where(id: search_term).or(or_clause)
        end

        if @account.grants_any_right?(@current_user, :read_sis, :manage_sis)
          sis_source = ActiveRecord::Base.wildcard("courses.sis_source_id", search_term)
          or_clause = or_clause.or(Course.where(sis_source))
        end

        @courses = @courses.merge(or_clause)
      end
    end

    includes = Set.new(Array(params[:include]))
    # We only want to return the permissions for single courses and not lists of courses.
    # sections, needs_grading_count, and total_score not valid as enrollments are needed
    includes -= %w[permissions sections needs_grading_count total_scores]
    all_precalculated_permissions = nil

    page_opts = { total_entries: nil }
    if includes.include?("ui_invoked")
      page_opts = {} # let Folio calculate total entries
      includes.delete("ui_invoked")
    end

    GuardRail.activate(:secondary) do
      @courses = Api.paginate(@courses, self, api_v1_account_courses_url, page_opts)

      ActiveRecord::Associations.preload(@courses, [:account, :root_account, { course_account_associations: :account }])
      preload_teachers(@courses) if includes.include?("teachers")
      preload_teachers(@courses) if includes.include?("active_teachers")
      ActiveRecord::Associations.preload(@courses, [:enrollment_term]) if includes.include?("term") || includes.include?("concluded")

      if includes.include?("total_students")
        student_counts = StudentEnrollment.shard(@account.shard).not_fake.where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')")
                                          .where(course_id: @courses).group(:course_id).distinct.count(:user_id)
        @courses.each { |c| c.student_count = student_counts[c.id] || 0 }
      end
      all_precalculated_permissions = @current_user.precalculate_permissions_for_courses(@courses, [:read_sis, :manage_sis])
    end

    render json: @courses.map { |c|
                   course_json(c,
                               @current_user,
                               session,
                               includes,
                               nil,
                               precalculated_permissions: all_precalculated_permissions&.dig(c.global_id),
                               prefer_friendly_name: false)
                 }
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
            @account.errors.add(:unauthorized, t("Cannot set sis_account_id on a root_account."))
          else
            @account.errors.add(:unauthorized, t("To change sis_account_id the user must have manage_sis permission."))
          end
          unauthorized = true
        end
      end

      if params[:account][:services] && authorized_action(@account, @current_user, :manage_account_settings)
        params[:account][:services].slice(*Account.services_exposed_to_ui_hash(nil, @current_user, @account).keys).each do |key, value|
          @account.set_service_availability(key, value_to_boolean(value))
        end
        includes << "services"
        params[:account].delete :services
      end

      # Set default Dashboard View
      set_default_dashboard_view(params.dig(:account, :settings)&.delete(:default_dashboard_view))
      unauthorized = true if set_course_template == :unauthorized

      # account settings (:manage_account_settings)
      account_settings = account_params.slice(:name, :default_time_zone, :settings)
      unless account_settings.empty?
        if @account.grants_right?(@current_user, session, :manage_account_settings)
          if account_settings[:settings]
            account_settings[:settings].slice!(*permitted_api_account_settings)
            ensure_sis_max_name_length_value!(account_settings)
          end
          @account.errors.add(:name, t(:account_name_required, "The account name cannot be blank")) if account_params.key?(:name) && account_params[:name].blank?
          @account.errors.add(:default_time_zone, t(:unrecognized_time_zone, "'%{timezone}' is not a recognized time zone", timezone: account_params[:default_time_zone])) if account_params.key?(:default_time_zone) && ActiveSupport::TimeZone.new(account_params[:default_time_zone]).nil?
        else
          account_settings.each_key { |k| @account.errors.add(k.to_sym, t(:cannot_manage_account, "You are not allowed to manage account settings")) }
          unauthorized = true
        end
      end

      param_settings = params.dig(:account, :settings)
      microsoft_sync_settings = param_settings&.permit(*MicrosoftSync::SettingsValidator::SYNC_SETTINGS)
      MicrosoftSync::SettingsValidator.new(microsoft_sync_settings, @account).validate_and_save

      # quotas (:manage_account_quotas)
      quota_settings = account_params.slice(:default_storage_quota_mb,
                                            :default_user_storage_quota_mb,
                                            :default_group_storage_quota_mb)
      unless quota_settings.empty?
        if @account.grants_right?(@current_user, session, :manage_storage_quotas)
          %i[default_storage_quota_mb default_user_storage_quota_mb default_group_storage_quota_mb].each do |quota_type|
            next unless quota_settings.key?(quota_type)

            quota_value = quota_settings[quota_type].to_s.strip
            if INTEGER_REGEX.match?(quota_value.to_s)
              @account.errors.add(quota_type, t(:quota_must_be_positive, "Value must be positive")) if quota_value.to_i < 0
              @account.errors.add(quota_type, t(:quota_too_large, "Value too large")) if quota_value.to_i >= (2**62) / 1.megabytes
            else
              @account.errors.add(quota_type, t(:quota_integer_required, "An integer value is required"))
            end
          end
        else
          quota_settings.each_key { |k| @account.errors.add(k.to_sym, t(:cannot_manage_quotas, "You are not allowed to manage quota settings")) }
          unauthorized = true
        end
      end

      if unauthorized
        # Attempt to modify something without sufficient permissions
        render json: @account.errors, status: :unauthorized
      else
        success = @account.errors.empty?
        success &&= @account.update(account_settings.merge(quota_settings)) rescue false

        if success
          # Successfully completed
          update_user_dashboards
          render json: account_json(@account, @current_user, session, includes)
        else
          # Failed (hopefully with errors)
          render json: @account.errors, status: :bad_request
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
  # @argument account[course_template_id] [Integer]
  #   The ID of a course to be used as a template for all newly created courses.
  #   Empty means to inherit the setting from parent account, 0 means to not
  #   use a template even if a parent account has one set. The course must be
  #   marked as a template.
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
  # @argument account[settings][microsoft_sync_enabled] [Boolean]
  #   Determines whether this account has Microsoft Teams Sync enabled or not.
  #
  #   Note that if you are altering Microsoft Teams sync settings you must enable
  #   the Microsoft Group enrollment syncing feature flag. In addition, if you are enabling
  #   Microsoft Teams sync, you must also specify a tenant, login attribute, and a remote attribute.
  #   Specifying a suffix to use is optional.
  #
  # @argument account[settings][microsoft_sync_tenant]
  #   The tenant this account should use when using Microsoft Teams Sync.
  #   This should be an Azure Active Directory domain name.
  #
  # @argument account[settings][microsoft_sync_login_attribute]
  #   The attribute this account should use to lookup users when using Microsoft Teams Sync.
  #   Must be one of "sub", "email", "oid", "preferred_username", or "integration_id".
  #
  # @argument account[settings][microsoft_sync_login_attribute_suffix]
  #   A suffix that will be appended to the result of the login attribute when associating
  #   Canvas users with Microsoft users. Must be under 255 characters and contain no whitespace.
  #   This field is optional.
  #
  # @argument account[settings][microsoft_sync_remote_attribute]
  #   The Active Directory attribute to use when associating Canvas users with Microsoft users.
  #   Must be one of "mail", "mailNickname", or "userPrincipalName".
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
  # @argument account[settings][conditional_release][value] [Boolean]
  #   Enable or disable individual learning paths for students based on assessment
  #
  # @argument account[settings][conditional_release][locked] [Boolean]
  #   Lock this setting for sub-accounts and courses
  #
  # @argument override_sis_stickiness [boolean]
  #   Default is true. If false, any fields containing “sticky” changes will not be updated.
  #   See SIS CSV Format documentation for information on which fields can have SIS stickiness
  #
  # @argument account[settings][lock_outcome_proficiency][value] [Boolean]
  #   [DEPRECATED] Restrict instructors from changing mastery scale
  #
  # @argument account[lock_outcome_proficiency][locked] [Boolean]
  #   [DEPRECATED] Lock this setting for sub-accounts and courses
  #
  # @argument account[settings][lock_proficiency_calculation][value] [Boolean]
  #   [DEPRECATED] Restrict instructors from changing proficiency calculation method
  #
  # @argument account[lock_proficiency_calculation][locked] [Boolean]
  #   [DEPRECATED] Lock this setting for sub-accounts and courses
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
              encrypted_slack_key, salt = Canvas::Security.encrypt_password(slack_api_key.to_s, "instructure_slack_encrypted_key")
              @account.settings[:encrypted_slack_key] = encrypted_slack_key
              @account.settings[:encrypted_slack_key_salt] = salt
            end
          end
        end

        pronouns = params[:account].delete :pronouns
        if pronouns && !@account.site_admin? && @account.root_account?
          @account.pronouns = pronouns
        end

        custom_help_links = params[:account].delete :custom_help_links
        if custom_help_links
          sorted_help_links = custom_help_links.to_unsafe_h.select { |_k, h| h["state"] != "deleted" && h["state"] != "new" }.sort_by { |k, _h| k.to_i }
          sorted_help_links.map! do |index_with_hash|
            hash = index_with_hash[1].to_hash.with_indifferent_access
            hash.delete("state")
            hash.assert_valid_keys %w[text subtext url available_to type id is_featured is_new feature_headline]
            hash
          end
          @account.settings[:custom_help_links] = @account.help_links_builder.process_links_before_save(sorted_help_links)
          @account.settings[:new_custom_help_links] = true
        end

        params[:account][:turnitin_host] = validated_turnitin_host(params[:account][:turnitin_host])
        allow_sis_import = params[:account].delete :allow_sis_import
        params[:account].delete :default_user_storage_quota_mb unless @account.root_account? && !@account.site_admin?
        unless @account.grants_right? @current_user, :manage_storage_quotas
          %i[storage_quota
             default_storage_quota
             default_storage_quota_mb
             default_user_storage_quota
             default_user_storage_quota_mb
             default_group_storage_quota
             default_group_storage_quota_mb].each { |key| params[:account].delete key }
        end
        if params[:account][:services]
          params[:account][:services].slice(*Account.services_exposed_to_ui_hash(nil, @current_user, @account).keys).each do |key, value|
            @account.set_service_availability(key, value == "1")
          end
          params[:account].delete :services
        end

        # If the setting is present (update is called from 2 different settings forms, one for notifications)
        if params[:account][:settings] && params[:account][:settings][:outgoing_email_default_name_option].present? &&
           params[:account][:settings][:outgoing_email_default_name_option] == "default"
          # If set to default, remove the custom name so it doesn't get saved
          params[:account][:settings][:outgoing_email_default_name] = ""
        end

        emoji_deny_list = params[:account][:settings].try(:delete, :emoji_deny_list)
        if @account.feature_allowed?(:submission_comment_emojis) &&
           @account.primary_settings_root_account? &&
           !@account.site_admin?
          @account.settings[:emoji_deny_list] = emoji_deny_list
        end

        if @account.grants_right?(@current_user, :manage_site_settings)
          google_docs_domain = params[:account][:settings].try(:delete, :google_docs_domain)
          if @account.feature_enabled?(:google_docs_domain_restriction) &&
             @account.root_account? &&
             !@account.site_admin?
            @account.settings[:google_docs_domain] = google_docs_domain.presence
          end

          @account.allow_sis_import = allow_sis_import if allow_sis_import && @account.root_account?
          if @account.site_admin? && params[:account][:settings]
            # these shouldn't get set for the site admin account
            params[:account][:settings].delete(:enable_alerts)
            params[:account][:settings].delete(:enable_eportfolios)
            params[:account][:settings].delete(:include_integration_ids_in_gradebook_exports)
          end
        else
          # must have :manage_site_settings to update these
          %i[admins_can_change_passwords
             admins_can_view_notifications
             enable_alerts
             enable_eportfolios
             enable_profiles
             enable_turnitin
             include_integration_ids_in_gradebook_exports
             show_scheduler
             global_includes
             gmail_domain
             limit_parent_app_web_access].each do |key|
            params[:account][:settings].try(:delete, key)
          end
        end

        # For each inheritable setting, if the value for the account is the same as the inheritable value,
        # remove it from the settings hash on the account
        Account.inheritable_settings.each do |setting|
          # when changing k5 settings on an account, the value gets saved to the root account and special
          # locking rules apply, so don't remove it from the update params here
          next if K5::EnablementService::K5_SETTINGS.include? setting
          next unless params.dig(:account, :settings)
          next if !Account.account_settings_options[setting].key?(:boolean) && params.dig(:account, :settings, setting) != @account.parent_account&.send(setting)
          next if value_to_boolean(params.dig(:account, :settings, setting, :locked))
          next if value_to_boolean(params.dig(:account, :settings, setting, :value)) != @account.parent_account&.send(setting)&.[](:value)

          params[:account][:settings].delete(setting)
          @account.settings.delete(setting)
        end

        if params[:account][:settings]&.key?(:trusted_referers) &&
           (trusted_referers = params[:account][:settings].delete(:trusted_referers)) &&
           @account.root_account?
          @account.trusted_referers = trusted_referers
        end

        # don't accidentally turn the default help link name into a custom one and thereby break i18n
        help_link_name = params.dig(:account, :settings, :help_link_name)
        params[:account][:settings][:help_link_name] = nil if help_link_name == default_help_link_name

        ensure_sis_max_name_length_value!(params[:account]) if params[:account][:settings]

        if (sis_id = params[:account].delete(:sis_source_id)) &&
           !@account.root_account? && sis_id != @account.sis_source_id &&
           @account.root_account.grants_right?(@current_user, session, :manage_sis)
          @account.sis_source_id = sis_id.presence
        end

        @account.process_external_integration_keys(params[:account][:external_integration_keys], @current_user)

        can_edit_email = params[:account][:settings].try(:delete, :edit_institution_email)
        if @account.root_account? && !can_edit_email.nil?
          @account[:settings][:edit_institution_email] = value_to_boolean(can_edit_email)
        end

        remove_ip_filters = params[:account].delete(:remove_ip_filters)
        params[:account][:ip_filters] = [] if remove_ip_filters

        enable_k5 = params.dig(:account, :settings, :enable_as_k5_account, :value)
        use_classic_font = params.dig(:account, :settings, :use_classic_font_in_k5, :value)
        K5::EnablementService.new(@account).set_k5_settings(value_to_boolean(enable_k5), value_to_boolean(use_classic_font)) unless enable_k5.nil?

        # validate/normalize default due time parameter
        if (default_due_time = params.dig(:account, :settings, :default_due_time, :value))
          params[:account][:settings][:default_due_time][:value] = normalize_due_time(default_due_time)
        end

        # Set default Dashboard view
        set_default_dashboard_view(params.dig(:account, :settings)&.delete(:default_dashboard_view))
        set_course_template

        if @account.update(strong_account_params)
          update_user_dashboards
          format.html { redirect_to account_settings_url(@account) }
          format.json { render json: @account }
        else
          flash[:error] = t(:update_failed_notice, "Account settings update failed")
          format.html { redirect_to account_settings_url(@account) }
          format.json { render json: @account.errors, status: :bad_request }
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
        @last_complete_reports = AccountReport.from("unnest('{#{@available_reports.keys.join(",")}}'::text[]) report_types (name),
                LATERAL (#{scope.complete.to_sql}) account_reports ")
                                              .order("report_types.name")
                                              .preload(:attachment)
                                              .index_by(&:report_type)
        @last_reports = AccountReport.from("unnest('{#{@available_reports.keys.join(",")}}'::text[]) report_types (name),
                LATERAL (#{scope.to_sql}) account_reports ")
                                     .order("report_types.name")
                                     .index_by(&:report_type)
      end
      render layout: false
    end
  end

  def terms_of_service_custom_content
    TermsOfService.ensure_terms_for_account(@domain_root_account)
    render plain: @domain_root_account.terms_of_service.terms_of_service_content&.content
  end

  def settings
    if authorized_action(@account, @current_user, :read_as_admin)
      @account_users = @account.account_users.active
      @account_user_permissions_cache = AccountUser.create_permissions_cache(@account_users, @current_user, session)
      ActiveRecord::Associations.preload(@account_users, user: :communication_channels)
      order_hash = {}
      @account.available_account_roles.each_with_index do |role, idx|
        order_hash[role.id] = idx
      end
      @account_users = @account_users.select(&:user).sort_by { |au| [order_hash[au.role_id] || CanvasSort::Last, Canvas::ICU.collation_key(au.user.sortable_name)] }
      @alerts = @account.alerts

      @account_roles = @account.available_account_roles.sort_by(&:display_sort_index).map { |role| { id: role.id, label: role.label } }
      @course_roles = @account.available_course_roles.sort_by(&:display_sort_index).map { |role| { id: role.id, label: role.label } }

      @announcements = @account.announcements.order(created_at: "desc").paginate(page: params[:page], per_page: 10)
      @external_integration_keys = ExternalIntegrationKey.indexed_keys_for(@account)

      course_creation_settings = {}
      if @account.root_account? && !@account.site_admin?
        course_creation_settings.merge!({
                                          teachers_can_create_courses: @account.teachers_can_create_courses?,
                                          students_can_create_courses: @account.students_can_create_courses?,
                                          no_enrollments_can_create_courses: @account.no_enrollments_can_create_courses?,
                                          teachers_can_create_courses_anywhere: @account.teachers_can_create_courses_anywhere?,
                                          students_can_create_courses_anywhere: @account.students_can_create_courses_anywhere?,
                                        })
      end

      js_permissions = {
        manage_feature_flags: @account.grants_right?(@current_user, session, :manage_feature_flags)
      }
      if @account.root_account.feature_enabled?(:granular_permissions_manage_lti)
        js_permissions[:add_tool_manually] = @account.grants_right?(@current_user, session, :manage_lti_add)
        js_permissions[:edit_tool_manually] = @account.grants_right?(@current_user, session, :manage_lti_edit)
        js_permissions[:delete_tool_manually] = @account.grants_right?(@current_user, session, :manage_lti_delete)
      else
        js_permissions[:create_tool_manually] = @account.grants_right?(@current_user, session, :create_tool_manually)
      end
      js_env({
               APP_CENTER: { enabled: Canvas::Plugin.find(:app_center).enabled? },
               LTI_LAUNCH_URL: account_tool_proxy_registration_path(@account),
               EXTERNAL_TOOLS_CREATE_URL: url_for(controller: :external_tools, action: :create, account_id: @context.id),
               TOOL_CONFIGURATION_SHOW_URL: account_show_tool_configuration_url(account_id: @context.id, developer_key_id: ":developer_key_id"),
               MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED: @account.root_account.feature_enabled?(:membership_service_for_lti_tools),
               CONTEXT_BASE_URL: "/accounts/#{@context.id}",
               MASKED_APP_CENTER_ACCESS_TOKEN: @account.settings[:app_center_access_token].try(:[], 0...5),
               PERMISSIONS: js_permissions,
               CSP: {
                 enabled: @account.csp_enabled?,
                 inherited: @account.csp_inherited?,
                 settings_locked: @account.csp_locked?,
               },
               MICROSOFT_SYNC: {
                 CLIENT_ID: MicrosoftSync::LoginService.client_id,
                 REDIRECT_URI: MicrosoftSync::LoginService::REDIRECT_URI,
                 BASE_URL: MicrosoftSync::LoginService::BASE_URL
               },
               COURSE_CREATION_SETTINGS: course_creation_settings,
               EMOJI_DENY_LIST: @account.root_account.settings[:emoji_deny_list]
             })
      js_env(edit_help_links_env, true)
    end
  end

  # Admin Tools page controls
  # => Log Auditing
  # => Add/Change Quota
  # = Restoring Content
  def admin_tools
    unless @account.can_see_admin_tools_tab?(@current_user)
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

    js_env PERMISSIONS: {
      restore_course: @account.grants_right?(@current_user, session, :undelete_courses),
      restore_user: @account.grants_right?(@current_user, session, :manage_user_logins),
      # Permission caching issue makes explicitly checking the account setting
      # an easier option.
      view_messages: (@account.settings[:admins_can_view_notifications] &&
                       @account.grants_right?(@current_user, session, :view_notifications)) ||
                     Account.site_admin.grants_right?(@current_user, :read_messages),
      logging:
    }
    js_env bounced_emails_admin_tool: @account.grants_right?(@current_user, session, :view_bounced_emails)
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
      flash[:notice] = t(:user_deleted_message, "%{username} successfully deleted", username: @user.name)
      respond_to do |format|
        format.html { redirect_to account_users_url(@account) }
        format.json { render json: @user || {} }
      end
    else
      render_unauthorized_action
    end
  end

  # @API Restore a deleted user from a root account
  #
  # Restore a user record along with the most recently deleted pseudonym
  # from a Canvas root account.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/3/users/5/restore \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  #       -X PUT
  #
  # @returns User
  def restore_user
    raise ActiveRecord::RecordNotFound unless @account.root_account?

    user = api_find(User, params[:user_id])
    raise ActiveRecord::RecordNotFound if user.try(:frd_deleted?)

    pseudonym = user && @account.pseudonyms.where(user_id: user).order(deleted_at: :desc).first!

    is_permissible =
      pseudonym.account.grants_right?(@current_user, :manage_user_logins) &&
      pseudonym.user.has_subset_of_account_permissions?(@current_user, user.account)
    return render_unauthorized_action unless is_permissible

    if @account.pseudonyms.where(user_id: user).active.any? && !user.deleted?
      return render json: { errors: "User not deleted" }, status: :bad_request
    end

    # this is a no-op if the user was deleted from the account profile page
    user.update!(workflow_state: "registered") if user.deleted?
    pseudonym.update!(workflow_state: "active")
    pseudonym.clear_permissions_cache(user)
    user.update_account_associations
    user.clear_caches
    render json: user_json(user, @current_user, session, [], @account)
  end

  def eportfolio_moderation
    if authorized_action(@account, @current_user, :moderate_user_content)
      spam_status_order = "CASE spam_status WHEN 'flagged_as_possible_spam' THEN 0 WHEN 'marked_as_spam' THEN 1 WHEN 'marked_as_safe' THEN 2 ELSE 3 END"
      @eportfolios = Eportfolio.active.preload(:user)
                               .joins(:user)
                               .joins("JOIN #{UserAccountAssociation.quoted_table_name} ON eportfolios.user_id = user_account_associations.user_id AND user_account_associations.account_id = #{@account.id}")
                               .where(spam_status: %w[flagged_as_possible_spam marked_as_spam marked_as_safe])
                               .where(Eportfolio.where("user_id = users.id").where(spam_status: ["flagged_as_possible_spam", "marked_as_spam"]).arel.exists)
                               .merge(User.active)
                               .order(Arel.sql(spam_status_order), Arel.sql("eportfolios.public DESC NULLS LAST"), updated_at: :desc)
                               .paginate(per_page: EPORTFOLIO_MODERATION_PER_PAGE, page: params[:page])
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
        render json: { success: turnitin.testSettings }
      rescue
        render json: { success: false }
      end
    end
  end

  def statistics
    if authorized_action(@account, @current_user, :view_statistics)
      add_crumb(t(:crumb_statistics, "Statistics"), statistics_account_url(@account))
      if @account.grants_right?(@current_user, :read_course_list)
        @recently_started_courses = @account.associated_courses.active.recently_started
        @recently_ended_courses = @account.associated_courses.active.recently_ended
        @recently_created_courses = @account.associated_courses.active.recently_created
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
        format.json { render json: @items }
        format.csv do
          res = CSV.generate do |csv|
            csv << ["Timestamp", "Value"]
            @items.each do |item|
              csv << [item[0] / 1000, item[1]]
            end
          end
          cancel_cache_buster
          # TODO: i18n
          send_data(
            res,
            type: "text/csv",
            filename: "#{params[:attribute].titleize} Report for #{@account.name}.csv",
            disposition: "attachment"
          )
        end
      end
    end
  end

  def avatars
    is_authorized = if @domain_root_account.feature_enabled?(:granular_permissions_manage_users)
                      authorized_action(@account, @current_user, :allow_course_admin_actions)
                    else
                      authorized_action(@account, @current_user, :manage_admin_users)
                    end

    if is_authorized
      @users = @account.all_users
      @avatar_counts = {
        all: format_avatar_count(@users.with_avatar_state("any").count),
        reported: format_avatar_count(@users.with_avatar_state("reported").count),
        re_reported: format_avatar_count(@users.with_avatar_state("re_reported").count),
        submitted: format_avatar_count(@users.with_avatar_state("submitted").count)
      }
      if params[:avatar_state]
        @users = @users.with_avatar_state(params[:avatar_state])
        @avatar_state = params[:avatar_state]
      elsif @domain_root_account && @domain_root_account.settings[:avatars] == "enabled_pending"
        @users = @users.with_avatar_state("submitted")
        @avatar_state = "submitted"
      else
        @users = @users.with_avatar_state("reported")
        @avatar_state = "reported"
      end
      @users = Api.paginate(@users, self, account_avatars_url)
    end
  end

  def sis_import
    if authorized_action(@account, @current_user, [:import_sis, :manage_sis])
      return redirect_to account_settings_url(@account) if !@account.allow_sis_import || !@account.root_account?

      @current_batch = @account.current_sis_batch
      @last_batch = @account.sis_batches.order("created_at DESC").first
      @terms = @account.enrollment_terms.active
      respond_to do |format|
        format.html
        format.json { render json: @current_batch }
      end
    end
  end

  def courses_redirect
    redirect_to course_url(params[:id])
  end

  def course_user_search
    return unless authorized_action(@account, @current_user, :read)

    can_read_course_list = @account.grants_right?(@current_user, session, :read_course_list)
    can_read_roster = @account.grants_right?(@current_user, session, :read_roster)

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
    add_crumb "", "?" # the text for this will be set by javascript
    js_permissions = {
      can_read_course_list:,
      can_read_roster:,
      can_create_courses: @account.grants_any_right?(@current_user, session, :manage_courses, :create_courses),
      can_create_users: @account.root_account.grants_right?(@current_user, session, :manage_user_logins),
      analytics: @account.service_enabled?(:analytics),
      can_read_sis: @account.grants_right?(@current_user, session, :read_sis),
      can_masquerade: @account.grants_right?(@current_user, session, :become_user),
      can_message_users: @account.grants_right?(@current_user, session, :send_messages),
      can_edit_users: @account.grants_any_right?(@current_user, session, :manage_user_logins),
      can_manage_groups: # access to view account-level user groups, People --> hamburger menu
        @account.grants_any_right?(
          @current_user,
          session,
          :manage_groups,
          *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS
        ),
      can_create_enrollments: @account.grants_any_right?(@current_user, session, *add_enrollment_permissions(@account))
    }
    if @account.root_account.feature_enabled?(:temporary_enrollments)
      js_permissions[:can_add_temporary_enrollments] =
        @account.grants_right?(@current_user, session, :temporary_enrollments_add)
      js_permissions[:can_edit_temporary_enrollments] =
        @account.grants_right?(@current_user, session, :temporary_enrollments_edit)
      js_permissions[:can_delete_temporary_enrollments] =
        @account.grants_right?(@current_user, session, :temporary_enrollments_delete)
      js_permissions[:can_view_temporary_enrollments] =
        @account.grants_any_right?(@current_user, session, *RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS)
    end
    if @account.root_account.feature_enabled?(:granular_permissions_manage_users)
      js_permissions[:can_allow_course_admin_actions] = @account.grants_right?(@current_user, session, :allow_course_admin_actions)
      js_permissions[:can_add_ta] = @account.grants_right?(@current_user, session, :add_ta_to_course)
      js_permissions[:can_add_student] = @account.grants_right?(@current_user, session, :add_student_to_course)
      js_permissions[:can_add_teacher] = @account.grants_right?(@current_user, session, :add_teacher_to_course)
      js_permissions[:can_add_designer] = @account.grants_right?(@current_user, session, :add_designer_to_course)
      js_permissions[:can_add_observer] = @account.grants_right?(@current_user, session, :add_observer_to_course)
    else
      js_permissions[:can_manage_admin_users] = @account.grants_right?(@current_user, session, :manage_admin_users)
    end
    js_env({
             ROOT_ACCOUNT_NAME: @account.root_account.name, # used in AddPeopleApp modal
             ROOT_ACCOUNT_ID: @account.root_account.id,
             customized_login_handle_name: @account.root_account.customized_login_handle_name,
             delegated_authentication: @account.root_account.delegated_authentication?,
             SHOW_SIS_ID_IN_NEW_USER_FORM: @account.root_account.allow_sis_import && @account.root_account.grants_right?(@current_user, session, :manage_sis),
             PERMISSIONS: js_permissions
           })
    render html: "", layout: true
  end

  def users
    get_context
    unless params.key?(:term)
      @account ||= @context
      return course_user_search
    end
    return unless authorized_action(@context, @current_user, :read_roster)

    @root_account = @context.root_account
    @query = params[:term]
    GuardRail.activate(:secondary) do
      @users = @context.users_name_like(@query)
      @users = @users.paginate(page: params[:page])

      cancel_cache_buster
      expires_in 30.minutes
      render(json: @users.map { |u| { label: u.name, id: u.id } })
    end
  end

  def build_course_stats
    courses_to_fetch_users_for = @courses

    templates = MasterCourses::MasterTemplate.active.for_full_course.where(course_id: @courses).to_a
    if templates.any?
      MasterCourses::MasterTemplate.preload_index_data(templates)
      @master_template_index = templates.index_by(&:course_id)
      courses_to_fetch_users_for = courses_to_fetch_users_for.reject { |c| @master_template_index[c.id] } # don't fetch the counts for the master/blueprint courses
    end

    teachers = TeacherEnrollment.for_courses_with_user_name(courses_to_fetch_users_for).where.not(enrollments: { workflow_state: %w[rejected deleted] })
    course_to_student_counts = StudentEnrollment.student_in_claimed_or_available.where(course_id: courses_to_fetch_users_for).group(:course_id).distinct.count(:user_id)
    courses_to_teachers = teachers.each_with_object({}) do |teacher, result|
      result[teacher.course_id] ||= []
      result[teacher.course_id] << teacher
    end
    courses_to_fetch_users_for.each do |course|
      course.student_count = course_to_student_counts[course.id] || 0
      course_teachers = courses_to_teachers[course.id] || []
      course.teacher_names = course_teachers.uniq(&:user_id).map(&:user_name)
    end
  end
  protected :build_course_stats

  # TODO: Refactor add_account_user and remove_account_user actions into
  # AdminsController. see https://redmine.instructure.com/issues/6634
  def add_account_user
    if (role_id = params[:role_id])
      role = Role.get_role_by_id(role_id)
      raise ActiveRecord::RecordNotFound unless role
    else
      role = Role.get_built_in_role("AccountAdmin", root_account_id: @context.resolved_root_account_id)
    end

    list = UserList.new(params[:user_list],
                        root_account: @context.root_account,
                        search_method: @context.user_list_search_mode_for(@current_user),
                        current_user: @current_user)
    users = list.users
    admins = users.map do |user|
      admin = @context.account_users.where(user_id: user.id, role_id: role.id).first_or_initialize
      admin.user = user
      admin.workflow_state = "active"
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

      { enrollment: {
        id: admin.id,
        name: admin.user.name,
        role_id: admin.role_id,
        membership_type: AccountUser.readable_type(admin.role.name),
        workflow_state: "active",
        user_id: admin.user.id,
        type: "admin",
        email: admin.user.email
      } }
    end
    render json: account_users
  end

  def remove_account_user
    admin = @context.account_users.find(params[:id])
    if authorized_action(admin, @current_user, :destroy)
      admin.destroy
      respond_to do |format|
        format.html { redirect_to account_settings_url(@context, anchor: "tab-users") }
        format.json { render json: admin }
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

  def set_default_dashboard_view(new_view)
    if new_view != @account.default_dashboard_view && authorized_action(@account, @current_user, :manage_account_settings)
      # NOTE: Only _sets_ the property. It's up to the caller to `save` it
      @account.default_dashboard_view = new_view
    end
  end

  def set_course_template
    return unless params[:account]&.key?(:course_template_id)

    param = params[:account][:course_template_id]
    if param.blank?
      return if @account.course_template_id.nil?
      return :unauthorized unless @account.grants_any_right?(@current_user, :delete_course_template, :edit_course_template)

      @account.course_template_id = nil
    elsif param.to_s == "0"
      return if @account.course_template_id == 0
      return :unauthorized unless @account.grants_any_right?(@current_user, :delete_course_template, :edit_course_template)

      @account.course_template_id = 0
    else
      return if @account.course_template_id == param.to_i

      course = api_find(@account.root_account.all_courses.templates, param)

      return :unauthorized if @account.course_template_id.nil? && !@account.grants_any_right?(@current_user, :add_course_template, :edit_course_template)
      return :unauthorized if !@account.course_template_id.nil? && !@account.grants_right?(@current_user, :edit_course_template)

      @account.course_template = course
    end
    nil
  end

  def update_user_dashboards
    return unless value_to_boolean(params.dig(:account, :settings, :force_default_dashboard_view))

    @account.update_user_dashboards
  end

  def account_calendar_settings
    return unless authorized_action(@account, @current_user, :manage_account_calendar_visibility)

    title = t("Account Calendars")
    @page_title = title
    add_crumb(title)
    set_active_tab "account_calendars"
    @current_user.add_to_visited_tabs("account_calendars")
    js_env
    css_bundle :account_calendar_settings
    js_bundle :account_calendar_settings
    InstStatsd::Statsd.increment("account_calendars.settings.visit")
    render html: '<div id="account-calendar-settings-container"></div>'.html_safe, layout: true
  end

  def format_avatar_count(count = 0)
    (count > 99) ? "99+" : count
  end
  private :format_avatar_count

  private

  def ensure_sis_max_name_length_value!(account_settings)
    sis_name_length_setting = account_settings[:settings][:sis_assignment_name_length_input]
    return if sis_name_length_setting.nil?

    value = sis_name_length_setting[:value]
    sis_name_length_setting[:value] = if value.to_i.to_s == value.to_s && value.to_i <= SIS_ASSINGMENT_NAME_LENGTH_DEFAULT && value.to_i >= 0
                                        value
                                      else
                                        SIS_ASSINGMENT_NAME_LENGTH_DEFAULT
                                      end
  end

  PERMITTED_SETTINGS_FOR_UPDATE = [:admins_can_change_passwords,
                                   :admins_can_view_notifications,
                                   :allow_additional_email_at_registration,
                                   :allow_invitation_previews,
                                   :allow_sending_scores_in_emails,
                                   :author_email_in_notifications,
                                   :canvadocs_prefer_office_online,
                                   :can_add_pronouns,
                                   :can_change_pronouns,
                                   :consortium_parent_account,
                                   :consortium_can_create_own_accounts,
                                   :shard_per_account,
                                   :consortium_autocreate_web_of_trust,
                                   :consortium_autocreate_reverse_trust,
                                   :default_storage_quota,
                                   :default_storage_quota_mb,
                                   :default_group_storage_quota,
                                   :default_group_storage_quota_mb,
                                   :default_user_storage_quota,
                                   :default_user_storage_quota_mb,
                                   :default_time_zone,
                                   :disable_post_to_sis_when_grading_period_closed,
                                   :edit_institution_email,
                                   :enable_alerts,
                                   :enable_eportfolios,
                                   :enable_course_catalog,
                                   :limit_parent_app_web_access,
                                   { allow_gradebook_show_first_last_names: [:value] }.freeze,
                                   { enable_offline_web_export: [:value] }.freeze,
                                   { disable_rce_media_uploads: [:value] }.freeze,
                                   :enable_profiles,
                                   :enable_gravatar,
                                   :enable_turnitin,
                                   :equella_endpoint,
                                   :equella_teaser,
                                   :external_notification_warning,
                                   :global_includes,
                                   :google_docs_domain,
                                   :help_link_icon,
                                   :help_link_name,
                                   :include_integration_ids_in_gradebook_exports,
                                   :include_students_in_global_survey,
                                   :kill_joy,
                                   :license_type,
                                   :suppress_notifications,
                                   { lock_all_announcements: [:value, :locked] }.freeze,
                                   :login_handle_name,
                                   :mfa_settings,
                                   :no_enrollments_can_create_courses,
                                   :mobile_qr_login_is_enabled,
                                   :microsoft_sync_enabled,
                                   :microsoft_sync_tenant,
                                   :microsoft_sync_login_attribute,
                                   :microsoft_sync_login_attribute_suffix,
                                   :microsoft_sync_remote_attribute,
                                   :open_registration,
                                   :outgoing_email_default_name,
                                   :prevent_course_availability_editing_by_teachers,
                                   :prevent_course_renaming_by_teachers,
                                   :restrict_quiz_questions,
                                   { restrict_student_future_listing: [:value, :locked] }.freeze,
                                   { restrict_student_future_view: [:value, :locked] }.freeze,
                                   { restrict_student_past_view: [:value, :locked] }.freeze,
                                   :self_enrollment,
                                   :show_scheduler,
                                   :sis_app_token,
                                   :sis_app_url,
                                   { sis_assignment_name_length: [:value] }.freeze,
                                   { sis_assignment_name_length_input: [:value] }.freeze,
                                   { sis_default_grade_export: [:value, :locked] }.freeze,
                                   :sis_name,
                                   { sis_require_assignment_due_date: [:value] }.freeze,
                                   { sis_syncing: [:value, :locked] }.freeze,
                                   :strict_sis_check,
                                   :storage_quota,
                                   :students_can_create_courses,
                                   :sub_account_includes,
                                   :teachers_can_create_courses,
                                   :trusted_referers,
                                   :turnitin_host,
                                   :turnitin_account_id,
                                   :users_can_edit_name,
                                   :users_can_edit_profile,
                                   :users_can_edit_comm_channels,
                                   { usage_rights_required: [:value, :locked] }.freeze,
                                   { restrict_quantitative_data: [:value, :locked] }.freeze,
                                   :app_center_access_token,
                                   :default_dashboard_view,
                                   :force_default_dashboard_view,
                                   :smart_alerts_threshold,
                                   :enable_push_notifications,
                                   :teachers_can_create_courses_anywhere,
                                   :students_can_create_courses_anywhere,
                                   { default_due_time: [:value] }.freeze,
                                   { conditional_release: [:value, :locked] }.freeze,
                                   { allow_observers_in_appointment_groups: [:value] }.freeze,].freeze

  def permitted_account_attributes
    [:name,
     :turnitin_account_id,
     :turnitin_shared_secret,
     :include_crosslisted_courses,
     :turnitin_host,
     :turnitin_comments,
     :turnitin_pledge,
     :turnitin_originality,
     :default_time_zone,
     :parent_account,
     :default_storage_quota,
     :default_storage_quota_mb,
     :storage_quota,
     :default_locale,
     :default_user_storage_quota_mb,
     :default_group_storage_quota_mb,
     :integration_id,
     :brand_config_md5,
     settings: PERMITTED_SETTINGS_FOR_UPDATE, ip_filters: strong_anything]
  end

  def permitted_api_account_settings
    %i[restrict_student_past_view
       restrict_student_future_view
       restrict_student_future_listing
       restrict_quantitative_data
       lock_all_announcements
       sis_assignment_name_length_input
       conditional_release]
  end

  def strong_account_params
    # i'm doing this instead of normal params because we do too much hackery to the weak params, especially in plugins
    # and it breaks when we enforce inherited weak parameters (because we're not actually editing request.parameters anymore)
    if params[:override_sis_stickiness] && !value_to_boolean(params[:override_sis_stickiness])
      params.require(:account).permit(*permitted_account_attributes - [*@account.stuck_sis_fields])
    else
      params.require(:account).permit(*permitted_account_attributes)
    end
  end

  def edit_help_links_env
    # @domain_root_account may be cached; load settings from @account to ensure they're up to date
    return {} unless @account == @domain_root_account

    {
      help_link_name: @account.settings[:help_link_name] || default_help_link_name,
      help_link_icon: @account.settings[:help_link_icon] || "help",
      CUSTOM_HELP_LINKS: @account.help_links || [],
      DEFAULT_HELP_LINKS: @account.help_links_builder.instantiate_links(@account.help_links_builder.default_links)
    }
  end

  def add_enrollment_permissions(context)
    if context.root_account.feature_enabled?(:granular_permissions_manage_users)
      %i[
        add_teacher_to_course
        add_ta_to_course
        add_designer_to_course
        add_student_to_course
        add_observer_to_course
      ]
    else
      [
        :manage_students,
        :manage_admin_users
      ]
    end
  end
end
