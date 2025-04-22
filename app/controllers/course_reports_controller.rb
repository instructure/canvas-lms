# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# @API Course Reports
#
# API for accessing course reports.
#
# @model Report
#     {
#       "id": "Report",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the report.",
#           "example": "1",
#           "type": "integer"
#         },
#         "file_url": {
#           "description": "The url to the report download.",
#           "example": "https://example.com/some/path",
#           "type": "string"
#         },
#         "attachment": {
#           "description": "The attachment api object of the report. Only available after the report has completed.",
#           "$ref": "File"
#         },
#         "status": {
#           "description": "The status of the report",
#           "example": "complete",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The date and time the report was created.",
#           "example": "2013-12-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "started_at": {
#           "description": "The date and time the report started processing.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "ended_at": {
#           "description": "The date and time the report finished processing.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "parameters": {
#           "description": "The report parameters",
#           "example": {"course_id": 2, "start_at": "2012-07-13T10:55:20-06:00", "end_at": "2012-07-13T10:55:20-06:00"},
#           "$ref": "ReportParameters"
#         },
#         "progress": {
#           "description": "The progress of the report",
#           "example": "100",
#           "type": "integer"
#         }
#       }
#     }
#
# @model ReportParameters
#     {
#       "id": "ReportParameters",
#       "description": "The parameters returned will vary for each report.",
#       "properties": {
#       }
#     }
#
class CourseReportsController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::CourseReport

  # @API Status of a Report
  # Returns the status of a report.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/<course_id>/reports/<report_type>/<report_id>
  #
  # @returns Report
  #
  def show
    report = @context.course_reports.active.find(params[:id])
    if authorized_action(report, @current_user, :read)
      render json: course_report_json(report, @current_user)
    end
  end

  # @API Start a Report
  # Generates a report instance for the account. Note that "report" in the
  # request must match one of the available report names.
  #
  # @argument course_id [Integer] The id of the course to report on.
  #
  # @argument report_type [String] The type of report to generate.
  #
  # @argument parameters The parameters will vary for each report.
  #   Note that the example parameters provided below may not be valid for
  #   every report.
  #
  # @argument parameters[section_ids[]] [Integer] The sections of the course to report on.
  #   Note: this parameter has been listed to serve as an example and may not be
  #   valid for every report.
  #
  # @returns Report
  #
  def create
    return render json: { error: "invalid context type" }, status: :bad_request unless @context.is_a? Course
    return render json: { error: "invalid report type #{params[:report_type]}" }, status: :bad_request unless available_reports.include? params[:report_type]

    if authorized_action(@context, @current_user, :read_reports)
      parameters = params[:parameters].permit(enrollment_ids: [], section_ids: []).to_h

      report = @context.course_reports.create(user: @current_user, course: @context, report_type: params.require(:report_type), root_account: @context.account.root_account, parameters:)
      progress = Progress.create!(context: report, tag: "course_report", completion: 0)
      strand = "course_report:#{@context.id}"
      progress.process_job(report,
                           :run_report,
                           { priority: Delayed::LOW_PRIORITY, strand: })

      render json: course_report_json(report, @current_user)
    end
  end

  # @API Status of last Report
  # Returns the status of the last report initiated by the current user.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/<course_id>/reports/<report_type>
  #
  # @returns Report
  #
  def last
    report = @context.course_reports.active.where(user: @current_user, report_type: params[:report_type]).by_recency.take
    render json: {} unless report
    render json: course_report_json(report, @current_user)
  end

  private

  def available_reports
    %w[course_pace_docx]
  end
end
