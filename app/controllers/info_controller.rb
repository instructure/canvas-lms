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
  skip_before_filter :load_user, :only => [:health_check, :browserconfig]

  def styleguide
    js_bundle :styleguide
    render :layout => "layouts/styleguide"
  end

  def message_redirect
    m = AssetSignature.find_by_signature(Message, params[:id])
    if m && m.url
      redirect_to m.url
    else
      redirect_to "http://#{HostUrl.default_host}/"
    end
  end

  def help_links
    render :json => @domain_root_account && @domain_root_account.help_links
  end

  def record_error
    error = params[:error] || {}
    error[:user_agent] = request.headers['User-Agent']
    begin
      report_id = error.delete(:id)
      @report = ErrorReport.where(id: report_id.to_i).first if report_id.present? && report_id.to_i != 0
      @report ||= ErrorReport.where(id: session.delete(:last_error_id)).first if session[:last_error_id].present?
      @report ||= ErrorReport.new
      error.delete(:category) if @report.category.present?
      @report.user = @current_user
      @report.account ||= @domain_root_account
      backtrace = params[:error].delete(:backtrace) rescue nil
      backtrace ||= ""
      if @report.backtrace
        backtrace += "\n\n-----------------------------------------\n\n"
        backtrace += @report.backtrace
      end
      @report.backtrace = backtrace
      @report.http_env ||= Canvas::Errors::Info.useful_http_env_stuff_from_request(request)
      @report.request_context_id = RequestContextGenerator.request_id
      @report.assign_data(error)
      @report.save
      @report.send_later(:send_to_external)
    rescue => e
      @exception = e
      Canvas::Errors.capture(
        e,
        message: "Error Report Creation failed",
        user_email: error[:email],
        user_id: @current_user.try(:id)
      )
    end
    respond_to do |format|
      flash[:notice] = t('notices.error_reported', "Thanks for your help!  We'll get right on this")
      format.html { redirect_to root_url }
      format.json { render :json => {:logged => true, :id => @report.try(:id) } }
    end
  end

  def health_check
    # This action should perform checks on various subsystems, and raise an exception on failure.
    Account.connection.select_value("SELECT 1")
    Tempfile.open("heartbeat", ENV['TMPDIR'] || Dir.tmpdir) { |f| f.write("heartbeat"); f.flush }

    respond_to do |format|
      format.html { render :text => 'canvas ok' }
      format.json { render :json => { :status => 'canvas ok', :revision => Canvas.revision } }
    end
  end

  # for windows live tiles
  def browserconfig
    cancel_cache_buster
    expires_in 10.minutes, public: true
  end

end
