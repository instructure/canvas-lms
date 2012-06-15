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

# @API Accounts
class AccountsController < ApplicationController
  before_filter :require_user, :only => [:index]
  before_filter :reject_student_view_student
  before_filter :get_context

  include Api::V1::Account

  # @API List accounts
  # List accounts that the current user can view or manage.  Typically,
  # students and even teachers will get an empty list in response, only
  # account admins can view the accounts that they are in.
  def index
    @accounts = @current_user.accounts rescue []
    respond_to do |format|
      format.html
      format.json do
        # TODO: what would be more useful, include sub-accounts here
        # that you implicitly have access to, or have a separate method
        # to get the sub-accounts of an account?
        @accounts = Api.paginate(@accounts, self, api_v1_accounts_path)
        render :json => @accounts.map { |a| account_json(a, @current_user, session, []) }
      end
    end
  end

  # @API Get a single account
  # Retrieve information on an individual account, given by id or sis
  # sis_account_id.
  def show
    return unless authorized_action(@account, @current_user, :read)

    respond_to do |format|
      format.html do
        return redirect_to account_settings_url(@account) if @account.site_admin? || !@account.grants_right?(@current_user, nil, :read_course_list)
        load_course_right_side
        @courses = @account.fast_all_courses(:term => @term, :limit => @maximum_courses_im_gonna_show, :hide_enrollmentless_courses => @hide_enrollmentless_courses)
        build_course_stats
      end
      format.json { render :json => account_json(@account, @current_user, session, []) }
    end
  end

  include Api::V1::Course

  # @API List active courses in an account
  # Retrieve the list of active (non-deleted) courses in this account.
  #
  # @argument hide_enrollmentless_courses [optional] If set, only return courses that have at least one enrollment.
  #
  # @example_response
  #   [ { 'id': 1, 'name': 'first course', 'course_code': 'first', 'sis_course_id': 'first-sis' },
  #     { 'id': 2, 'name': 'second course', 'course_code': 'second', 'sis_course_id': null } ]
  def courses_api
    if authorized_action(@account, @current_user, :read)
      @courses = @account.associated_courses.active
      @courses = @courses.with_enrollments if params[:hide_enrollmentless_courses]
      @courses = Api.paginate(@courses, self, api_v1_account_courses_path, :order => :id)
      render :json => @courses.map { |c| course_json(c, @current_user, session, [], nil) }
    end
  end

  def update
    if authorized_action(@account, @current_user, :manage_account_settings)
      respond_to do |format|

        custom_help_links = params[:account].delete :custom_help_links
        if custom_help_links
          @account.settings[:custom_help_links] = custom_help_links.sort.map do |index_with_hash|
            hash = index_with_hash[1]
            hash.assert_valid_keys ["text", "subtext", "url", "available_to"]
            hash
          end
        elsif @account.settings[:custom_help_links].present?
          @account.settings.delete :custom_help_links
        end

        enable_user_notes = params[:account].delete :enable_user_notes
        allow_sis_import = params[:account].delete :allow_sis_import
        global_includes = !!params[:account][:settings].try(:delete, :global_includes)
        if params[:account][:services]
          params[:account][:services].slice(*Account.services_exposed_to_ui_hash.keys).each do |key, value|
            @account.set_service_availability(key, value == '1')
          end
          params[:account].delete :services
        end
        if Account.site_admin.grants_right?(@current_user, :manage_site_settings)
          @account.enable_user_notes = enable_user_notes if enable_user_notes
          @account.allow_sis_import = allow_sis_import if allow_sis_import && @account.root_account?
          if params[:account][:settings]
            @account.settings[:admins_can_change_passwords] = !!params[:account][:settings][:admins_can_change_passwords]
            @account.settings[:global_includes] = global_includes
            @account.settings[:enable_eportfolios] = !!params[:account][:settings][:enable_eportfolios] unless @account.site_admin?
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
        if @account.update_attributes(params[:account])
          format.html { redirect_to account_settings_url(@account) }
          format.json { render :json => @account.to_json }
        else
          flash[:error] = t(:update_failed_notice, "Account settings update failed")
          format.html { redirect_to account_settings_url(@account) }
          format.json { render :json => @account.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def settings
    if authorized_action(@account, @current_user, :read)
      @available_reports = AccountReport.available_reports(@account) if @account.grants_right?(@current_user, @session, :read_reports)
      if @available_reports
        @last_complete_reports = {}
        @last_reports = {}
        @available_reports.keys.each do |report|
          @last_complete_reports[report] = @account.account_reports.last_complete_of_type(report).first
          @last_reports[report] = @account.account_reports.last_of_type(report).first
        end
      end
      load_course_right_side
      @account_users = @account.account_users
      order_hash = {}
      (['AccountAdmin'] + @account.account_membership_types).each_with_index do |type, idx|
        order_hash[type] = idx
      end
      @account_users = @account_users.select(&:user).sort_by{|au| [order_hash[au.membership_type] || 999, au.user.sortable_name.downcase] }
      @announcements = @account.announcements
      @alerts = @account.alerts
      @role_types = RoleOverride.account_membership_types(@account)
    end
  end

  def confirm_delete_user
    @root_account = @account.root_account
    if authorized_action(@root_account, @current_user, :manage_user_logins)
      @context = @root_account
      @user = @root_account.all_users.find_by_id(params[:user_id]) if params[:user_id].present?
      if !@user
        flash[:error] = t(:no_user_message, "No user found with that id")
        redirect_to account_url(@account)
      end
    end
  end
  
  def remove_user
    @root_account = @account.root_account
    if authorized_action(@root_account, @current_user, :manage_user_logins)
      @user = UserAccountAssociation.find_by_account_id_and_user_id(@root_account.id, params[:user_id]).user rescue nil
      # if the user is in any account other then the
      # current one, remove them from the current account
      # instead of deleting them completely
      if @user
        if !(@user.associated_root_accounts.map(&:id).compact.uniq - [@root_account.id]).empty?
          @user.remove_from_root_account(@root_account)
        else
          @user.destroy(true)
        end
        flash[:notice] = t(:user_deleted_message, "%{username} successfully deleted", :username => @user.name)
      end
      respond_to do |format|
        format.html { redirect_to account_users_url(@account) }
        format.json { render :json => (@user || {}).to_json }
      end
    end
  end
  
  def turnitin_confirmation 
    if authorized_action(@account, @current_user, :manage_account_settings)
      turnitin = Turnitin::Client.new(params[:id], params[:shared_secret])
      render :json => {:success => turnitin.testSettings}.to_json
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
    @associated_courses_count = associated_courses.count('DISTINCT course_id')
    @hide_enrollmentless_courses = params[:hide_enrollmentless_courses] == "1"
  end
  protected :load_course_right_side
  
  def statistics
    if authorized_action(@account, @current_user, :view_statistics)
      add_crumb(t(:crumb_statistics, "Statistics"), statistics_account_url(@account))
      if @account.grants_right?(@current_user, nil, :read_course_list)
        @recently_started_courses = @account.all_courses.recently_started
        @recently_ended_courses = @account.all_courses.recently_ended
        if @account == Account.default
          @recently_created_courses = @account.all_courses.recently_created
        end
      end
      if @account.grants_right?(@current_user, nil, :read_roster)
        @recently_logged_users = @account.all_users.recently_logged_in[0,25]
      end
      @counts_report = @account.report_snapshots.detailed.last.try(:data)
    end
  end
  
  def statistics_graph
    if authorized_action(@account, @current_user, :view_statistics)
      @items = @account.report_snapshots.progressive.last.try(:report_value_over_time, params[:attribute])
      respond_to do |format|
        format.json { render :json => @items.to_json }
        format.csv { 
          res = FasterCSV.generate do |csv|
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
      @last_batch = @account.sis_batches.scoped(:order=>'created_at DESC', :limit=>1).first
      @terms = @account.enrollment_terms.active
      respond_to do |format|
        format.html
        format.json { render :json => @current_batch.to_json(:include => :sis_batch_log_entries) }
      end
    end
  end

  def sis_import_submit
    raise "SIS imports can only be executed on root accounts" unless @account.root_account?
    raise "SIS imports can only be executed on enabled accounts" unless @account.allow_sis_import

    if authorized_action(@account, @current_user, :manage_sis)
      SisBatch.transaction do
        if !@account.current_sis_batch || !@account.current_sis_batch.importing?
          batch = SisBatch.create_with_attachment(@account, params[:import_type], params[:attachment])

          if params[:batch_mode].to_i > 0
            batch.batch_mode = true
            if params[:batch_mode_term_id].present?
              batch.batch_mode_term = @account.enrollment_terms.active.find(params[:batch_mode_term_id])
            end
          end

          batch.options ||= {}
          if params[:override_sis_stickiness].to_i > 0
            batch.options[:override_sis_stickiness] = true
            [:add_sis_stickiness, :clear_sis_stickiness].each do |option|
              batch.options[option] = true if params[option].to_i > 0
            end
          end

          batch.save!

          @account.current_sis_batch_id = batch.id
          @account.save
          batch.process
          render :json => batch.to_json(:include => :sis_batch_log_entries),
                 :as_text => true
        else
          render :json => {:error=>true, :error_message=> t(:sis_import_in_process_notice, "An SIS import is already in process."), :batch_in_progress=>true}.to_json,
                 :as_text => true
        end
      end
    end

  end
  
  def courses_redirect
    redirect_to course_url(params[:id])
  end
  
  def courses
    if authorized_action(@context, @current_user, :read)
      load_course_right_side
      @courses = []
      @query = (params[:course] && params[:course][:name]) || params[:term]
      if @context && @context.is_a?(Account) && @query
        @courses = @context.courses_name_like(@query, :term => @term, :hide_enrollmentless_courses => @hide_enrollmentless_courses)
      end
      respond_to do |format|
        format.html {
          build_course_stats
          redirect_to @courses.first if @courses.length == 1
        }
        format.json  { 
          cancel_cache_buster
          expires_in 30.minutes 
          render :json => @courses.map{ |c| {:label => c.name, :id => c.id} }
        }
      end
    end
  end
  
  def build_course_stats
    teachers = TeacherEnrollment.for_courses_with_user_name(@courses).admin.active
    course_to_student_counts = StudentEnrollment.student_in_claimed_or_available.scoped(:conditions => { :course_id => @courses.map(&:id) }).count('DISTINCT user_id', :group => :course_id)
    courses_to_teachers = teachers.inject({}) do |result, teacher|
      result[teacher.course_id] ||= []
      result[teacher.course_id] << teacher
      result
    end
    @courses.each do |course|
      course.write_attribute(:student_count, course_to_student_counts[course.id] || 0)
      course_teachers = courses_to_teachers[course.id] || []
      course.write_attribute(:teacher_names, course_teachers.uniq(&:user_id).map(&:user_name))
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
    if authorized_action(@context, @current_user, :manage_account_memberships)
      list = UserList.new(params[:user_list], @context.root_account, @context.user_list_search_mode_for(@current_user))
      users = list.users
      account_users = users.map do |user|
        admin = user.flag_as_admin(@context, params[:membership_type])
        { :enrollment => {
          :id => admin.id,
          :name => user.name,
          :membership_type => admin.membership_type,
          :workflow_state => 'active',
          :user_id => user.id,
          :type => 'admin',
          :email => user.email
        }}
      end
      render :json => account_users
    end
  end
  
  def remove_account_user
    if authorized_action(@context, @current_user, :manage_account_memberships)
      @account_user = AccountUser.find(params[:id])
      @account_user.destroy
      respond_to do |format|
        format.html { redirect_to account_settings_url(@context, :anchor => "tab-users") }
        format.json { render :json => @account_user.to_json }
      end
    end
  end
  
  def run_report
    if authorized_action(@context, @current_user, :read_reports)
      student_report = AccountReport.new(:user=>@current_user, :account=>@account, :report_type=>params[:report_type], :parameters=>params[:parameters])
      student_report.workflow_state = :running
      student_report.progress = 0
      student_report.save
      student_report.run_report
      respond_to do |format|
        format.json {render :json => {:student_report_id=>student_report.id, :success=>true}.to_json}
      end
    end
  end

end
