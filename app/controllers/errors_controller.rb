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

# @API Error Reports
#
# @model ErrorReport
#   {
#     "id": "ErrorReport",
#     "description": "A collection of information around a specific notification of a problem",
#     "properties": {
#       "subject": {
#         "description": "The users problem summary, like an email subject line",
#         "type": "string",
#         "example": "File upload breaking"
#       },
#       "comments": {
#         "description": "long form documentation of what was witnessed",
#         "type": "string",
#         "example": "When I went to upload a .mov file to my files page, I got an error.  Retrying didn't help, other file types seem ok"
#       },
#       "user_perceived_severity": {
#         "description": "categorization of how bad the user thinks the problem is.  Should be one of [just_a_comment, not_urgent, workaround_possible, blocks_what_i_need_to_do, extreme_critical_emergency].",
#         "type": "string",
#         "example": "just_a_comment"
#       },
#       "email": {
#         "description": "the email address of the reporting user",
#         "type": "string",
#         "example": "name@example.com"
#       },
#       "url": {
#         "description": "URL of the page on which the error was reported",
#         "type": "string",
#         "example": "https://canvas.instructure.com/courses/1"
#       },
#       "context_asset_string": {
#         "description": "string describing the asset being interacted with at the time of error.  Formatted '[type]_[id]'",
#         "type": "string",
#         "example": "user_1"
#       },
#       "user_roles": {
#         "description": "comma seperated list of roles the reporting user holds.  Can be one [student], or many [teacher,admin]",
#         "type": "string",
#         "example": "user,teacher,admin"
#       }
#     }
#   }
#
class ErrorsController < ApplicationController
  PER_PAGE = 20

  before_action :require_view_error_reports, except: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]

  def require_view_error_reports
    require_site_admin_with_permission(:view_error_reports)
  end

  def index
    params[:page] = (params[:page].to_i > 0) ? params[:page].to_i : 1
    @reports = ErrorReport.preload(:user, :account)

    @message = params[:message]
    if error_search_enabled? && @message.present?
      @reports = @reports.where("message LIKE ?", "%" + @message + "%")
    elsif params[:category].blank?
      @reports = @reports.where("category<>'404'")
    end
    if params[:category].present?
      @reports = @reports.where(category: params[:category])
    end

    @reports = @reports.order("created_at DESC").paginate(per_page: PER_PAGE, page: params[:page], total_entries: nil)
  end

  def show
    @reports = [ErrorReport.find(params[:id])]
    render :index
  end

  # @API Create Error Report
  #
  # Create a new error report documenting an experienced problem
  #
  # Performs the same action as when a user uses the "help -> report a problem"
  # dialog.
  #
  # @argument error[subject] [Required, String]
  #   The summary of the problem
  #
  # @argument error[url] [Optional, String]
  #   URL from which the report was issued
  #
  # @argument error[email] [Optional, String]
  #   Email address for the reporting user
  #
  # @argument error[comments] [Optional, String]
  #   The long version of the story from the user one what they experienced
  #
  # @argument error[http_env] [Optional, SerializedHash]
  #   A collection of metadata about the users' environment.  If not provided,
  #   canvas will collect it based on information found in the request.
  #   (Doesn't have to be HTTPENV info, could be anything JSON object that can be
  #   serialized as a hash, a mobile app might include relevant metadata for
  #   itself)
  #
  # @example_request
  #   # Create error report
  #   curl 'https://<canvas>/api/v1/error_reports' \
  #         -X POST \
  #         -F 'error[subject]="things are broken"' \
  #         -F 'error[url]=http://<canvas>/courses/1' \
  #         -F 'error[description]="All my thoughts on what I saw"' \
  #         -H 'Authorization: Bearer <token>'
  def create
    # this action can be called by an unauthenticated user.  To prevent
    # abuse, we're representing this as an expensive operation so it would
    # get quickly rate limited if hit repeatedly.
    increment_request_cost(200)

    reporter = @current_user.try(:fake_student?) ? @real_current_user : @current_user
    error = params[:error]&.to_unsafe_h || {}

    # this is a honeypot field to catch spambots. it's hidden via css and should always be empty.
    return render(nothing: true, status: :bad_request) if error.delete(:username).present?

    unless Shard.current.in_current_region?
      logger.debug("Out of region error report received")
      return render(nothing: true, status: :bad_request)
    end

    error[:user_agent] = request.headers["User-Agent"]
    begin
      report_id = error.delete(:id)
      report = ErrorReport.where(id: report_id.to_i).first if report_id.present? && report_id.to_i != 0
      report ||= ErrorReport.where(id: session.delete(:last_error_id)).first if session[:last_error_id].present?
      report ||= ErrorReport.new
      error.delete(:category) if report.category.present?
      report.user = reporter
      report.account ||= @domain_root_account
      backtrace = error.fetch(:backtrace, "")
      if report.backtrace
        backtrace += "\n\n-----------------------------------------\n\n"
        backtrace += report.backtrace
      end
      report.backtrace = backtrace
      report.http_env ||= Canvas::Errors::Info.useful_http_env_stuff_from_request(request)
      report.request_context_id = RequestContext::Generator.request_id
      report.assign_data(error)
      report.save
      report.delay.send_to_external
    rescue => e
      @exception = e
      Canvas::Errors.capture(
        e,
        message: "Error Report Creation failed",
        user_email: error[:email],
        user_id: reporter.try(:id)
      )
    end
    respond_to do |format|
      flash[:notice] = t("notices.error_reported", "Thanks for your help!  We'll get right on this")
      format.html { redirect_to root_url }
      format.json { render json: { logged: true, id: report.try(:id) } }
    end
  end

  def error_search_enabled?
    Setting.get("error_search_enabled", "true") == "true"
  end
  helper_method :error_search_enabled?
end
