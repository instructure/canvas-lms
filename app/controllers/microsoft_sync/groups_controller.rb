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
#           "description": "Internal data about the last step run for a job in the 'retrying' state. Only returned for site admins",
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
#         "last_error_report_id": {
#            "description": "The ErrorReport ID for the last_error. Only returned for site admins",
#            "type": "integer",
#         },
#         "root_account_id": {
#            "description": "The root account the MicrosoftSync::Group belongs to",
#            "type": "integer",
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
  before_action :require_feature
  before_action :require_cooldown, only: :sync
  before_action :require_currently_not_syncing, only: :sync

  # Create a new MicrosoftSync::Group for
  # the specified course.
  #
  # If a MicrosoftSync::Group already exists
  # for the course, this endpoints responds with
  # "409 conflict"
  #
  # @returns MicrosoftSync::Group
  def create
    # Check if a active group already exists
    existing_group = MicrosoftSync::Group.find_by(course: course)
    head :conflict and return if existing_group && !existing_group.deleted?

    # If a non-active group exists for the course, restore it.
    # Otherwise create a new group
    new_group = (existing_group&.restore! && existing_group) ||
      MicrosoftSync::Group.create!(course: course)

    render json: group_json(new_group), status: :created
  end

  # Get a single MicrosoftSync::Group
  # Returns the active MicrosoftSync::Group
  # associated with the specified course
  #
  # @returns MicrosoftSync::Group
  def show
    render json: group_json
  end

  # Destroy the MicrosoftSync::Group associated
  # with the specified course.
  #
  # These records are soft-deleted
  def destroy
    group.destroy!
    head :no_content
  end

  # Schedule a sync for the group associated
  # with the specified course.
  #
  # This action counts as a "manual sync"
  #
  # Manual syncs require a cooldown period
  # before another manual sync is allowed.
  def sync
    group.syncer_job.run_later
    group.update_unless_deleted(workflow_state: :scheduled, last_manually_synced_at: Time.zone.now)
    render json: group_json
  end

  private

  # Don't allow scheduling a new job
  # if one is already running
  def require_currently_not_syncing
    return unless MicrosoftSync::Group::RUNNING_STATES.include?(
      group.workflow_state.to_sym
    )

    render(
      json: { errors: ['A sync job is already running for the specified group'] },
      status: :bad_request
    )
  end

  # Prevents users from queueing a large number
  # of manual sync jobs by requiring a cooldown
  # period.
  #
  # Site admins can bypass this cooldown period.
  #
  # There are some states in which we allow scheduling
  # another manual sync right away. (errored, for example).
  # This method also allows scheduling the sync if the
  # group is in one of those states.
  def require_cooldown
    return if Account.site_admin.account_users_for(@current_user).present?
    return if MicrosoftSync::Group::COOLDOWN_NOT_REQUIRED_STATES.include?(group.workflow_state.to_sym)
    return if group.last_manually_synced_at.blank?
    return if Time.zone.now.to_i - group.last_manually_synced_at.to_i >= MicrosoftSync::Group.manual_sync_cooldown

    render json: { errors: ['Not enough time elapsed since last manual sync'] }, status: :bad_request
  end

  def require_feature
    return if course.root_account.feature_enabled?(:microsoft_group_enrollments_syncing)

    not_found
  end

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

  def group_json(grp=nil)
    excludes = [:job_state]
    unless Account.site_admin.grants_right?(@current_user, :view_error_reports)
      excludes << :last_error_report_id
    end
    (grp || group).as_json(include_root: false, except: excludes)
  end
end
