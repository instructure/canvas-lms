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
# @API Files
# @subtopic Usage Rights
#
# @model UsageRights
#     {
#       "id": "UsageRights",
#       "description": "Describes the copyright and license information for a File",
#       "properties": {
#         "legal_copyright" : {
#           "type": "string",
#           "description": "Copyright line for the file",
#           "example": "(C) 2014 Incom Corporation Ltd"
#         },
#         "use_justification" : {
#           "type": "string",
#           "description": "Justification for using the file in a Canvas course. Valid values are 'own_copyright', 'public_domain', 'used_by_permission', 'fair_use', 'creative_commons'",
#           "example": "creative_commons"
#         },
#         "license" : {
#           "type": "string",
#           "description": "License identifier for the file.",
#           "example": "cc_by_sa"
#         },
#         "license_name": {
#           "type": "string",
#           "description": "Readable license name",
#           "example": "CC Attribution Share-Alike"
#         },
#         "message": {
#           "type": "string",
#           "description": "Explanation of the action performed",
#           "example": "4 files updated"
#         }
#       }
#     }
#
# @model License
#     {
#       "id": "License",
#       "properties": {
#         "id": {
#           "type": "string",
#           "description": "a short string identifying the license",
#           "example": "cc_by_sa"
#         },
#         "name": {
#           "type": "string",
#           "description": "the name of the license",
#           "example": "CC Attribution ShareAlike"
#         },
#         "url": {
#           "type": "string",
#           "description": "a link to the license text",
#           "example": "http://creativecommons.org/licenses/by-sa/4.0"
#         }
#       }
#     }
#
class UsageRightsController < ApplicationController
  include Api::V1::UsageRights

  before_filter :require_context

  # @API Set usage rights
  # Sets copyright and license information for one or more files
  #
  # @argument file_ids[] [Required]
  #   List of ids of files to set usage rights for.
  #
  # @argument folder_ids[] [Optional]
  #   List of ids of folders to search for files to set usage rights for.
  #   Note that new files uploaded to these folders do not automatically inherit these rights.
  #
  # @argument usage_rights[use_justification] [Required, String, "own_copyright"|"used_by_permission"|"fair_use"|"public_domain"|"creative_commons"]
  #   The intellectual property justification for using the files in Canvas
  #
  # @argument usage_rights[legal_copyright] [Optional, String]
  #   The legal copyright line for the files
  #
  # @argument usage_rights[license] [Optional, String]
  #   The license that applies to the files. See the {api:UsageRightsController#licenses List licenses endpoint} for the supported license types.
  #
  # @returns UsageRights
  def set_usage_rights
    if authorized_action(@context, @current_user, :manage_files)
      return render json: { message: I18n.t("Must supply 'file_ids' and/or 'folder_ids' parameter") }, status: :bad_request unless params[:file_ids].present? || params[:folder_ids].present?
      return render json: { message: I18n.t("No 'usage_rights' object supplied") }, status: :bad_request unless params[:usage_rights].is_a?(Hash)

      usage_rights_params = params[:usage_rights].slice(:use_justification, :legal_copyright, :license)
      usage_rights = @context.usage_rights.where(usage_rights_params).first
      usage_rights ||= @context.usage_rights.create(usage_rights_params)
      return render json: usage_rights.errors, status: :bad_request unless usage_rights && usage_rights.valid?

      assign_usage_rights(usage_rights)
    end
  end

  # @API Remove usage rights
  # Removes copyright and license information associated with one or more files
  #
  # @argument file_ids[] [Required]
  #   List of ids of files to remove associated usage rights from.
  #
  # @argument folder_ids[] [Optional]
  #   List of ids of folders. Usage rights will be removed from all files in these folders.
  #
  def remove_usage_rights
    if authorized_action(@context, @current_user, :manage_files)
      return render json: { message: I18n.t("Must supply 'file_ids' and/or 'folder_ids' parameter") }, status: :bad_request unless params[:file_ids].present? || params[:folder_ids].present?

      assign_usage_rights(nil)
    end
  end

  # @API List licenses
  # Lists licenses that can be applied
  #
  # @returns [License]
  def licenses
    # there are no per-context licenses yet, but let's pretend like there are, for future expandability
    if authorized_action(@context, @current_user, :read)
      render json: UsageRights.licenses.map { |license, data|
        { id: license, name: data[:readable_license], url: data[:license_url] }
      }
    end
  end

private
  # recursively enumerate file ids under a folder
  def enumerate_contents(folder)
    ids = folder.active_sub_folders.inject([]) { |file_ids, folder| file_ids += enumerate_contents(folder) }
    ids += folder.active_file_attachments.pluck(:id)
  end

  # assign the given usage rights to params[:file_ids] / params[:folder_ids]
  def assign_usage_rights(usage_rights)
    folder_ids = Array(params[:folder_ids]).map(&:to_i)
    folders = @context.folders.active.where(id: folder_ids).to_a
    file_ids = folders.inject([]) { |file_ids, folder| file_ids += enumerate_contents(folder) }
    file_ids += Array(params[:file_ids]).map(&:to_i)

    count = @context.attachments.not_deleted.where(id: file_ids).update_all(usage_rights_id: usage_rights)
    result = usage_rights ? usage_rights_json(usage_rights, @current_user) : {}
    result.merge!(message: I18n.t({one: "1 file updated", other: "%{count} files updated"}, count: count))
    return render json: result
  end
end
