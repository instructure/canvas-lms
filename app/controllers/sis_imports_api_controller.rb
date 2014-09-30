#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

# @API SIS Imports
#
# API for importing data from Student Information Systems
#
# @model SisImportData
#     {
#       "id": "SisImportData",
#       "description": "",
#       "properties": {
#         "import_type": {
#           "description": "The type of SIS import",
#           "example": "instructure_csv",
#           "type": "string"
#         },
#         "supplied_batches": {
#           "description": "Which file were included in the SIS import",
#           "example": "[\"term\", \"course\", \"section\", \"user\", \"enrollment\"]",
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "counts": {
#           "description": "The number of rows processed for each type of import",
#           "$ref": "SisImportCounts"
#         }
#       }
#     }
#
# @model SisImportCounts
#     {
#       "id": "SisImportCounts",
#       "description": "",
#       "properties": {
#         "accounts": {
#           "example": 0,
#           "type": "integer"
#         },
#         "terms": {
#           "example": 3,
#           "type": "integer"
#         },
#         "abstract_courses": {
#           "example": 0,
#           "type": "integer"
#         },
#         "courses": {
#           "example": 121,
#           "type": "integer"
#         },
#         "sections": {
#           "example": 278,
#           "type": "integer"
#         },
#         "xlists": {
#           "example": 0,
#           "type": "integer"
#         },
#         "users": {
#           "example": 346,
#           "type": "integer"
#         },
#         "enrollments": {
#           "example": 1542,
#           "type": "integer"
#         },
#         "groups": {
#           "example": 0,
#           "type": "integer"
#         },
#         "group_memberships": {
#           "example": 0,
#           "type": "integer"
#         },
#         "grade_publishing_results": {
#           "example": 0,
#           "type": "integer"
#         }
#       }
#     }
#
# @model SisImport
#     {
#       "id": "SisImport",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the SIS import.",
#           "example": 1,
#           "type": "integer"
#         },
#         "created_at": {
#           "description": "The date the SIS import was created.",
#           "example": "2013-12-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "ended_at": {
#           "description": "The date the SIS import finished. Returns null if not finished.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The date the SIS import was last updated.",
#           "example": "2013-12-02T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "workflow_state": {
#           "description": "The current state of the SIS import. - 'created': The SIS import has been created.\n - 'importing': The SIS import is currently processing.\n - 'imported': The SIS import has completed successfully.\n - 'imported_with_messages': The SIS import completed with errors or warnings.\n - 'failed_with_messages': The SIS import failed with errors.\n - 'failed': The SIS import failed.",
#           "example": "imported",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "created",
#               "imported",
#               "imported_with_messages",
#               "failed_with_messages",
#               "failed"
#             ]
#           }
#         },
#         "data": {
#           "description": "data",
#           "$ref": "SisImportData"
#         },
#         "progress": {
#           "description": "The progress of the SIS import.",
#           "example": "100",
#           "type": "string"
#         },
#         "processing_warnings": {
#           "description": "Only imports that are complete will get this data. An array of CSV_file/warning_message pairs.",
#           "example": "[['students.csv','user John Doe has already claimed john_doe's requested login information, skipping'], ...]",
#           "type": "array",
#           "items": {
#             "$ref": "Array"
#           }
#         },
#         "processing_errors": {
#           "description": "An array of CSV_file/error_message pairs.",
#           "example": "[['students.csv','Error while importing CSV. Please contact support.'], ...]",
#           "type": "array",
#           "items": {
#             "$ref": "Array"
#           }
#         },
#         "batch_mode": {
#           "description": "Whether the import was run in batch mode.",
#           "example": "true",
#           "type": "boolean"
#         },
#         "batch_mode_term_id": {
#           "description": "The term the batch was limited to.",
#           "example": "1234",
#           "type": "string"
#         },
#         "override_sis_stickiness": {
#           "description": "Whether UI changes were overridden.",
#           "example": "false",
#           "type": "boolean"
#         },
#         "add_sis_stickiness": {
#           "description": "Whether stickiness was added to the batch changes.",
#           "example": "false",
#           "type": "boolean"
#         },
#         "clear_sis_stickiness": {
#           "description": "Whether stickiness was cleared.",
#           "example": "false",
#           "type": "boolean"
#         }
#       }
#     }
#
class SisImportsApiController < ApplicationController
  before_filter :get_context
  before_filter :check_account

  def check_account
    raise "SIS imports can only be executed on root accounts" unless @account.root_account?
    raise "SIS imports can only be executed on enabled accounts" unless @account.allow_sis_import
  end

  # @API Get SIS import list
  #
  # Returns the list of SIS imports for an account
  #
  #   Examples:
  #     curl 'https://<canvas>/api/v1/accounts/<account_id>/sis_imports' \
  #         -H "Authorization: Bearer <token>"
  #
  # @returns [SisImport]
  def index
    if authorized_action(@account, @current_user, :manage_sis)
      @batches = Api.paginate(@account.sis_batches.order('created_at DESC'), self, url_for({action: :index, controller: :sis_imports_api}))
      render :json => ({ sis_imports: @batches})
    end
  end

  # @API Import SIS data
  #
  # Import SIS data into Canvas. Must be on a root account with SIS imports
  # enabled.
  #
  # For more information on the format that's expected here, please see the
  # "SIS CSV" section in the API docs.
  #
  # @argument import_type [String]
  #   Choose the data format for reading SIS data. With a standard Canvas
  #   install, this option can only be 'instructure_csv', and if unprovided,
  #   will be assumed to be so. Can be part of the query string.
  #
  # @argument attachment
  #   There are two ways to post SIS import data - either via a
  #   multipart/form-data form-field-style attachment, or via a non-multipart
  #   raw post request.
  #
  #   'attachment' is required for multipart/form-data style posts. Assumed to
  #   be SIS data from a file upload form field named 'attachment'.
  #
  #   Examples:
  #     curl -F attachment=@<filename> -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?import_type=instructure_csv'
  #
  #   If you decide to do a raw post, you can skip the 'attachment' argument,
  #   but you will then be required to provide a suitable Content-Type header.
  #   You are encouraged to also provide the 'extension' argument.
  #
  #   Examples:
  #     curl -H 'Content-Type: application/octet-stream' --data-binary @<filename>.zip \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?import_type=instructure_csv&extension=zip'
  #
  #     curl -H 'Content-Type: application/zip' --data-binary @<filename>.zip \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?import_type=instructure_csv'
  #
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?import_type=instructure_csv'
  #
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv \
  #         -H "Authorization: Bearer <token>" \
  #         'https://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?import_type=instructure_csv&batch_mode=1&batch_mode_term_id=15'
  #
  # @argument extension [String]
  #   Recommended for raw post request style imports. This field will be used to
  #   distinguish between zip, xml, csv, and other file format extensions that
  #   would usually be provided with the filename in the multipart post request
  #   scenario. If not provided, this value will be inferred from the
  #   Content-Type, falling back to zip-file format if all else fails.
  #
  # @argument batch_mode [Boolean]
  #   If set, this SIS import will be run in batch mode, deleting any data
  #   previously imported via SIS that is not present in this latest import.
  #   See the SIS CSV Format page for details.
  #
  # @argument batch_mode_term_id [String]
  #   Limit deletions to only this term. Required if batch mode is enabled.
  #
  # @argument override_sis_stickiness [Boolean]
  #   Many fields on records in Canvas can be marked "sticky," which means that
  #   when something changes in the UI apart from the SIS, that field gets
  #   "stuck." In this way, by default, SIS imports do not override UI changes.
  #   If this field is present, however, it will tell the SIS import to ignore
  #   "stickiness" and override all fields.
  #
  # @argument add_sis_stickiness [Boolean]
  #   This option, if present, will process all changes as if they were UI
  #   changes. This means that "stickiness" will be added to changed fields.
  #   This option is only processed if 'override_sis_stickiness' is also provided.
  #
  # @argument clear_sis_stickiness [Boolean]
  #   This option, if present, will clear "stickiness" from all fields touched
  #   by this import. Requires that 'override_sis_stickiness' is also provided.
  #   If 'add_sis_stickiness' is also provided, 'clear_sis_stickiness' will
  #   overrule the behavior of 'add_sis_stickiness'
  #
  # @returns SisImport
  def create
    if authorized_action(@account, @current_user, :manage_sis)
      params[:import_type] ||= 'instructure_csv'
      raise "invalid import type parameter" unless SisBatch.valid_import_types.has_key?(params[:import_type])

      if !api_request? && @account.current_sis_batch.try(:importing?)
        return render :json => {:error=>true, :error_message=> t(:sis_import_in_process_notice, "An SIS import is already in process."), :batch_in_progress=>true},
               :as_text => true
      end

      file_obj = nil
      if params.has_key?(:attachment)
        file_obj = params[:attachment]
      else
        file_obj = request.body
        def file_obj.set_file_attributes(filename, content_type)
          @original_filename = filename
          @content_type = content_type
        end
        def file_obj.content_type; @content_type; end
        def file_obj.original_filename; @original_filename; end
        if params[:extension]
          file_obj.set_file_attributes("sis_import.#{params[:extension]}",
                                Attachment.mimetype("sis_import.#{params[:extension]}"))
        else
          env = request.env.dup
          env['CONTENT_TYPE'] = env["ORIGINAL_CONTENT_TYPE"]
          # copy of request with original content type restored
          request2 = Rack::Request.new(env)
          charset = request2.media_type_params['charset']
          if charset.present? && charset.downcase != 'utf-8'
            return render :json => { :error => t('errors.invalid_content_type', "Invalid content type, UTF-8 required") }, :status => 400
          end
          params[:extension] ||= {"application/zip" => "zip",
                                  "text/xml" => "xml",
                                  "text/plain" => "csv",
                                  "text/csv" => "csv"}[request2.media_type] || "zip"
          file_obj.set_file_attributes("sis_import.#{params[:extension]}",
                                request2.media_type)
        end
      end

      batch_mode_term = nil
      if value_to_boolean(params[:batch_mode])
        if params[:batch_mode_term_id].present?
          batch_mode_term = api_find(@account.enrollment_terms.active,
                                           params[:batch_mode_term_id])
        end
        unless batch_mode_term
          return render :json => { :message => "Batch mode specified, but the given batch_mode_term_id cannot be found." }, :status => :bad_request
        end
      end

      batch = SisBatch.create_with_attachment(@account, params[:import_type], file_obj, @current_user) do |batch|
        if batch_mode_term
          batch.batch_mode = true
          batch.batch_mode_term = batch_mode_term
        end

        batch.options ||= {}
        if value_to_boolean(params[:override_sis_stickiness])
          batch.options[:override_sis_stickiness] = true
          [:add_sis_stickiness, :clear_sis_stickiness].each do |option|
            batch.options[option] = true if value_to_boolean(params[option])
          end
        end
      end

      unless Setting.get('skip_sis_jobs_account_ids', '').split(',').include?(@account.global_id.to_s)
        batch.process
      end

      unless api_request?
        @account.current_sis_batch_id = batch.id
        @account.save
      end

      render :json => batch
    end
  end

  # @API Get SIS import status
  #
  # Get the status of an already created SIS import.
  #
  #   Examples:
  #     curl 'https://<canvas>/api/v1/accounts/<account_id>/sis_imports/<sis_import_id>' \
  #         -H "Authorization: Bearer <token>"
  #
  # @returns SisImport
  def show
    if authorized_action(@account, @current_user, :manage_sis)
      @batch = SisBatch.find(params[:id])
      raise "Sis Import not found" unless @batch
      raise "Batch does not match account" unless @batch.account.id == @account.id
      render :json => @batch
    end
  end

end
