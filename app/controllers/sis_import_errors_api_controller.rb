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

# @API SIS Import Errors
#
#
# @model SisImportError
#     {
#       "id": "SisImportError",
#       "description": "",
#       "properties": {
#         "sis_import_id": {
#           "description": "The unique identifier for the SIS import.",
#           "example": "1",
#           "type": "integer"
#         },
#         "file": {
#           "description": "The file where the error message occurred.",
#           "example": "courses.csv",
#           "type": "string"
#         },
#         "message": {
#           "description": "The error message that from the record.",
#           "example": "No short_name given for course C001",
#           "type": "string"
#         },
#         "row_info": {
#           "description": "The contents of the line that had the error.",
#           "example": "account_1, Sub account 1,, active ",
#           "type": "string"
#         },
#         "row": {
#           "description": "The line number where the error occurred. Some Importers do not yet support this. This is a 1 based index starting with the header row.",
#           "example": "34",
#           "type": "integer"
#         }
#       }
#     }
#
class SisImportErrorsApiController < ApplicationController
  before_action :get_context
  before_action :check_account
  include Api::V1::SisImportError

  def check_account
    return render json: {errors: ["SIS imports can only be executed on root accounts"]}, status: :bad_request unless @account.root_account?
    return render json: {errors: ["SIS imports are not enabled for this account"]}, status: :forbidden unless @account.allow_sis_import
  end

  # @API Get SIS import error list
  #
  # Returns the list of SIS import errors for an account or a SIS import. Import
  # errors are only stored for 30 days.
  #
  # @argument failure [Optional, Boolean]
  #   If set, only shows errors on a sis import that would cause a failure.
  #
  # Example:
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/sis_imports/<id>/sis_import_errors' \
  #     -H "Authorization: Bearer <token>"
  #
  # Example:
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/sis_import_errors' \
  #     -H "Authorization: Bearer <token>"
  #
  # @returns [SisImportError]
  def index
    if authorized_action(@account, @current_user, %i(import_sis manage_sis))
      scope = @account.sis_batch_errors.order('created_at DESC')
      if params[:id]
        batch = @account.sis_batches.find(params[:id])
        scope = scope.where(sis_batch_id: batch)
      end
      scope = scope.failed if value_to_boolean(params[:failure])

      url = api_v1_sis_batch_import_errors_url if params[:id]
      url ||= api_v1_account_sis_import_errors_url
      errors = Api.paginate(scope, self, url)
      render json: {sis_import_errors: sis_import_errors_json(errors)}
    end
  end

end
