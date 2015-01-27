#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
#         "workflow_state": {
#           "description": "The state of the account. Can be 'active' or 'deleted'.",
#           "example": "active",
#           "type": "string"
#         }
#       }
#     }
#
class AccountsController < ApplicationController
  before_filter :require_user, :only => [:index]
  before_filter :reject_student_view_student
  before_filter :get_context

  include Api::V1::Account

  INTEGER_REGEX = /\A[+-]?\d+\z/

  # @API List accounts
  # List accounts that the current user can view or manage.  Typically,
  # students and even teachers will get an empty list in response, only
  # account admins can view the accounts that they are in.
  #
  # @returns [Account]
  def index
    respond_to do |format|
      format.html do
        @accounts = @current_user ? @current_user.all_accounts : []
      end
      format.json do
        if @current_user
          @accounts = Api.paginate(@current_user.all_paginatable_accounts, self, api_v1_accounts_url)
        else
          @accounts = []
        end
        ActiveRecord::Associations::Preloader.new(@accounts, :root_account).run
        render :json => @accounts.map { |a| account_json(a, @current_user, session, params[:includes] || [], false) }
      end
    end
  end

  # @API List accounts for course admins
  # List accounts that the current user can view through their admin course enrollments.
  # (Teacher, TA, or designer enrollments).
  # Only returns "id", "name", "workflow_state", "root_account_id" and "parent_account_id"
  #
  # @returns [Account]
  def course_accounts
    if @current_user
        course_accounts = BookmarkedCollection.wrap(Account::Bookmarker,
          Account.where(:id => Account.joins(:courses => :enrollments).merge(
            @current_user.enrollments.admin.except(:select)).
            select("accounts.id").uniq.with_each_shard.map(&:id))
        )
      @accounts = Api.paginate(course_accounts, self, api_v1_accounts_url)
    else
      @accounts = []
    end
    ActiveRecord::Associations::Preloader.new(@accounts, :root_account).run
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
        return redirect_to account_settings_url(@account) if @account.site_admin? || !@account.grants_right?(@current_user, :read_course_list)
        js_env(:ACCOUNT_COURSES_PATH => account_courses_path(@account, :format => :json))
        load_course_right_side
        @courses = @account.fast_all_courses(:term => @term, :limit => @maximum_courses_im_gonna_show, :hide_enrollmentless_courses => @hide_enrollmentless_courses)
        ActiveRecord::Associations::Preloader.new(@courses, :enrollment_term).run
        build_course_stats
      end
      format.json { render :json => account_json(@account, @current_user, session, params[:includes] || [],
                                                 !@account.grants_right?(@current_user, session, :manage)) }
    end
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

    ActiveRecord::Associations::Preloader.new(@accounts, [:root_account, :parent_account]).run
    render :json => @accounts.map { |a| account_json(a, @current_user, session, []) }
  end

  include Api::V1::Course

  # @API List active courses in an account
  # Retrieve the list of courses in this account.
  #
  # @argument with_enrollments [Boolean]
  #   If true, include only courses with at least one enrollment.  If false,
  #   include only courses with no enrollments.  If not present, do not filter
  #   on course enrollment status.
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
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"total_scores"|"term"|"course_progress"|"sections"|"storage_quota_used_mb"]
  #   - All explanations can be seen in the {api:CoursesController#index Course API index documentation}
  #
  # @returns [Course]
  def courses_api
    return unless authorized_action(@account, @current_user, :read)

    params[:state] ||= %w{created claimed available completed}
    params[:state] = %w{created claimed available completed deleted} if Array(params[:state]).include?('all')
    if value_to_boolean(params[:published])
      params[:state] -= %w{created claimed completed deleted}
    elsif !params[:published].nil? && !value_to_boolean(params[:published])
      params[:state] -= %w{available}
    end

    @courses = @account.associated_courses.order(:id).where(:workflow_state => params[:state])
    if params[:hide_enrollmentless_courses] || value_to_boolean(params[:with_enrollments])
      @courses = @courses.with_enrollments
    elsif !params[:with_enrollments].nil? && !value_to_boolean(params[:with_enrollments])
      @courses = @courses.without_enrollments
    end

    if value_to_boolean(params[:completed])
      @courses = @courses.completed
    elsif !params[:completed].nil? && !value_to_boolean(params[:completed])
      @courses = @courses.not_completed
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

      is_id = search_term.to_s =~ Api::ID_REGEX
      if is_id && course = @courses.where(id: search_term).first
        @courses = [course]
      elsif is_id && !SearchTermHelper.valid_search_term?(search_term)
        @courses = []
      else
        SearchTermHelper.validate_search_term(search_term)

        name = ActiveRecord::Base.wildcard('courses.name', search_term)
        code = ActiveRecord::Base.wildcard('courses.course_code', search_term)
        @courses = @courses.where("#{name} OR #{code}")
      end
    end

    includes = Set.new(Array(params[:include]))
    # We only want to return the permissions for single courses and not lists of courses.
    includes.delete 'permissions'

    @courses = Api.paginate(@courses, self, api_v1_account_courses_url)

    ActiveRecord::Associations::Preloader.new(@courses, [:account, :root_account])
    render :json => @courses.map { |c| course_json(c, @current_user, session, includes, nil) }
  end

  # Delegated to by the update action (when the request is an api_request?)
  def update_api
    if authorized_action(@account, @current_user, [:manage_account_settings, :manage_storage_quotas])
      account_params = params[:account] || {}
      unauthorized = false

      # account settings (:manage_account_settings)
      account_settings = account_params.select {|k, v| [:name, :default_time_zone].include?(k.to_sym)}.with_indifferent_access
      unless account_settings.empty?
        if is_authorized_action?(@account, @current_user, :manage_account_settings)
          @account.errors.add(:name, t(:account_name_required, 'The account name cannot be blank')) if account_params.has_key?(:name) && account_params[:name].blank?
          @account.errors.add(:default_time_zone, t(:unrecognized_time_zone, "'%{timezone}' is not a recognized time zone", :timezone => account_params[:default_time_zone])) if account_params.has_key?(:default_time_zone) && ActiveSupport::TimeZone.new(account_params[:default_time_zone]).nil?
        else
          account_settings.each {|k, v| @account.errors.add(k.to_sym, t(:cannot_manage_account, 'You are not allowed to manage account settings'))}
          unauthorized = true
        end
      end

      # quotas (:manage_account_quotas)
      quota_settings = account_params.select {|k, v| [:default_storage_quota_mb, :default_user_storage_quota_mb,
                                                      :default_group_storage_quota_mb].include?(k.to_sym)}.with_indifferent_access
      unless quota_settings.empty?
        if is_authorized_action?(@account, @current_user, :manage_storage_quotas)
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
          render :json => account_json(@account, @current_user, session, params[:includes] || [])
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

        custom_help_links = params[:account].delete :custom_help_links
        if custom_help_links
          @account.settings[:custom_help_links] = custom_help_links.select{|k, h| h['state'] != 'deleted'}.sort.map do |index_with_hash|
            hash = index_with_hash[1]
            hash.delete('state')
            hash.assert_valid_keys ["text", "subtext", "url", "available_to"]
            hash
          end
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
        if @account.grants_right?(@current_user, :manage_site_settings)
          # If the setting is present (update is called from 2 different settings forms, one for notifications)
          if params[:account][:settings] && params[:account][:settings][:outgoing_email_default_name_option].present?
            # If set to default, remove the custom name so it doesn't get saved
            params[:account][:settings][:outgoing_email_default_name] = '' if params[:account][:settings][:outgoing_email_default_name_option] == 'default'
          end

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
          end
        else
          # must have :manage_site_settings to update these
          [ :admins_can_change_passwords,
            :admins_can_view_notifications,
            :enable_alerts,
            :enable_eportfolios,
            :enable_profiles,
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

        if sis_id = params[:account].delete(:sis_source_id)
          if !@account.root_account? && sis_id != @account.sis_source_id && @account.root_account.grants_right?(@current_user, session, :manage_sis)
            if sis_id == ''
              @account.sis_source_id = nil
            else
              @account.sis_source_id = sis_id
            end
          end
        end

        process_external_integration_keys

        can_edit_email = params[:account][:settings].try(:delete, :edit_institution_email)
        if @account.root_account? && !can_edit_email.nil?
          @account[:settings][:edit_institution_email] = value_to_boolean(can_edit_email)
        end

        if @account.update_attributes(params[:account])
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

  def settings
    if authorized_action(@account, @current_user, :read)
      @available_reports = AccountReport.available_reports if @account.grants_right?(@current_user, @session, :read_reports)
      if @available_reports
        @last_complete_reports = {}
        @last_reports = {}
        if AccountReport.connection.adapter_name == 'PostgreSQL'
          scope = @account.account_reports.select("DISTINCT ON (report_type) account_reports.*").order(:report_type)
          @last_complete_reports = scope.last_complete_of_type(@available_reports.keys, nil).includes(:attachment).index_by(&:report_type)
          @last_reports = scope.last_of_type(@available_reports.keys, nil).index_by(&:report_type)
        else
          @available_reports.keys.each do |report|
            @last_complete_reports[report] = @account.account_reports.last_complete_of_type(report).first
            @last_reports[report] = @account.account_reports.last_of_type(report).first
          end
        end
      end
      load_course_right_side
      @account_users = @account.account_users
      ActiveRecord::Associations::Preloader.new(@account_users, user: :communication_channels).run
      order_hash = {}
      @account.available_account_roles.each_with_index do |role, idx|
        order_hash[role.id] = idx
      end
      @account_users = @account_users.select(&:user).sort_by{|au| [order_hash[au.role_id] || CanvasSort::Last, Canvas::ICU.collation_key(au.user.sortable_name)] }
      @alerts = @account.alerts

      @account_roles = @account.available_account_roles.sort_by(&:display_sort_index).map{|role| {:id => role.id, :label => role.label}}
      @course_roles = @account.available_course_roles.sort_by(&:display_sort_index).map{|role| {:id => role.id, :label => role.label}}

      @announcements = @account.announcements
      @external_integration_keys = ExternalIntegrationKey.indexed_keys_for(@account)
      js_env({
        APP_CENTER: { enabled: Canvas::Plugin.find(:app_center).enabled? },
        ENABLE_LTI2: @account.root_account.feature_enabled?(:lti2_ui),
        LTI_LAUNCH_URL: account_tool_proxy_registration_path(@account),
        CONTEXT_BASE_URL: "/api/v1/accounts/#{@context.id}"
      })
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
    if authentication_logging || grade_change_logging || course_logging
      logging = {
        authentication: authentication_logging,
        grade_change: grade_change_logging,
        course: course_logging
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
      @user.remove_from_root_account(@account)
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

  def load_course_right_side
    @root_account = @account.root_account
    @maximum_courses_im_gonna_show = 50
    @term = nil
    if params[:enrollment_term_id].present?
      @term = @root_account.enrollment_terms.active.find(params[:enrollment_term_id]) rescue nil
      @term ||= @root_account.enrollment_terms.active[-1]
    end
    associated_courses = @account.associated_courses.active
    associated_courses = associated_courses.for_term(@term) if @term
    @associated_courses_count = associated_courses.count
    @hide_enrollmentless_courses = params[:hide_enrollmentless_courses] == "1"
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
      @counts_report = @account.report_snapshots.detailed.last.try(:data)
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
      @users = @account.all_users
      @avatar_counts = {
        :all => @users.with_avatar_state('any').count,
        :reported => @users.with_avatar_state('reported').count,
        :re_reported => @users.with_avatar_state('re_reported').count,
        :submitted => @users.with_avatar_state('submitted').count
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
      @users = @users.paginate(:page => params[:page], :per_page => 100)
    end
  end

  def sis_import
    if authorized_action(@account, @current_user, :manage_sis)
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
      Shackles.activate(:slave) do
        load_course_right_side
        @courses = []
        @query = (params[:course] && params[:course][:name]) || params[:term]
        if @context && @context.is_a?(Account) && @query
          @courses = @context.courses_name_like(@query, :term => @term, :hide_enrollmentless_courses => @hide_enrollmentless_courses)
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
    teachers = TeacherEnrollment.for_courses_with_user_name(@courses).admin.active
    course_to_student_counts = StudentEnrollment.student_in_claimed_or_available.where(:course_id => @courses).group(:course_id).count(:user_id, :distinct => true)
    courses_to_teachers = teachers.inject({}) do |result, teacher|
      result[teacher.course_id] ||= []
      result[teacher.course_id] << teacher
      result
    end
    @courses.each do |course|
      course.student_count = course_to_student_counts[course.id] || 0
      course_teachers = courses_to_teachers[course.id] || []
      course.teacher_names = course_teachers.uniq(&:user_id).map(&:user_name)
    end
  end
  protected :build_course_stats

  def saml_meta_data
    # This needs to be publicly available since external SAML
    # servers need to be able to access it without being authenticated.
    # It is used to disclose our SAML configuration settings.
    settings = AccountAuthorizationConfig.saml_settings_for_account(@domain_root_account, request.host_with_port)
    render :xml => Onelogin::Saml::MetaData.create(settings)
  end

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
                        :root_account => @context.root_account,
                        :search_method => @context.user_list_search_mode_for(@current_user))
    users = list.users
    admins = users.map do |user|
      admin = @context.account_users.where(user_id: user.id, role_id: role.id).first_or_initialize
      admin.user = user
      return unless authorized_action(admin, @current_user, :create)
      admin
    end

    account_users = admins.map do |admin|
      if admin.new_record?
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

  def process_external_integration_keys
    if params_keys = params[:account][:external_integration_keys]
      ExternalIntegrationKey.indexed_keys_for(@account).each do |key_type, key|
        next unless params_keys.key?(key_type)
        next unless key.grants_right?(@current_user, :write)
        unless params_keys[key_type].blank?
          key.key_value = params_keys[key_type]
          key.save!
        else
          key.delete
        end
      end
    end
  end
end
