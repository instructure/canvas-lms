#
# Copyright (C) 2012 Instructure, Inc.
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
# @object report
#     {
#       // The unique identifier for the report.
#       "id": 1,
#
#       // The type of report.
#       "report": "sis_export_csv",
#
#       // The url to the report download.
#       "file_url": "https://example.com/some/path",
#
#       // The status of the report
#       "complete",
#
#       // The report parameters
#       {"enrollment_term":"2","sis_terms_csv":"1","sis_accounts_csv":"1"},
#
#       // The progress of the report
#       "100",
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
#    {"id":"student_assignment_outcome_map_csv",
#    "title":"Student Competency",
#    "parameters":null
#    },
#    {"report":"grade_export_csv",
#    "title":"Grade Export",
#    "parameters":{
#      "term":{
#        "description":"The canvas id of the term to get grades from",
#        "required":true
#        }
#      }
#    }
#  ]
#
  def available_reports
    if authorized_action(@account, @current_user, :read_reports)
      available_reports = AccountReport.available_reports(@account)

      results = []

      available_reports.each do |key, value|
        last_run = @account.account_reports.scoped(:conditions => { :report_type => key }, :order => 'created_at DESC').first
        last_run = account_report_json(last_run, @current_user, session) if last_run
        report = {
          :title => value[:title],
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
      render :json => results.to_json

    end
  end

# @API Start a Report
# Generates a report instance for the account.
#
# @argument [parameters] The parameters will vary for each report
#
# @returns report
#
  def create
    if authorized_action(@context, @current_user, :read_reports)
      report = @account.account_reports.build(:user=>@current_user, :report_type=>params[:report], :parameters=>params[:parameters])
      report.workflow_state = :running
      report.progress = 0
      report.save
      report.run_report
      render :json => account_report_json(report, @current_user, session)
    end
  end

  def type_scope
    @context.account_reports.scoped(:conditions => { :report_type => params[:report]})
  end

# @API Index of Reports
# Shows all reports that have been run for the account of a specific type.
#
# @example_request
#     curl -H 'Authorization: Bearer <token>' \ 
#          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>
#
# @returns [report]
#
  def index
    if authorized_action(@context, @current_user, :read_reports)

      reports = Api.paginate(type_scope, self, url_for({:action => :index, :controller => :account_reports}),
                             :order => 'start_at DESC')

      render :json => account_reports_json(reports, @current_user, session)
    end
  end

# @API Status of a Report
# Returns the status of a report.
# @argument [report_id] The report id.
#
# @example_request
#     curl -H 'Authorization: Bearer <token>' \ 
#          https://<canvas>/api/v1/accounts/<account_id>/reports/<report_type>/<report_id>
#
# @returns report
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
# @returns report
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
