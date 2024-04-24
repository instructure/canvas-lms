# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# @API Content Exports
#
# API for exporting courses and course content
#
# @model ContentExport
#     {
#       "id": "ContentExport",
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
#         "export_type": {
#           "description": "the type of content migration: 'common_cartridge' or 'qti'",
#           "example": "common_cartridge",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "common_cartridge",
#               "qti"
#             ]
#           }
#         },
#         "attachment": {
#           "description": "attachment api object for the export package (not present before the export completes or after it becomes unavailable for download.)",
#           "example": {"url": "https://example.com/api/v1/attachments/789?download_frd=1&verifier=bG9sY2F0cyEh"},
#           "$ref": "File"
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
#         "workflow_state": {
#           "description": "Current state of the content migration: created exporting exported failed",
#           "example": "exported",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "created",
#               "exporting",
#               "exported",
#               "failed"
#             ]
#           }
#         }
#       }
#     }
#
class ContentExportsApiController < ApplicationController
  include ContentExportApiHelper
  include SupportHelpers::ControllerHelpers
  include Api::V1::ContentExport
  before_action :require_context
  before_action :require_site_admin, only: :update

  # @API List content exports
  #
  # A paginated list of the past and pending content export jobs for a course,
  # group, or user. Exports are returned newest first.
  #
  # @returns [ContentExport]
  def index
    if authorized_action(@context, @current_user, :read)
      scope = @context.content_exports_visible_to(@current_user).active.not_for_copy
      scope = scope.order("id DESC")
      route = polymorphic_url([:api_v1, @context, :content_exports])
      exports = Api.paginate(scope, self, route)
      render json: exports.map { |export| content_export_json(export, @current_user, session) }
    end
  end

  # @API Show content export
  #
  # Get information about a single content export.
  #
  # @returns ContentExport
  def show
    export = @context.content_exports.not_for_copy.find(params[:id])
    if authorized_action(export, @current_user, :read)
      render json: content_export_json(export, @current_user, session)
    end
  end

  # @API Export content
  #
  # Begin a content export job for a course, group, or user.
  #
  # You can use the {api:ProgressController#show Progress API} to track the
  # progress of the export. The migration's progress is linked to with the
  # _progress_url_ value.
  #
  # When the export completes, use the {api:ContentExportsApiController#show Show content export} endpoint
  # to retrieve a download URL for the exported content.
  #
  # @argument export_type [Required, String, "common_cartridge"|"qti"|"zip"]
  #   "common_cartridge":: Export the contents of the course in the Common Cartridge (.imscc) format
  #   "qti":: Export quizzes from a course in the QTI format
  #   "zip":: Export files from a course, group, or user in a zip file
  #
  # @argument skip_notifications [Optional, Boolean]
  #   Don't send the notifications about the export to the user. Default: false
  #
  # @argument select [Optional, Hash, "folders"|"files"|"attachments"|"quizzes"|"assignments"|"announcements"|"calendar_events"|"discussion_topics"|"modules"|"module_items"|"pages"|"rubrics"]
  #   The select parameter allows exporting specific data. The keys are object types like 'files',
  #   'folders', 'pages', etc. The value for each key is a list of object ids. An id can be an
  #   integer or a string.
  #
  #   Multiple object types can be selected in the same call. However, not all object types are
  #   valid for every export_type. Common Cartridge supports all object types. Zip and QTI only
  #   support the object types as described below.
  #
  #   "folders":: Also supported for zip export_type.
  #   "files":: Also supported for zip export_type.
  #   "quizzes":: Also supported for qti export_type.
  #
  # @returns ContentExport
  def create
    if authorized_action(@context, @current_user, :read)
      valid_types = %w[zip]
      valid_types += %w[qti common_cartridge quizzes2] if @context.is_a?(Course)
      return render json: { message: "invalid export_type" }, status: :bad_request unless valid_types.include?(params[:export_type])

      export = create_content_export_from_api(params, @context, @current_user)
      return unless export.instance_of?(ContentExport)

      if export.id
        includes = Array(params[:include]) || []
        render json: content_export_json(export, @current_user, session, includes)
      else
        render json: export.errors, status: :bad_request
      end
    end
  end

  def fail
    if authorized_action(Account.site_admin, @current_user, :read)
      export = @context.content_exports.find(params[:id])
      export_fail_with_error export, "manually marked failed by a site administrator"
      render json: content_export_json(export, @current_user, session)
    end
  end

  def content_list
    if authorized_action(@context, @current_user, :read_as_admin)
      base_url = polymorphic_url([:api_v1, @context, :content_list])
      formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(nil,
                                                                            base_url,
                                                                            global_identifiers: @context.content_exports.temp_record.can_use_global_identifiers?)

      unless formatter.valid_type?(params[:type])
        return render json: { message: "unsupported migration type" }, status: :bad_request
      end

      render json: formatter.get_content_list(params[:type], @context)
    end
  end

  def update
    export = @context.content_exports.common_cartridge.find(params[:id])

    if export.update(update_params)
      export.export if export.new_quizzes_export_state_completed?
      export_fail_with_error(export, "New Quizzes failed to export") if export.new_quizzes_export_state_failed?
      render json: content_export_json(export, @current_user, session, ["new_quizzes_export_settings"])
    else
      render json: export.errors, status: :bad_request
    end
  end

  private

  def update_params
    params.require(:content_export).permit(:new_quizzes_export_state, :new_quizzes_export_url)
  end

  def export_fail_with_error(export, msg)
    export.fail_with_error! @current_user.global_id, error_message: msg
  end
end
