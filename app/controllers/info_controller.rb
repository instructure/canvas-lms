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
  skip_before_filter :verify_authenticity_token, :only => :record_error
  skip_before_filter :load_account, :only => :health_check
  skip_before_filter :load_user, :only => :health_check
  
  def message_redirect
    m = Message.find_by_id(params[:id])
    if m && m.url
      redirect_to m.url
    else
      redirect_to "http://#{HostUrl.default_host}/"
    end
  end
  
  def avatar_image_url
    cancel_cache_buster
    url = Rails.cache.fetch(Cacher.avatar_cache_key(params[:user_id])) do
      user = User.find_by_id(params[:user_id]) if params[:user_id].present?
      if user && service_enabled?(:avatars)
        url = user.avatar_url(nil, @domain_root_account && @domain_root_account.settings[:avatars], params[:fallback])
      end
      url ||= params[:fallback] || '/images/no_pic.gif'
    end
    redirect_to url
  end

  def record_error_for_teacher
    @admins = @course.admins
    if !@admins.empty?
      backtrace = params[:error][:backtrace] rescue nil
      comments = params[:error][:comments] rescue nil
      comments = t(:no_comments, "No comments") unless comments.present?
      body = t(:feedback_subject, "Student Feedback on %{course}", :course => @course.name)
      body += "\n" + backtrace if backtrace.present?
      body += "\n" + comments
      @message = @current_user.initiate_conversation(@admins.map(&:id)).add_message(comments)
      respond_to do |format|
        flash[:notice] = t('notices.feedback_sent', "Thanks for your feedback!  Your teacher has been notified.")
        format.html { redirect_to root_url }
        format.json { render :json => {:logged => true, :id => @message.id, :teacher_message => true}.to_json }
      end
      return true
    end
  end
  protected :record_error_for_teacher
  
  def record_error
    error = params[:error] || {}
    if @current_user && params[:feedback_type] == 'teacher' && params[:course_id].present? && @course = @current_user.courses.find_by_id(params[:course_id])
      return if record_error_for_teacher
    end
    error[:user_agent] = request.headers['User-Agent']
    begin
      report_id = error.delete(:id)
      @report = ErrorReport.find_by_id(report_id) if report_id.present?
      @report ||= ErrorReport.find_by_id(session.delete(:last_error_id)) if session[:last_error_id].present?
      @report ||= ErrorReport.create()
      error.delete(:category) if @report.category.present?
      @report.user = @current_user
      @report.account ||= @domain_root_account
      backtrace = params[:error].delete(:backtrace) rescue nil
      backtrace ||= ""
      backtrace += "\n\n-----------------------------------------\n\n" + @report.backtrace if @report.backtrace
      @report.backtrace = backtrace
      @report.http_env ||= ErrorReport.useful_http_env_stuff_from_request(request)
      @report.request_context_id = RequestContextGenerator.request_id
      @report.assign_data(error)
      @report.save
      @report.send_later(:send_to_external)
    rescue => e
      @exception = e
      ErrorReport.log_exception(:default, e,
        :message => "Error Report Creation failed",
        :user_email => (error[:email] rescue ''),
        :user_id => (error[:user].id rescue ''))
    end
    respond_to do |format|
      flash[:notice] = t('notices.error_reported', "Thanks for your help!  We'll get right on this")
      format.html { redirect_to root_url }
      format.json { render :json => {:logged => true, :id => @report.id}.to_json }
    end
  end

  def record_js_error
    error = params[:error]
    error[:backtrace] = error[:url]
    ErrorReport.log_error('javascript', error)
    # Render a 0x0 gif
    render  :content_type =>'image/gif', :text => "GIF89a\001\000\001\000\200\377\000\377\377\377\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
  end

  def health_check
    # This action should perform checks on various subsystems, and raise an exception on failure.
    Account.connection.select_value("SELECT 1")

    respond_to do |format|
      format.html { render :text => 'canvas ok' }
      format.json { render :json => { :status => 'canvas ok' } }
    end
  end
end
