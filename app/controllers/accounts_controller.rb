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

class AccountsController < ApplicationController
  before_filter :require_user, :only => [:index]
  before_filter :get_context
  
  def index
    @accounts = @current_user.accounts rescue []
  end
  
  def show
    return redirect_to account_settings_url(@account) if @account.site_admin?
    if authorized_action(@account, @current_user, :read)
      load_course_right_side
      @courses = @account.fast_all_courses(:term => @term, :limit => @maximum_courses_im_gonna_show, :hide_enrollmentless_courses => @hide_enrollmentless_courses)
      build_course_stats
    end
  end
  
  def update
    if authorized_action(@account, @current_user, :manage_account_settings)
      respond_to do |format|
        enable_user_notes = params[:account].delete :enable_user_notes
        allow_sis_import = params[:account].delete :allow_sis_import
        if params[:account][:services]
          params[:account][:services].slice(*Account.services_exposed_to_ui_hash.keys).each do |key, value|
            @account.set_service_availability(key, value == '1')
          end
          params[:account].delete :services
        end
        if current_user_is_site_admin?
          @account.enable_user_notes = enable_user_notes if enable_user_notes
          @account.allow_sis_import = allow_sis_import if allow_sis_import && @account.root_account?
          if params[:account][:settings]
            @account.settings[:admins_can_change_passwords] = !!params[:account][:settings][:admins_can_change_passwords]
            @account.settings[:global_includes] = !!params[:account][:settings][:global_includes]
          end
        end
        if sis_id = params[:account].delete(:sis_source_id)
          if sis_id != @account.sis_source_id && (@account.root_account || @account).grants_right?(@current_user, session, :manage_sis)
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
      @account_users = @account_users.select(&:user).sort_by{|au| [order_hash[au.membership_type] || 999, au.user.sortable_name] }
      @account_notifications = AccountNotification.for_account(@account)
    end
  end
  
  def add_user
    if authorized_action(@account, @current_user, :manage_admin_users)
      @root_account = @account.root_account || @account
      params[:pseudonym][:unique_id] ||= params[:pseudonym][:path]
      @pseudonym = Pseudonym.find_by_unique_id_and_account_id(params[:pseudonym][:unique_id], @root_account.id)
      @pseudonym ||= Pseudonym.new(:unique_id => params[:pseudonym][:unique_id], :account => @root_account)
      new_login = @pseudonym.new_record?
      if !@pseudonym.new_record?
        user = @pseudonym.user
        render :json => {:errors => {'pseudonym[unique_id]' => mt(:login_in_use_notice, "The login specified is already in use by [%{username}](%{url})", :username => user.name, :url => "/users/#{user.id}")}}.to_json, :status => :bad_request
        return
      end
      notify = (params[:pseudonym].delete :send_confirmation) == '1'
      email = params[:pseudonym][:path] || params[:pseudonym][:unique_id]
      @active_cc = CommunicationChannel.find_by_path_and_path_type_and_workflow_state(email, 'email', 'active')
      if @active_cc && @active_cc.user && !@pseudonym.user
        @user = @active_cc.user
      end
      @user ||= User.new
      new_user = @user.new_record?
      @user.attributes = params[:user]
      @user.name ||= params[:pseudonym][:unique_id]
      if @user.save
        @pseudonym.user = @user
        @pseudonym.workflow_state = 'active'
        if @active_cc
        else
          @pseudonym.path = email
        end
        @pseudonym.errors.clear
        if @pseudonym.valid?
          @pseudonym.save_without_session_maintenance
          @pseudonym.assert_communication_channel(true)
          message_sent = notify && new_login
          @pseudonym.send_registration_notification! if notify && (new_login || @user.pre_registered?)
          @user.update_account_associations_later
          @user.reload
          data = OpenObject.new(:user => @user, :pseudonym => @pseudonym, :channel => @user.communication_channel, :new_login => new_login, :new_user => new_user, :message_sent => message_sent)
          respond_to do |format|
            format.json { render :json => data.to_json }
          end
        else
          @user.destroy if @user.pseudonyms.select{|p| !p.new_record? }.empty?
          render :json => {:errors => {:base => t(:invalid_login_message, "Invalid login")}}.to_json, :status => :bad_request
        end
      else
        render :json => {:errors => {:base => t(:invalid_login_message, "Invalid login")}}.to_json, :status => :bad_request
      end
    end
  end
  
  def confirm_delete_user
    if authorized_action(@account, @current_user, :manage_admin_users)
      @context = @account
      @user = @account.all_users.find_by_id(params[:user_id]) if params[:user_id].present?
      if !@user
        flash[:error] = t(:no_user_message, "No user found with that id")
        redirect_to account_url(@account)
      end
    end
  end
  
  def remove_user
    if authorized_action(@account, @current_user, :manage_admin_users)
      @user = UserAccountAssociation.find_by_account_id_and_user_id(@account.id, params[:user_id]).user rescue nil
      # if the user is in any account other then the
      # current one, remove them from the current account
      # instead of deleting them completely
      account_ids = []
      if @user
        account_ids = @user.associated_root_accounts.map(&:id)
      end
      account_ids = account_ids.compact.uniq - [@account.id]
      if @user && !account_ids.empty?
        @root_account = @account.root_account || @account
        @user.remove_from_root_account(@root_account)
      else
        @user && @user.destroy
      end
      respond_to do |format|
        flash[:notice] = t(:user_deleted_message, "%{username} successfully deleted", :username => @user.name) if @user
        format.html { redirect_to account_url(@account) }
        format.json { render :json => @user.to_json }
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
    @root_account = @account.root_account || @account
    @maximum_courses_im_gonna_show = 100
    @term = nil
    if params[:enrollment_term_id].present?
      @term = @root_account.enrollment_terms.active.find(params[:enrollment_term_id]) rescue nil
      @term ||= @root_account.enrollment_terms.active[-1]
    end
    associated_courses = @account.associated_courses.active
    associated_courses = associated_courses.for_term(@term) if @term
    @associated_courses_count = associated_courses.uniq.count
    @hide_enrollmentless_courses = params[:hide_enrollmentless_courses] == "1"
  end
  protected :load_course_right_side
  
  def statistics
    if authorized_action(@account, @current_user, :read)
      add_crumb(t(:crumb_statistics, "Statistics"), statistics_account_url(@account))
      @recently_started_courses = @account.all_courses.recently_started
      @recently_ended_courses = @account.all_courses.recently_ended
      @recently_logged_users = @account.all_users.recently_logged_in[0,25]
      if @account == Account.default
        @recently_created_courses = @account.all_courses.recently_created
      end
      @counts_report = ReportSnapshot.get_account_details_by_type_and_id('counts_detailed', @account.id)
    end
  end
  
  def statistics_graph
    if authorized_action(@account, @current_user, :read)
      @items = ReportSnapshot.get_account_detail_over_time('counts_progressive_detailed', @account.id, params[:attribute])
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
  
  def statistics_page_views
    if authorized_action(@account, @current_user, :read)
      start_at = Date.parse(params[:start_at]) rescue nil
      start_at ||= 1.month.ago.to_date
      end_at = Date.parse(params[:end_at]) rescue nil
      end_at ||= Date.today

      @end_at = [[start_at, end_at].max, Date.today].min
      @start_at = [[start_at, end_at].min, Date.today].min
      add_crumb(t(:crumb_statistics, "Statistics"), statistics_account_url(@account))
      add_crumb(t(:crumb_page_views, "Page Views"))
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
      ActiveRecord::Base.transaction do
        if !@account.current_sis_batch || !@account.current_sis_batch.importing?
          batch = SisBatch.create_with_attachment(@account, params[:import_type], params[:attachment])

          if params[:batch_mode].to_i > 0
            batch.batch_mode = true
            if params[:batch_mode_term_id].present?
              batch.batch_mode_term = @account.enrollment_terms.active.find(params[:batch_mode_term_id])
            end
            batch.save!
          end

          @account.current_sis_batch_id = batch.id
          @account.save
          batch.process
          render :text => batch.to_json(:include => :sis_batch_log_entries)
        else
          render :text => {:error=>true, :error_message=> t(:sis_import_in_process_notice, "An SIS import is already in process."), :batch_in_progress=>true}.to_json
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
      @query = (params[:course] && params[:course][:name]) || params[:query]
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
          render :json => {
            :query =>  @query,
            :suggestions =>  @courses.map(& :name),
            :data => @courses.map(&:id)
          }
        }
      end
    end
  end
  
  def build_course_stats
    teachers = TeacherEnrollment.for_courses_with_user_name(@courses).admin.active
    students = StudentEnrollment.for_courses_with_user_name(@courses).student
    @courses.each do |course|
      course.write_attribute(:student_count, students.select{|e| e.course_id == course.id }.once_per(&:user_id).length)
      course.write_attribute(:teacher_names, teachers.select{|e| e.course_id == course.id }.once_per(&:user_id).map(&:user_name))
    end
  end
  protected :build_course_stats
  
  def saml_meta_data
    # This needs to be publicly available since external SAML
    # servers need to be able to access it without being authenticated.
    # It is used to disclose our SAML configuration settings.
    if @domain_root_account.account_authorization_config and @domain_root_account.account_authorization_config.auth_type == 'saml'
      settings = @domain_root_account.account_authorization_config.saml_settings
      render :xml => Onelogin::Saml::MetaData.create(settings)
    else
      render :xml => ""
    end
  end
  
  def add_account_user
    if authorized_action(@context, @current_user, :manage_account_memberships)
      res = @context.add_admin(params[:admin])
      if res
        redirect_to account_settings_url(@context, :anchor => "tab-users")
      else
        flash[:error] = t(:no_user_found_notice, "No user with that email address was found")
        redirect_to account_settings_url(@context, :anchor => "tab-users")
      end
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
