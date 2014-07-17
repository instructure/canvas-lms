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

# @API Content Exports
# @beta
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
#           "description": "attachment api object for the export package (not present until the export completes)",
#           "example": "{\"url\"=>\"https://example.com/api/v1/attachments/789?download_frd=1&verifier=bG9sY2F0cyEh\"}",
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
  include Api::V1::ContentExport
  before_filter :require_context

  # @API List content exports
  #
  # List the past and pending content export jobs for a course, group, or user.
  # Exports are returned newest first.
  #
  # @returns [ContentExport]
  def index
    if authorized_action(@context, @current_user, :read)
      scope = @context.content_exports_visible_to(@current_user).active.not_for_copy
      scope = scope.order('id DESC')
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
  # @argument export_type [String, "common_cartridge"|"qti"]
  #   "common_cartridge":: Export the contents of a course in the Common Cartridge (.imscc) format
  #   "qti":: Export quizzes from a course in the QTI format
  #   "zip":: Export files from a course, group, or user in a zip file
  #
  # @returns ContentExport
  def create
    if authorized_action(@context, @current_user, :read)
      valid_types = %w(zip)
      valid_types += %w(qti common_cartridge) if @context.is_a?(Course)
      return render json: { message: 'invalid export_type' }, status: :bad_request unless valid_types.include?(params[:export_type])
      export = @context.content_exports.build
      export.user = @current_user
      export.workflow_state = 'created'

      # ZipExporter accepts unhashed asset strings, to avoid having to instantiate all the files and folders
      selected_content = ContentMigration.process_copy_params(params[:select], true, params[:export_type] == ContentExport::ZIP) if params[:select]
      case params[:export_type]
      when 'qti'
        export.export_type = ContentExport::QTI
        export.selected_content = selected_content || { all_quizzes: true }
      when 'zip'
        export.export_type = ContentExport::ZIP
        export.selected_content = selected_content || { all_attachments: true }
      else
        export.export_type = ContentExport::COMMON_CARTRIDGE
        export.selected_content = selected_content || { everything: true }
      end
      # recheck, since the export type influences permissions (e.g., students can download zips of non-locked files, but not common cartridges)
      return unless authorized_action(export, @current_user, :create)

      opts = params.slice(:version)
      export.progress = 0
      if export.save
        export.queue_api_job(opts)
        render json: content_export_json(export, @current_user, session)
      else
        render json: export.errors, status: :bad_request
      end
    end
  end

  def content_list
    if authorized_action(@context, @current_user, :read_as_admin)
      base_url = polymorphic_url([:api_v1, @context, :content_list])
      formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(nil, base_url)

      unless formatter.valid_type?(params[:type])
        return render :json => {:message => "unsupported migration type"}, :status => :bad_request
      end

      render :json => formatter.get_content_list(params[:type], @context)
    end
  end
end
