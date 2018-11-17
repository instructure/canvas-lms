#
# Copyright (C) 2018 - present Instructure, Inc.
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

# @API Outcome Imports
#
# API for importing outcome data
#
# @model OutcomeImportData
#     {
#       "id": "OutcomeImportData",
#       "description": "",
#       "properties": {
#         "import_type": {
#           "description": "The type of outcome import",
#           "example": "instructure_csv",
#           "type": "string"
#         }
#       }
#     }
#
# @model OutcomeImport
#     {
#       "id": "OutcomeImport",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the outcome import.",
#           "example": 1,
#           "type": "integer"
#         },
#         "created_at": {
#           "description": "The date the outcome import was created.",
#           "example": "2013-12-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "ended_at": {
#           "description": "The date the outcome import finished. Returns null if not finished.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The date the outcome import was last updated.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "workflow_state": {
#           "description": "The current state of the outcome import.\n - 'created': The outcome import has been created.\n - 'importing': The outcome import is currently processing.\n - 'succeeded': The outcome import has completed successfully.\n - 'failed': The outcome import failed.",
#           "example": "imported",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "created",
#               "importing",
#               "succeeded",
#               "failed"
#             ]
#           }
#         },
#         "data": {
#           "description": "See the OutcomeImportData specification above.",
#           "$ref": "OutcomeImportData"
#         },
#         "progress": {
#           "description": "The progress of the outcome import.",
#           "example": "100",
#           "type": "string"
#         },
#         "user": {
#           "description": "The user that initiated the outcome_import. See the Users API for details.",
#           "$ref": "User"
#         },
#         "processing_errors": {
#           "description": "An array of row number / error message pairs. Returns the first 25 errors.",
#           "example": [[1, "Missing required fields: title"]],
#           "type": "array",
#           "items": {
#             "type": "array",
#             "items": {"type": "object"}
#           }
#         }
#       }
#     }
#
class OutcomeImportsApiController < ApplicationController
  before_action :get_context
  include Api::V1::OutcomeImport

  class InvalidContentType < StandardError
  end

  rescue_from InvalidContentType do
    render :json => {:error => t('Invalid content type, UTF-8 required')}, :status => 400
  end

  # @API Import Outcomes
  #
  # Import outcomes into Canvas.
  #
  # For more information on the format that's expected here, please see the
  # "Outcomes CSV" section in the API docs.
  #
  # @argument import_type [String]
  #   Choose the data format for reading outcome data. With a standard Canvas
  #   install, this option can only be 'instructure_csv', and if unprovided,
  #   will be assumed to be so. Can be part of the query string.
  #
  # @argument attachment
  #   There are two ways to post outcome import data - either via a
  #   multipart/form-data form-field-style attachment, or via a non-multipart
  #   raw post request.
  #
  #   'attachment' is required for multipart/form-data style posts. Assumed to
  #   be outcome data from a file upload form field named 'attachment'.
  #
  #   Examples:
  #     curl -F attachment=@<filename> -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/outcome_imports?import_type=instructure_csv'
  #     curl -F attachment=@<filename> -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/courses/<course_id>/outcome_imports?import_type=instructure_csv'
  #
  #   If you decide to do a raw post, you can skip the 'attachment' argument,
  #   but you will then be required to provide a suitable Content-Type header.
  #   You are encouraged to also provide the 'extension' argument.
  #
  #   Examples:
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/outcome_imports?import_type=instructure_csv'
  #
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/courses/<course_id>/outcome_imports?import_type=instructure_csv'
  #
  #
  # @argument extension [String]
  #   Recommended for raw post request style imports. This field will be used to
  #   distinguish between csv and other file format extensions that
  #   would usually be provided with the filename in the multipart post request
  #   scenario. If not provided, this value will be inferred from the
  #   Content-Type, falling back to csv-file format if all else fails.
  #
  # @returns OutcomeImport
  def create
    if authorized_action(@context, @current_user, :import_outcomes)
      params[:import_type] ||= 'instructure_csv'
      raise "invalid import type parameter" unless OutcomeImport.valid_import_type?(params[:import_type])

      file_obj = nil
      if params.key?(:attachment)
        file_obj = params[:attachment]
      else
        file_obj = body_file
      end

      import = OutcomeImport.create_with_attachment(@context, params[:import_type], file_obj, @current_user)
      import.schedule

      render json: outcome_import_json(import, @current_user, session)
    end
  end

  # @API Get Outcome import status
  #
  # Get the status of an already created Outcome import. Pass 'latest' for the outcome import id
  # for the latest import.
  #
  #   Examples:
  #     curl 'https://<canvas>/api/v1/accounts/<account_id>/outcome_imports/<outcome_import_id>' \
  #         -H "Authorization: Bearer <token>"
  #     curl 'https://<canvas>/api/v1/courses/<course_id>/outcome_imports/<outcome_import_id>' \
  #         -H "Authorization: Bearer <token>"
  #
  # @returns OutcomeImport
  def show
    if authorized_action(@context, @current_user, %i(import_outcomes manage_outcomes))
      begin
        @import = if params[:id] == 'latest'
                    @context.latest_outcome_import or raise ActiveRecord::RecordNotFound
                  else
                    @context.outcome_imports.find(params[:id])
                  end
        render json: outcome_import_json(@import, @current_user, session)
      rescue ActiveRecord::RecordNotFound => e
        render json: { message: e.message }, status: :not_found
      end
    end
  end

  private

  def body_file
    file_obj = request.body

    file_obj.instance_exec do
      def set_file_attributes(filename, content_type)
        @original_filename = filename
        @content_type = content_type
      end

      def content_type
        @content_type
      end

      def original_filename
        @original_filename
      end
    end

    if params[:extension]
      file_obj.set_file_attributes("outcome_import.#{params[:extension]}",
                                   Attachment.mimetype("outcome_import.#{params[:extension]}"))
    else
      env = request.env.dup
      env['CONTENT_TYPE'] = env["ORIGINAL_CONTENT_TYPE"]
      # copy of request with original content type restored
      request2 = Rack::Request.new(env)
      charset = request2.media_type_params['charset']
      if charset.present? && charset.casecmp('utf-8') != 0
        raise InvalidContentType
      end
      params[:extension] ||= {"text/plain" => "csv",
                              "text/csv" => "csv"}[request2.media_type] || "csv"
      file_obj.set_file_attributes("outcome_import.#{params[:extension]}",
                                   request2.media_type)
      file_obj
    end
  end
end
