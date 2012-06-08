#
# Copyright (C) 2012 Instructure, Inc.
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
# A Group Membership object looks like:
#     !!!javascript
#     {
#       // The id of the membership object
#       id: 92
#
#       // The id of the group object to which the membership belongs
#       group_id: 17
#
#       // The id of the user object to which the membership belongs
#       user_id: 3
#
#       // The current state of the membership. Current possible values are
#       // "accepted", "invited", and "requested"
#       workflow_state: "accepted"
#
#       // Whether or not the user is a moderator of the group (the must also
#       // be an active member of the group to moderate)
#       moderator: true
#     }
#
class GroupMembershipsController < ApplicationController
  before_filter :find_group, :only => [:index, :create, :update, :destroy]

  include Api::V1::Group

  ALLOWED_MEMBERSHIP_FILTER = %w(accepted invited requested)

  # @API List group memberships
  #
  # @subtopic Group Memberships
  #
  # List the members of a group.
  #
  # @argument filter_states[] [Optional] Only list memberships with the given
  #   workflow_states. Allowed values are "accepted", "invited", and
  #   "requested". By default it will return all memberships.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \ 
  #          -F 'filter_states[]=invited&filter_states[]=requested' \ 
  #          -H 'Authorization: Bearer <token>'
  def index
    if authorized_action(@group, @current_user, :read_roster)
      memberships_route = polymorphic_url([:api_v1, @group, :memberships])
      scope = @group.group_memberships

      only_states = ALLOWED_MEMBERSHIP_FILTER
      only_states = only_states & params[:filter_states] if params[:filter_states]
      scope = scope.scoped(:conditions => { :workflow_state => only_states })

      @memberships = Api.paginate(scope, self, memberships_route)
      render :json => @memberships.map{ |gm| group_membership_json(gm, @current_user, session) }
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
  # @argument user_id
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships \ 
  #          -F 'user_id=self'
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       id: 102,
  #       group_id: 6,
  #       user_id: 3,
  #       workflow_state: "requested",
  #       moderator: false
  #     }
  def create
    @user = api_find(User, params[:user_id])
    if authorized_action(GroupMembership.new(:group => @group, :user => @user), @current_user, :create)
      @membership = @group.add_user(@user)
      render :json => group_membership_json(@membership, @current_user, session)
    end
  end

  UPDATABLE_MEMBERSHIP_ATTRIBUTES = %w(workflow_state moderator)

  # @API Update a membership
  #
  # @subtopic Group Memberships
  #
  # Accept a membership request, or add/remove moderator rights.
  #
  # @argument workflow_state Currently, the only allowed value is "accepted"
  # @argument moderator
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/memberships/<membership_id> \ 
  #          -F 'moderator=true'
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       id: 102,
  #       group_id: 6,
  #       user_id: 3,
  #       workflow_state: "accepted",
  #       moderator: true
  #     }
  def update
    find_membership
    if authorized_action(@membership, @current_user, :update)
      params.delete(:workflow_state) unless params[:workflow_state] == 'accepted'
      if @membership.update_attributes(params.slice(*UPDATABLE_MEMBERSHIP_ATTRIBUTES))
        render :json => group_membership_json(@membership, @current_user, session)
      else
        render :json => @membership.errors, :status => :bad_request
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
    @group = Group.active.find(params[:group_id])
  end

  def find_membership
    if params[:membership_id] == 'self'
      @membership = @group.group_memberships.scoped(:conditions => { :user_id => @current_user.id }).first
    else
      @membership = @group.group_memberships.find(params[:membership_id])
    end
  end
end
