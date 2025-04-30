# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

# @API Account Reports
#
# API for accessing account reports.
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
#         "report": {
#           "description": "The type of report.",
#           "example": "sis_export_csv",
#           "type": "string"
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
#         },
#         "current_line": {
#           "description": "This is the current line count being written to the report. It updates every 1000 records.",
#           "example": "12000",
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
#         "enrollment_term_id": {
#           "description": "The canvas id of the term to get grades from",
#           "example": 2,
#           "type": "integer"
#         },
#         "include_deleted": {
#           "description": "If true, deleted objects will be included. If false, deleted objects will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "course_id": {
#           "description": "The id of the course to report on",
#           "example": 2,
#           "type": "integer"
#         },
#         "order": {
#           "description": "The sort order for the csv, Options: 'users', 'courses', 'outcomes'.",
#           "example": "users",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "users",
#               "courses",
#               "outcomes"
#             ]
#           }
#         },
#         "users": {
#           "description": "If true, user data will be included. If false, user data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "accounts": {
#           "description": "If true, account data will be included. If false, account data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "terms": {
#           "description": "If true, term data will be included. If false, term data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "courses": {
#           "description": "If true, course data will be included. If false, course data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "sections": {
#           "description": "If true, section data will be included. If false, section data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "enrollments": {
#           "description": "If true, enrollment data will be included. If false, enrollment data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "groups": {
#           "description": "If true, group data will be included. If false, group data will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "xlist": {
#           "description": "If true, data for crosslisted courses will be included. If false, data for crosslisted courses will be omitted.",
#           "example": false,
#           "type": "boolean"
#         },
#         "sis_terms_csv": {
#           "example": 1,
#           "type": "integer"
#         },
#         "sis_accounts_csv": {
#           "example": 1,
#           "type": "integer"
#         },
#         "include_enrollment_state": {
#           "description": "If true, enrollment state will be included. If false, enrollment state will be omitted. Defaults to false.",
#           "example": false,
#           "type": "boolean"
#         },
#         "enrollment_state": {
#           "description": "Include enrollment state. Defaults to 'all' Options: ['active'| 'invited'| 'creation_pending'| 'deleted'| 'rejected'| 'completed'| 'inactive'| 'all']",
#           "example": ["all"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "start_at": {
#           "description": "The beginning date for submissions. Max time range is 2 weeks.",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "The end date for submissions. Max time range is 2 weeks.",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
class AccountReportsController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::Account
  include Api::V1::AccountReport

  # allows `render_to_string` to find partials there
  def self.local_prefixes
    super + ["accounts"]
  end

  # @API List Available Reports
  #
  # Returns a paginated list of reports for the current context.
  #
  # @argument include[] [String, "description_html"|"params_html"]
  #   Array of additional information to include.
  #
  #   "description_html":: an HTML description of the report, with example output
  #   "parameters_html":: an HTML form for the report parameters
  #
  # @response_field name The name of the report.
  # @response_field parameters The parameters will vary for each report
  # @response_field last_run [Report] The last run of the report. This will be null if the report has never been run.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/accounts/<account_id>/reports/
  #
  # @example_response
  #
  #  [
  #    {
  #      "report":"student_assignment_outcome_map_csv",
  #      "title":"Student Competency",
  #      "parameters":null,
  #      "last_run": {
  #        "id": 1,
  #        "report": "student_assignment_outcome_map_csv",
  #        "file_url": "https://example.com/some/path",
  #        "status": "complete",
  #        "created_at": "2013-12-01T23:59:00-06:00",
  #        "started_at": "2013-12-02T00:03:21-06:00",
  #        "ended_at": "2013-12-02T00:03:21-06:00"
  #    },
  #    {
  #      "report":"grade_export_csv",
  #      "title":"Grade Export",
  #      "parameters":{
  #        "term":{
  #          "description":"The canvas id of the term to get grades from",
  #          "required":true
  #        }
  #      },
  #      "last_run": null
  #    }
  #  ]
  #
  def available_reports
    if authorized_action(@account, @current_user, :read_reports)
      @root_account = @account.root_account # used in partials
      available_reports = AccountReport.available_reports
      includes = Array(params[:include])

      results = []
      last_runs = AccountReport.last_reports(account: @account)

      available_reports.each do |key, value|
        last_run = account_report_json(last_runs[key], @current_user) if last_runs.key?(key)

        report = {
          title: value.title,
          parameters: nil,
          report: key,
          last_run:
        }
        parameters = {}

        value.parameters.each do |parameter_name, parameter|
          parameters[parameter_name] = {
            required: parameter[:required] || false,
            description: parameter[:description]
          }
        end

        report[:parameters] = parameters unless parameters.empty?

        add_description_partials(report, key, value, includes)

        results << report
      end
      render json: results.sort_by { |r| r[:title] }

    end
  end

  # @API Start a Report
  # Generates a report instance for the account. Note that "report" in the
  # request must match one of the available report names. To fetch a list of
  # available report names and parameters for each report (including whether or
  # not those parameters are required), see
  # {api:AccountReportsController#available_reports List Available Reports}.
  #
  # @argument parameters The parameters will vary for each report. To fetch a list
  #   of available parameters for each report, see {api:AccountReportsController#available_reports List Available Reports}.
  #   A few example parameters have been provided below. Note that the example
  #   parameters provided below may not be valid for every report.
  #
  # @argument parameters[skip_message] [Boolean] If true, no message will be sent
  #   to the user upon completion of the report.
  #
  # @argument parameters[course_id] [Integer] The id of the course to report on.
  #   Note: this parameter has been listed to serve as an example and may not be
  #   valid for every report.
  #
  # @argument parameters[users] [Boolean] If true, user data will be included. If
  #   false, user data will be omitted. Note: this parameter has been listed to
  #   serve as an example and may not be valid for every report.
  #
  # @example_request
  #   curl -X POST \
  #        https://<canvas>/api/v1/accounts/1/reports/provisioning_csv \
  #        -H 'Authorization: Bearer <token>' \
  #        -H 'Content-Type: multipart/form-data' \
  #        -F 'parameters[users]=true' \
  #        -F 'parameters[courses]=true' \
  #        -F 'parameters[enrollments]=true'
  #
  # @returns Report
  #
  def create
    if authorized_action(@context, @current_user, :read_reports)
      available_reports = AccountReport.available_reports.keys
      raise ActiveRecord::RecordNotFound unless available_reports.include? params[:report]

      parameters = params[:parameters]&.to_unsafe_h
      enrollment_term_id = parameters&.dig("enrollment_term_id") || parameters&.dig("enrollment_term")
      if enrollment_term_id.present? && !valid_enrollment_term_id?(enrollment_term_id)
        return render json: { error: "invalid enrollment_term_id '#{enrollment_term_id}'" }, status: :bad_request
      end

      report = @account.account_reports.build(user: @current_user, report_type: params[:report], parameters:)
      report.workflow_state = :created
      report.progress = 0
      report.save
      report.run_report
      render json: account_report_json(report, @current_user)
    end
  end

  def valid_enrollment_term_id?(enrollment_term_id)
    enrollment_term_id == "active_terms" || api_find_all(@account.root_account.enrollment_terms, enrollment_term_id.to_s.split(",")).exists?
  end

  def type_scope
    @context.account_reports.where(report_type: params[:report])
  end

  # @API Index of Reports
  # Shows all reports that have been run for the account of a specific type.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>
  #
  # @returns [Report]
  #
  def index
    if authorized_action(@context, @current_user, :read_reports)
      reports = Api.paginate(type_scope.active.most_recent.except(:limit), self, url_for({ action: :index, controller: :account_reports }))

      render json: account_reports_json(reports, @current_user)
    end
  end

  # @API Status of a Report
  # Returns the status of a report.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>/<report_id>
  #
  # @returns Report
  #
  def show
    if authorized_action(@context, @current_user, :read_reports)

      report = type_scope.active.find(params[:id])
      render json: account_report_json(report, @current_user)
    end
  end

  # @API Delete a Report
  #
  # Deletes a generated report instance.
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          -X DELETE \
  #          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>/<id>
  #
  # @returns Report
  #
  def destroy
    if authorized_action(@context, @current_user, :read_reports)
      report = type_scope.active.find(params[:id])

      if report.destroy
        render json: account_report_json(report, @current_user)
      else
        render json: report.errors, status: :bad_request
      end
    end
  end

  # @API Abort a Report
  #
  # Abort a report in progress
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          -X PUT \
  #          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>/<id>/abort
  #
  # @returns Report
  #
  def abort
    if authorized_action(@context, @current_user, :read_reports)
      report = type_scope.running.find(params[:id])

      if report.update(workflow_state: "aborted")
        render json: account_report_json(report, @current_user)
      else
        render json: report.errors, status: :bad_request
      end
    end
  end

  private

  def add_description_partials(json, report, report_details, includes)
    if includes.include?("description_html") && report_details.respond_to?(:description_partial)
      description_partial = report_details.description_partial
      if description_partial.present?
        description_partial = report + "_description" if description_partial == true
        json[:description_html] = render_to_string(
          partial: description_partial,
          layout: false,
          locals: { report:, report_details: },
          formats: [:html]
        )
      end
    end

    if includes.include?("parameters_html") && report_details.respond_to?(:parameters_partial)
      parameters_partial = report_details.parameters_partial
      if parameters_partial.present?
        parameters_partial = report + "_parameters" if parameters_partial == true
        json[:parameters_html] = <<~HTML
          <form id="#{report}_form" class="run_report_form" action="#{api_v1_account_create_report_path(@account, report)}">
          #{
            render_to_string(
              partial: parameters_partial,
              layout: false,
              locals: { report:, report_details: },
              formats: [:html]
            )
          }
          </form>
        HTML
      end
    end

    json
  end
end
