# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API Microsoft Sync - Groups
# @internal
#
# API to manage MicrosoftSync::Groups.
#
# @model MicrosoftSync::Group
#     {
#       "id": "MicrosoftSync::Group",
#       "description": "The membership of a Microsoft group as well as the status of syncing Canvas enrollments to that group.",
#       "properties": {
#         "id": {
#           "description": "The id of the MicrosoftSync::Group",
#           "example": "4",
#           "type": "integer"
#         },
#         "course_id": {
#           "description": "The id of the course related to the MicrosoftSync::Group",
#           "example": "8",
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current state of the MicrosoftSync::Group",
#           "example": "pending",
#           "type": "string",
#           "enum": [
#             "pending",
#             "running",
#             "errored",
#             "completed"
#           ]
#         },
#         "job_state": {
#           "description": "The last step of syncing that was successfully completed",
#           "type": "string"
#         },
#         "last_synced_at": {
#            "description": "The time of the last successful sync",
#            "type": "datetime",
#            "example": "2012-07-20T15:00:00-06:00"
#         },
#         "last_error": {
#            "description": "The last error encountered during an attempted sync",
#            "type": "string",
#         },
#         "root_account_id": {
#            "description": "The root account the MicrosoftSync::Group belongs to",
#            "integer": "datetime",
#            "example": "1"
#         },
#         "created_at": {
#            "description": "The time the MicrosoftSync::Group was created",
#            "type": "datetime",
#            "example": "2012-07-20T15:00:00-06:00"
#         },
#         "updated_at": {
#            "description": "The time the MicrosoftSync::Group was updated",
#            "type": "datetime",
#            "example": "2012-07-20T15:00:00-06:00"
#         }
#       }
#     }
class MicrosoftSync::GroupsController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :validate_user_permissions

  # Get a single MicrosoftSync::Group
  # Returns the active MicrosoftSync::Group
  # associated with the specified course
  #
  # @returns MicrosoftSync::Group
  def show
    render json: group.as_json(include_root: false)
  end

  # Destroy the MicrosoftSync::Group associated
  # with the specified course.
  #
  # These records are soft-deleted
  def destroy
    group.destroy!
    head :no_content
  end

  private

  def validate_user_permissions
    # Only users who can manage students in a course
    # should be permitted to manage the sync group
    render_unauthorized_action unless course.grants_right?(
      @current_user,
      session,
      :manage_students
    )
  end

  def course
    @context
  end

  def group
    @group ||= MicrosoftSync::Group.not_deleted.find_by(course: course) ||
      (raise ActiveRecord::RecordNotFound)
  end
end
