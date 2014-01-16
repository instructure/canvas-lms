#
# Copyright (C) 2014 Instructure, Inc.
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

# @API Data Exports
# @beta
#
# API for exporting all data associated with a given account during a given term
#
# @model DataExport
#   {
#     "id": "DataExport",
#     "description": "Status of queued export",
#     "properties": {
#       "id": {
#         "description": "the unique identifier for the export job",
#         "example": 101,
#         "type": "int"
#       },
#
#       "created_at": {
#         "description": "the date and time this dump was requested",
#         "example": "2014-01-01T00:00:00Z",
#         "type": "datetime"
#       },
#
#       "user": {
#         "description": "the user who initiated the export",
#         "example": 4,
#         "type": "int"
#       },
#
#       "workflow_state": {
#         "description": "the execution status of the export",
#         "example": "processing",
#         "type": "string"
#       },
#
#       "links": {
#         "progress": {
#           "id": "DataExportProgress"
#           "description": "Link object containing polling endpoint for currently queued export job"
#           "properties": {
#             "href": {
#               "description": "the api endpoint for polling the current progress",
#               "example": "https://example.com/api/v1/progress/4",
#               "type": "string"
#             }
#           }
#         }
#       }
#     }
#   }
#

module DataExportsApi
  class DataExportsApiController < ::ApplicationController
    include Api::V1::DataExport

    before_filter :require_context
    before_filter :check_permissions

    def check_permissions
      authorized_action(@context, @current_user, :manage_data_exports)
    end

    # @API List data dumps
    #
    # List the past and pending data exports for the account
    # Returned most recent first.
    #
    # @returns [DataExport]
    def index
      render json: {data_exports: data_exports_json(Api.paginate(DataExport.for(@context), self, api_v1_data_export_url(@context)), @current_user, session, [:user, :account])}
    end

    # @API Show data export
    #
    # Get information about a single data export.
    #
    # @returns DataExport
    def show
      dd = DataExport.for(@context).find(params[:id])
      render json: {data_exports: [data_export_json(dd, @current_user, session, [:account, :user])]}
    end

    # @API Cancel data export
    #
    # Unqueue a queued data export, or cancel one that is currently executing
    #
    # This does not affect exports already marked as completed, cancelled, or failed
    #
    # On success, the response will be 204 No Content with an empty body
    #
    # @example_request
    #
    #   curl 'https://<canvas>/api/v1/accounts/<account_id>/data_exports/<data_export_id> \
    #        -X DELETE \
    #        -H "Authorization: Bearer <token>" \
    #        -H "Content-Length: 0"
    def cancel
      DataExport.for(@context).find(params[:id]).cancel
      render :nothing => true, :status => :no_content
    end

    # @API Export all data associated with the given account for the given dates
    #
    # Begin a data_export job for a given account and term
    #
    # You can use the {api:ProgressController#show Progress API} to track the
    # progress of the export. The migration's progress is accessible at the url
    # contained in the linked progress object
    #
    # When the process completes, use the {api:DataExportsApiController#show Show content export}
    # endpoint to retrieve a download URL for the data.
    #
    # @returns DataExport
    def create
      dd = DataExport.for(@context).build(user: @current_user)
      if dd.save!
        # TODO: enqueue job here
        render json: {data_exports: [data_export_json(dd, @current_user, session)]}, :status => :created
      else
        render json: dd.errors, status: :bad_request
      end
    end

  end
end
