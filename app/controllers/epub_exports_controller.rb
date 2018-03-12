#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API ePub Exports
#
# API for exporting courses as an ePub
#
# @model CourseEpubExport
#     {
#       "id": "CourseEpubExport",
#       "description": "Combination of a Course & EpubExport.",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the course",
#           "example": 101,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name for the course",
#           "example": "Maths 101",
#           "type": "string"
#         },
#         "epub_export": {
#           "description": "ePub export API object",
#           "$ref": "EpubExport"
#         }
#       }
#     }
#
# @model EpubExport
#     {
#       "id": "EpubExport",
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
#         "attachment": {
#           "description": "attachment api object for the export ePub (not present until the export completes)",
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
#           "description": "Current state of the ePub export: created exporting exported generating generated failed",
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

class EpubExportsController < ApplicationController
  include Api::V1::EpubExport

  before_action :require_user
  before_action :require_context, :only => [:create]
  before_action :check_feature_enabled

  def check_feature_enabled
    if !@domain_root_account.feature_allowed?(:epub_export) ||
      @domain_root_account.enable_offline_web_export?
      respond_to do |format|
        format.html do
          render status: 404, template: 'shared/errors/404_message'
        end
        format.json { render status: 404 }
      end
      return false
    end
  end

  # @API List courses with their latest ePub export
  #
  # A paginated list of all courses a user is actively participating in, and
  # the latest ePub export associated with the user & course.
  #
  # @returns [CourseEpubExport]
  def index
    @presenter = EpubExports::CourseEpubExportsPresenter.new(@current_user)
    @courses = @presenter.courses

    respond_to do |format|
      format.html
      format.json do
        render json: {
          courses: @courses.map { |course| course_epub_export_json(course) }
        }
      end
    end
  end

  # @API Create ePub Export
  #
  # Begin an ePub export for a course.
  #
  # You can use the {api:ProgressController#show Progress API} to track the
  # progress of the export. The export's progress is linked to with the
  # _progress_url_ value.
  #
  # When the export completes, use the {api:EpubExportsController#show Show content export} endpoint
  # to retrieve a download URL for the exported content.
  #
  # @returns EpubExport
  def create
    if authorized_action(EpubExport.new(course: @context), @current_user, :create)
      @course = Course.find(params[:course_id])
      @service = EpubExports::CreateService.new(@course, @current_user, :epub_export)
      status = @service.save ? 201 : 422
      respond_to do |format|
        format.json do
          @course.latest_epub_export = @service.offline_export
          render({
            status: status, json: course_epub_export_json(@course)
          })
        end
      end
    end
  end

  # @API Show ePub export
  #
  # Get information about a single ePub export.
  #
  # @returns EpubExport
  def show
    @course = Course.find(params[:course_id])
    @epub_export = @course.epub_exports.where(id: params[:id]).first
    if authorized_action(@epub_export, @current_user, :read)
      respond_to do |format|
        @course.latest_epub_export = @epub_export
        format.json { render json: course_epub_export_json(@course) }
      end
    end
  end
end
