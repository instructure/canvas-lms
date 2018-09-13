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
  before_action :find_group, :only => [:index, :show, :create, :update, :destroy]

  include Api::V1::Group

  ALLOWED_MEMBERSHIP_FILTER = %w(accepted invited requested).freeze

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
      only_states = only_states & params[:filter_states] if params[:filter_states]
      scope = scope.where(:workflow_state => only_states)
      scope = scope.preload(group: :root_account)

      @memberships = Api.paginate(scope, self, memberships_route)
      render :json => @memberships.map{ |gm| group_membership_json(gm, @current_user, session) }
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
      render :json => group_membership_json(@membership, @current_user, session)
    end
  end

  # @API Create a membership
  #
  # @subtopic Group Memberships
  #
  # Join, or request to join, a group, depending on the join_level of the
  # group.  If the membership or join request already exists, then it is simply
  # returned
  #
  # @argument user_id [String]
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \
  #          -F 'user_id=self'
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns GroupMembership
  def create
    @user = api_find(User, params[:user_id])
    if authorized_action(GroupMembership.new(:group => @group, :user => @user), @current_user, :create)
      DueDateCacher.with_executing_user(@current_user) do
        @membership = @group.add_user(@user)

        if @membership.valid?
          render :json => group_membership_json(@membership, @current_user, session, include: ['just_created'])
        else
          render :json => @membership.errors, :status => :bad_request
        end
      end
    end
  end

  UPDATABLE_MEMBERSHIP_ATTRIBUTES = %w(workflow_state moderator).freeze

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
      attrs.delete(:workflow_state) unless attrs[:workflow_state] == 'accepted'

      DueDateCacher.with_executing_user(@current_user) do
        if @membership.update_attributes(attrs)
          render :json => group_membership_json(@membership, @current_user, session)
        else
          render :json => @membership.errors, :status => :bad_request
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
      @membership.workflow_state = 'deleted'
      @membership.save
      render :json => { "ok" => true }
    end
  end

  protected

  def find_group
    @group = api_find(Group.active, params[:group_id])
  end

  def find_membership
    if (params[:membership_id] && params[:membership_id] == 'self') || (params[:user_id] && params[:user_id] == 'self')
      @membership = @group.group_memberships.where(:user_id => @current_user).first!
    elsif params[:membership_id]
      @membership = @group.group_memberships.find(params[:membership_id])
    else
      user_id = Api.map_ids([params[:user_id]], @group.users, @domain_root_account, @current_user).first
      @membership = @group.group_memberships.where(user_id: user_id).first!
    end
  end
end
