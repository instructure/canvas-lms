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

class InfoController < ApplicationController
  ssl_allowed :record_error, :health_check
  skip_before_filter :verify_authenticity_token, :only => :record_error
  skip_before_filter :load_account, :only => :health_check
  skip_before_filter :load_user, :only => :health_check
  before_filter :require_site_admin, :only => :page_views
  
  def page_views
    @views = PageView.recent_with_user
    respond_to do |format|
      format.html
      format.json { render :json => @views.to_json(:methods => :user_name) }
    end
  end
  
  def avatar_image_url
    cancel_cache_buster
    url = Rails.cache.fetch(['avatar_img', params[:user_id]].cache_key, :expires_in => 30.minutes) do
      user = User.find_by_id(params[:user_id]) if params[:user_id].present?
      if user && service_enabled?(:avatars)
        url = user.avatar_url(nil, @domain_root_account && @domain_root_account.settings[:avatars])
      end
      url ||= '/images/no_pic.gif'
    end
    redirect_to url
  end

  def record_error_for_teacher
    @admins = @course.admins
    if !@admins.empty?
      comments = params[:error][:comments] rescue nil
      comments ||= "No comments"
      backtrace = params[:error][:backtrace] rescue nil
      backtrace ||= ""
      subject = "Student Feedback: #{comments[0,50]}"
      comments = backtrace + "\n" + comments
      @message = ContextMessage.create!({
        :context => @course,
        :user => @current_user,
        :body => comments,
        :subject => subject,
        :recipients => @admins.map(&:id).join(",")
      })
      respond_to do |format|
        flash[:notice] = "Thanks for your feedback!  Your teacher has been notified."
        format.html { redirect_to root_url }
        format.json { render :json => {:logged => true, :id => @message.id, :teacher_message => true}.to_json }
      end
      return true
    end
  end
  protected :record_error_for_teacher
  
  def record_error
    error = params[:error] || {}
    if @current_user && params[:feedback_type] == 'teacher' && params[:course_id].present? && 
        @course = @current_user.courses.find_by_id(params[:course_id])
      return if record_error_for_teacher
    end
    # error = {:error => error} unless error.is_a?(Hash)
    error[:user] = @current_user if @current_user
    error[:user_agent] = request.headers['User-Agent']
    begin
      report_id = error.delete(:id)
      @report = ErrorReport.find_by_id(report_id) if report_id.present?
      @report ||= ErrorReport.find_by_id(session[:last_error_id]) if session[:last_error_id].present?
      @report ||= ErrorReport.create()
      @report.user = @current_user
      @report.account ||= @domain_root_account
      @report.error_type = params[:error][:error_type] rescue nil
      backtrace = params[:error].delete(:backtrace) rescue nil
      backtrace ||= ""
      backtrace += "\n\n-----------------------------------------\n\n" + @report.backtrace if @report.backtrace
      @report.backtrace = backtrace
      @report.http_env ||= ErrorReport.useful_http_env_stuff_from_request(request)
      @report.request_context_id = $request_context_id
      @report.update_attributes(error.delete_if{|k,v| !ErrorReport.column_names.include?(k.to_s)})
      @report.send_later(:send_to_external)
    rescue => e
      @exception = e
      ErrorLogging.log_error(:default, {
        :message => "Error Report Creation failed",
        :exception_message => (@exception.message rescue ''),
        :backtrace => (@exception.backtrace rescue ''),
        :user_message => (error[:comments] rescue ''),
        :user_email => (error[:email] rescue ''),
        :user_id => (error[:user].id rescue '')
      })
    end
    respond_to do |format|
      flash[:notice] = "Thanks for your help!  We'll get right on this"
      format.html { redirect_to root_url }
      format.json { render :json => {:logged => true, :id => @report.id}.to_json }
    end
  end
  
  def health_check
    # This action should perform checks on various subsystems, and raise an exception on failure.
    ActiveRecord::Base.connection.select_value("SELECT now();")
    
    respond_to do |format|
      format.html { render :text => 'ok' }
      format.json { render :json => { :status => 'ok' } }
    end
  end
end
