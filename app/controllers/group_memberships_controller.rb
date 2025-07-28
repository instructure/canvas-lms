# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

# @API Groups
#
# Group memberships are the objects that tie users and groups together.
#
# @model GroupMembership
#     {
#       "id": "GroupMembership",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The id of the membership object",
#           "example": 92,
#           "type": "integer"
#         },
#         "group_id": {
#           "description": "The id of the group object to which the membership belongs",
#           "example": 17,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "The id of the user object to which the membership belongs",
#           "example": 3,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current state of the membership. Current possible values are 'accepted', 'invited', and 'requested'",
#           "example": "accepted",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "accepted",
#               "invited",
#               "requested"
#             ]
#           }
#         },
#         "moderator": {
#           "description": "Whether or not the user is a moderator of the group (the must also be an active member of the group to moderate)",
#           "example": true,
#           "type": "boolean"
#         },
#         "just_created": {
#           "description": "optional: whether or not the record was just created on a create call (POST), i.e. was the user just added to the group, or was the user already a member",
#           "example": true,
#           "type": "boolean"
#         },
#         "sis_import_id": {
#           "description": "The id of the SIS import if created through SIS. Only included if the user has permission to manage SIS information.",
#           "example": 4,
#           "type": "integer"
#         }
#       }
#     }
#
class GroupMembershipsController < ApplicationController
  before_action :find_group, only: %i[index show create update destroy]

  include Api::V1::Group

  ALLOWED_MEMBERSHIP_FILTER = %w[accepted invited requested].freeze

  # @API List group memberships
  #
  # @subtopic Group Memberships
  #
  # A paginated list of the members of a group.
  #
  # @argument filter_states[] [String, "accepted"|"invited"|"requested"]
  #   Only list memberships with the given workflow_states. By default it will
  #   return all memberships.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \
  #          -F 'filter_states[]=invited&filter_states[]=requested' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [GroupMembership]
  def index
    if authorized_action(@group, @current_user, :read_roster)
      memberships_route = polymorphic_url([:api_v1, @group, :memberships])
      scope = @group.group_memberships.preload(group: :root_account)

      only_states = ALLOWED_MEMBERSHIP_FILTER
      only_states &= params[:filter_states] if params[:filter_states]
      scope = scope.where(workflow_state: only_states)
      scope = scope.preload(group: :root_account)

      @memberships = Api.paginate(scope, self, memberships_route)
      render json: @memberships.map { |gm| group_membership_json(gm, @current_user, session) }
    end
  end

  # @API Get a single group membership
  #
  # @subtopic Group Memberships
  #
  # Returns the group membership with the given membership id or user id.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships/<membership_id> \
  #          -H 'Authorization: Bearer <token>'
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/users/<user_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns GroupMembership
  def show
    find_membership
    if authorized_action(@membership, @current_user, :read)
      render json: group_membership_json(@membership, @current_user, session)
    end
  end

  # @API Create a membership
  #
  # @subtopic Group Memberships
  #
  # Join, or request to join, a group, depending on the join_level of the
  # group. If the membership or join request already exists, then it is simply
  # returned.
  #
  # For differentiation tags, you can bulk add users using one of two methods:
  #
  # 1. Provide an array of user IDs via the `members[]` parameter.
  #
  # 2. Use the course-wide option with the following parameters:
  #    - `all_in_group_course` [Boolean]: If set to true, the endpoint will add
  #      every currently enrolled student (from the course context) to the
  #      differentiation tag.
  #    - `exclude_user_ids[]` [Integer]: When using `all_in_group_course`, you can
  #      optionally exclude specific users by providing their IDs in this parameter.
  #
  # In this context, these parameters only apply to differentiation tag memberships.
  #
  # @argument user_id [String] - The ID of the user for individual membership creation.
  # @argument members[] [Integer] - Bulk add multiple users to a differentiation tag.
  # @argument all_in_group_course [Boolean] - If true, add all enrolled students from the course.
  # @argument exclude_user_ids[] [Integer] - An array of user IDs to exclude when using all_in_group_course.
  #
  # @example_request (Individual membership creation)
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \
  #          -F 'user_id=self' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request (Bulk addition using members array)
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \
  #          -F 'members[]=123' \
  #          -F 'members[]=456' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request (Bulk addition using all_in_group_course with exclusions)
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \
  #          -F 'all_in_group_course=true' \
  #          -F 'exclude_user_ids[]=123' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns GroupMembership or a JSON response detailing partial failures
  #          if some memberships could not be created.
  def create
    return create_differentiation_tag_membership if params[:members] || params[:all_in_group_course]

    @user = api_find(User, params[:user_id])
    if authorized_action(GroupMembership.new(group: @group, user: @user), @current_user, :create)
      SubmissionLifecycleManager.with_executing_user(@current_user) do
        @membership = @group.add_user(@user)

        if @membership.valid?
          render json: group_membership_json(@membership, @current_user, session, include: ["just_created"])
        else
          render json: @membership.errors, status: :bad_request
        end
      end
    end
  end

  def create_differentiation_tag_membership
    differentiation_tag_context = @group.context

    return head :bad_request if differentiation_tag_context.is_a?(Account)
    return head :bad_request unless @group.non_collaborative?

    # Determine the user IDs to process based on the provided parameters.
    user_ids = if params[:all_in_group_course].present? && value_to_boolean(params[:all_in_group_course])
                 ids = differentiation_tag_context.student_enrollments.pluck(:user_id)
                 if params[:exclude_user_ids].present?
                   ids -= Array(params[:exclude_user_ids]).map(&:to_i)
                 end
                 ids
               else
                 Array(params[:members]).map(&:to_i)
               end

    return head :bad_request if user_ids.blank?

    if authorized_action(GroupMembership.new(group: @group, user: @current_user), @current_user, :create)
      SubmissionLifecycleManager.with_executing_user(@current_user) do
        active_user_ids = differentiation_tag_context.all_current_enrollments.where(user_id: user_ids).pluck(:user_id)
        invalid_user_ids = user_ids - active_user_ids

        memberships = @group.bulk_add_users_to_differentiation_tag(active_user_ids)
        membership_errors = memberships.select { |m| m.errors.any? }

        # Recompute submissions for the added users
        # - Typically this is handled by update_cached_due_dates callback in group_membership.rb, but since we are
        #   bulk creating memberships, it will bypass callbacks.
        added_user_ids = (memberships - membership_errors).map(&:user_id)
        assignments = AssignmentOverride.active.where(set_type: "Group", set_id: @group.id).pluck(:assignment_id)
        SubmissionLifecycleManager.recompute_users_for_course(added_user_ids, @group.context_id, assignments) if assignments.any?

        if membership_errors.any? || invalid_user_ids.any?
          render json: {
                   message: "Partial failure encountered",
                   invalid_user_ids:,
                   membership_errors: membership_errors.map(&:errors)
                 },
                 status: :ok
        else
          head :ok
        end
      end
    end
  end

  UPDATABLE_MEMBERSHIP_ATTRIBUTES = %w[workflow_state moderator].freeze

  # @API Update a membership
  #
  # @subtopic Group Memberships
  #
  # Accept a membership request, or add/remove moderator rights.
  #
  # @argument workflow_state [String, "accepted"]
  #   Currently, the only allowed value is "accepted"
  #
  # @argument moderator
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships/<membership_id> \
  #          -F 'moderator=true'
  #          -H 'Authorization: Bearer <token>'
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/users/<user_id> \
  #          -F 'moderator=true'
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns GroupMembership
  def update
    find_membership
    if authorized_action(@membership, @current_user, :update)
      attrs = params.permit(*UPDATABLE_MEMBERSHIP_ATTRIBUTES)
      attrs.delete(:workflow_state) unless attrs[:workflow_state] == "accepted"

      SubmissionLifecycleManager.with_executing_user(@current_user) do
        if @membership.update(attrs)
          render json: group_membership_json(@membership, @current_user, session)
        else
          render json: @membership.errors, status: :bad_request
        end
      end
    end
  end

  # @API Leave a group
  #
  # @subtopic Group Memberships
  #
  # Leave a group if you are allowed to leave (some groups, such as sets of
  # course groups created by teachers, cannot be left). You may also use 'self'
  # in place of a membership_id.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships/<membership_id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/users/<user_id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  def destroy
    find_membership
    if authorized_action(@membership, @current_user, :delete)
      @membership.workflow_state = "deleted"
      @membership.save
      render json: { "ok" => true }
    end
  end

  protected

  def find_group
    @group = api_find(Group.active, params[:group_id])
  end

  def find_membership
    if (params[:membership_id] && params[:membership_id] == "self") || (params[:user_id] && params[:user_id] == "self")
      @membership = @group.group_memberships.where(user_id: @current_user).first!
    elsif params[:membership_id]
      @membership = @group.group_memberships.find(params[:membership_id])
    else
      user_id = Api.map_ids([params[:user_id]], @group.users, @domain_root_account, @current_user).first
      @membership = @group.group_memberships.where(user_id:).first!
    end
  end
end
