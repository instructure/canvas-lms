#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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
#         "status": {
#           "description": "The status of the report",
#           "example": "complete",
#           "type": "string"
#         },
#         "parameters": {
#           "description": "The report parameters",
#           "$ref": "ReportParameters"
#         },
#         "progress": {
#           "description": "The progress of the report",
#           "example": "100",
#           "type": "string"
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
#           "description": "Include deleted objects",
#           "example": false,
#           "type": "boolean"
#         },
#         "course_id": {
#           "description": "The course to report on",
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
#           "description": "Get the data for users",
#           "example": false,
#           "type": "boolean"
#         },
#         "accounts": {
#           "description": "Get the data for accounts",
#           "example": false,
#           "type": "boolean"
#         },
#         "terms": {
#           "description": "Get the data for terms",
#           "example": false,
#           "type": "boolean"
#         },
#         "courses": {
#           "description": "Get the data for courses",
#           "example": false,
#           "type": "boolean"
#         },
#         "sections": {
#           "description": "Get the data for sections",
#           "example": false,
#           "type": "boolean"
#         },
#         "enrollments": {
#           "description": "Get the data for enrollments",
#           "example": false,
#           "type": "boolean"
#         },
#         "groups": {
#           "description": "Get the data for groups",
#           "example": false,
#           "type": "boolean"
#         },
#         "xlist": {
#           "description": "Get the data for cross-listed courses",
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
#           "description": "Include enrollment state. Defaults to false",
#           "example": false,
#           "type": "boolean"
#         },
#         "enrollment_state[]": {
#           "description": "Include enrollment state. Defaults to 'all' Options: ['active'| 'invited'| 'creation_pending'| 'deleted'| 'rejected'| 'completed'| 'inactive'| 'all']",
#           "example": "['all']",
#           "type": "string"
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
  before_filter :require_user
  before_filter :get_context

  include Api::V1::Account
  include Api::V1::AccountReport

# @API List Available Reports
#
# Returns the list of reports for the current context.
#
# @response_field name The name of the report.
# @response_field parameters The parameters will vary for each report
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
#      "parameters":null
#    },
#    {
#      "report":"grade_export_csv",
#      "title":"Grade Export",
#      "parameters":{
#        "term":{
#          "description":"The canvas id of the term to get grades from",
#          "required":true
#        }
#      }
#    }
#  ]
#
  def available_reports
    if authorized_action(@account, @current_user, :read_reports)
      available_reports = AccountReport.available_reports

      results = []

      available_reports.each do |key, value|
        last_run = @account.account_reports.where(:report_type => key).order('created_at DESC').first
        last_run = account_report_json(last_run, @current_user, session) if last_run
        report = {
          :title => value.title,
          :parameters => nil,
          :report => key,
          :last_run => last_run
        }
        parameters = {}

        value[:parameters].each do |parameter_name, parameter|
          parameters[parameter_name] = {
            :required => parameter[:required] || false,
            :description => parameter[:description]
          }
        end unless value[:parameters].nil?

        report[:parameters] = parameters unless parameters.length == 0
        results << report
      end
      render :json => results

    end
  end

# @API Start a Report
# Generates a report instance for the account.
#
# @argument [parameters] The parameters will vary for each report
#
# @returns Report
#
  def create
    if authorized_action(@context, @current_user, :read_reports)
      available_reports = AccountReport.available_reports.keys
      raise ActiveRecord::RecordNotFound unless available_reports.include? params[:report]
      report = @account.account_reports.build(:user=>@current_user, :report_type=>params[:report], :parameters=>params[:parameters])
      report.workflow_state = :running
      report.progress = 0
      report.save
      report.run_report
      render :json => account_report_json(report, @current_user, session)
    end
  end

  def type_scope
    @context.account_reports.where(:report_type => params[:report])
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

      reports = Api.paginate(type_scope.order('start_at DESC'), self, url_for({:action => :index, :controller => :account_reports}))

      render :json => account_reports_json(reports, @current_user, session)
    end
  end

# @API Status of a Report
# Returns the status of a report.
# @argument report_id [Integer] The report id.
#
# @example_request
#     curl -H 'Authorization: Bearer <token>' \ 
#          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>/<report_id>
#
# @returns Report
#
  def show
    if authorized_action(@context, @current_user, :read_reports)

      report = type_scope.find(params[:id])
      render :json => account_report_json(report, @current_user, session)
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
      report = type_scope.find(params[:id])

      report.destroy
      if report.destroy
        render :json => account_report_json(report, @current_user, session)
      else
        render :json => report.errors, :status => :bad_request
      end
    end
  end
end
