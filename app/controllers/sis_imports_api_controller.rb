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

# @API SIS Imports
#
# API for importing data from Student Information Systems
class SisImportsApiController < ApplicationController
  before_filter :get_context
  before_filter :check_account

  def check_account
    raise "SIS imports can only be executed on root accounts" if @account.root_account_id
    raise "SIS imports can only be executed on enabled accounts" unless @account.allow_sis_import
  end

  # @API
  #
  # Import SIS data into Canvas. Must be on a root account with SIS imports enabled.
  #
  # For more information on the format that's expected here, please see our
  # documentation at http://github.com/instructure/canvas-lms/raw/stable/public/resources/CanvasSISImport.pdf
  #
  # There are two ways to post SIS import data - either via a multipart/form-data
  # form-field-style attachment, or via a non-multipart raw post request. For the
  # latter to work, you must provide a suitable Content-Type header.
  #
  # @argument import_type Choose the data format for reading SIS data. With a
  #   standard Canvas install, this option can only be 'instructure_csv',
  #   and if unprovided, will be assumed to be so. Can be part of the query string.
  #
  # @argument attachment Required for multipart/form-data style posts. Assumed to be SIS data from a file
  #   upload form field named 'attachment'.
  #
  #   Examples:
  #     curl -F attachment=@<filename> -u '<username>:<password>' \ 
  #         'http://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?api_key=<key>&import_type=instructure_csv'
  #
  # @argument extension Recommended for raw post request style imports. This
  #   field will be used to distinguish between zip, xml, csv, and other file
  #   format extensions that would usually be provided with the filename in the
  #   multipart post request scenario. If not provided, this value will be
  #   inferred from the Content-Type, falling back to zip-file format if all
  #   else fails.
  #
  # @argument batch_mode ["1"] If set, this SIS import will be run in batch mode, deleting any data previously imported via SIS that is not present in this latest import.  See the PDF document for details.
  #
  # @argument batch_mode_term_id Limit deletions to only this term, if batch
  #   mode is enabled.
  #
  #   Examples:
  #     curl -H 'Content-Type: application/octet-stream' --data-binary @<filename>.zip -u '<username>:<password>' \ 
  #         'http://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?api_key=<key>&import_type=instructure_csv&extension=zip'
  #     curl -H 'Content-Type: application/zip' --data-binary @<filename>.zip -u '<username>:<password>' \ 
  #         'http://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?api_key=<key>&import_type=instructure_csv'
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv -u '<username>:<password>' \ 
  #         'http://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?api_key=<key>&import_type=instructure_csv'
  #     curl -H 'Content-Type: text/csv' --data-binary @<filename>.csv -u '<username>:<password>' \ 
  #         'http://<canvas>/api/v1/accounts/<account_id>/sis_imports.json?api_key=<key>&import_type=instructure_csv&batch_mode=1&batch_mode_term_id=15'
  def create
    if authorized_action(@account, @current_user, :manage)
      params[:import_type] ||= 'instructure_csv'
      raise "invalid import type parameter" unless SisBatch.valid_import_types.has_key?(params[:import_type])
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
      batch = SisBatch.create_with_attachment(@account, params[:import_type], file_obj)

      if params[:batch_mode].to_i > 0
        batch.batch_mode = true
        if params[:batch_mode_term_id].present?
          batch.batch_mode_term = api_find(@account.enrollment_terms.active,
                                           params[:batch_mode_term_id])
        end
      end

      batch.options ||= {}
      if params[:override_sis_stickiness].to_i > 0
        batch.options[:override_sis_stickiness] = true
        [:add_sis_stickiness, :clear_sis_stickiness].each do |option|
          batch.options[option] = true if params[option].to_i > 0
        end
      end

      batch.save!

      batch.process
      render :json => batch.api_json
    end
  end

  # @API
  #
  # Get the status of an already created SIS import.
  def show
    if authorized_action(@account, @current_user, :manage)
      @batch = SisBatch.find(params[:id])
      raise "Sis Import not found" unless @batch
      raise "Batch does not match account" unless @batch.account.id == @account.id
      render :json => @batch.api_json
    end
  end

end
