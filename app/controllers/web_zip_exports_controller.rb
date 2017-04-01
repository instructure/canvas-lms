#
# Copyright (C) 2016 Instructure, Inc.
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

# API Web Zip Exports
# @beta
#
# API for viewing offline exports for a course
#
#
# @model WebZipExport
#     {
#       "id": "WebZip",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the export",
#           "example": 101,
#           "type": "integer"
#         },
#         "created_at": {
#           "description": "the date and time this export was requested",
#           "example": "2014-01-01T00:00:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "the date and time this export was last updated",
#           "example": "2014-01-01T00:01:00Z",
#           "type": "datetime"
#         },
#         "zip_attachment": {
#           "description": "attachment api object for the export web zip (not present until the export completes)",
#           "example": {"url": "https://example.com/api/v1/attachments/789?download_frd=1&verifier=bG9sY2F0cyEh"},
#           "$ref": "File"
#         },
#         "progress_id": {
#           "description": "the unique identifier for the progress object",
#           "example": 5,
#           "type": "integer"
#         },
#         "progress_url": {
#           "description": "The api endpoint for polling the current progress",
#           "example": "https://example.com/api/v1/progress/4",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "The ID of the user who started the export",
#           "example": 4,
#           "type": "integer"
#         },
#         "course_id": {
#           "description": "The ID of the course the export is for",
#           "example": 2,
#           "type": "integer"
#         },
#         "content_export_id": {
#           "description": "The ID of the content export used in the offline export",
#           "example": 5,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "Current state of the web zip export: created exporting exported generating generated failed",
#           "example": "exported",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "created",
#               "exporting",
#               "exported",
#               "generating",
#               "generated",
#               "failed"
#             ]
#           }
#         }
#       }
#     }

class WebZipExportsController < ApplicationController
  include Api::V1::WebZipExport
  include WebZipExportHelper

  before_action :require_user
  before_action :require_context
  before_action :check_feature_enabled

  def check_feature_enabled
    unless course_allow_web_export_download?
      render status: 404, template: 'shared/errors/404_message'
      false
    end
  end

  # @API List all web zip exports in a course
  #
  # Lists all web zip exports in a course for the current user
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/web_zip_exports' \
  #        -H "Authorization: Bearer <token>" \
  #        -X GET
  #
  # @returns [WebZipExport]
  def index
    return render_unauthorized_action unless allow_web_export_for_course_user?

    user_web_zips = @context.web_zip_exports.visible_to(@current_user).order("created_at DESC")
    web_zips_json = Api.paginate(user_web_zips, self, api_v1_web_zip_exports_url).map do |web_zip|
      web_zip_export_json(web_zip)
    end
    render json: web_zips_json
  end

  # @API Show WebZipExport
  #
  # Get information about a single WebZipExport.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/web_zip_exports/<id>' \
  #        -H "Authorization: Bearer <token>" \
  #        -X GET
  #
  # @returns WebZipExport
  def show
    web_zip = @context.web_zip_exports.where(id: params[:id]).first
    return unless authorized_action(web_zip, @current_user, :read)
    render json: web_zip_export_json(web_zip)
  end
end
