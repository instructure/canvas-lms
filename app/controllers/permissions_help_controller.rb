# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# @API Roles
#
# @model PermissionHelpText
#     {
#       "id": "PermissionHelpText",
#       "description": "Information about a permission, including its purpose and considerations for use.",
#       "properties": {
#         "details": {
#           "description": "Detailed explanations about what the permission does.",
#           "type": "array",
#           "items": {
#             "type": "object"
#            },
#           "example": [ {"title": "Add External Tools", "description": "Allows users to add external tools (LTI) to courses."} ]
#         },
#         "considerations": {
#           "description": "A list of considerations or warnings about using the permission.",
#           "type": "array",
#           "items": {
#             "type": "object"
#           },
#           "example": [ {"title": "Security Risk", "description": "Granting this permission may expose your system to security vulnerabilities."} ]
#         }
#       }
#     }
#
class PermissionsHelpController < ApplicationController
  # these actions access only static (but localized) information about permissions,
  # but require a logged-in user to mitigate possible abuse
  before_action :require_user

  # @API Get help text for permissions
  # Retrieve information about what Canvas permissions do and considerations for their use.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/permissions/account/view_user_logins/help
  #
  # @returns PermissionHelpText
  def help
    perm = params[:permission].to_sym
    info = Permissions.retrieve[perm] || Permissions.group_info(perm)
    raise ActiveRecord::RecordNotFound, "unknown permission" unless info

    h = if params[:context_type]&.downcase == "course"
          { details: info[:course_details] || [], considerations: info[:course_considerations] || [] }
        else
          { details: info[:account_details] || [], considerations: info[:account_considerations] || [] }
        end

    h[:details] = h[:details].map { |entry| entry.transform_values(&:call) }
    h[:considerations] = h[:considerations].map { |entry| entry.transform_values(&:call) }
    render json: h
  end

  # @API Retrieve permission groups
  # Retrieve information about groups of granular permissions
  #
  # The return value is a dictionary of permission group keys to objects
  # containing +label+ and +subtitle+ keys.
  def groups
    h = Permissions.permission_groups.transform_values do |info|
      {
        label: info[:label].call,
        subtitle: info[:subtitle].call
      }
    end
    render json: h
  end
end
