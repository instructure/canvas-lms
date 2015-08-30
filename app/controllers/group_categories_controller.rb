#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Group Categories
#
# Group Categories allow grouping of groups together in canvas. There are a few
# different built-in group categories used, or custom ones can be created. The
# built in group categories are:  "communities", "student_organized", and "imported".
#
# @model GroupCategory
#     {
#       "id": "GroupCategory",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the group category.",
#           "example": 17,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The display name of the group category.",
#           "example": "Math Groups",
#           "type": "string"
#         },
#         "role": {
#           "description": "Certain types of group categories have special role designations. Currently, these include: 'communities', 'student_organized', and 'imported'. Regular course/account group categories have a role of null.",
#           "example": "communities",
#           "type": "string"
#         },
#         "self_signup": {
#           "description": "If the group category allows users to join a group themselves, thought they may only be a member of one group per group category at a time. Values include 'restricted', 'enabled', and null 'enabled' allows students to assign themselves to a group 'restricted' restricts them to only joining a group in their section null disallows students from joining groups",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "restricted",
#               "enabled"
#             ]
#           }
#         },
#         "auto_leader": {
#           "description": "Gives instructors the ability to automatically have group leaders assigned.  Values include 'random', 'first', and null; 'random' picks a student from the group at random as the leader, 'first' sets the first student to be assigned to the group as the leader",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "first",
#               "random"
#             ]
#           }
#         },
#         "context_type": {
#           "description": "The course or account that the category group belongs to. The pattern here is that whatever the context_type is, there will be an _id field named after that type. So if instead context_type was 'Course', the course_id field would be replaced by an course_id field.",
#           "example": "Account",
#           "type": "string"
#         },
#         "account_id": {
#           "example": 3,
#           "type": "integer"
#         },
#         "group_limit": {
#           "description": "If self-signup is enabled, group_limit can be set to cap the number of users in each group. If null, there is no limit.",
#           "type": "integer"
#         },
#         "progress": {
#           "description": "If the group category has not yet finished a randomly student assignment request, a progress object will be attached, which will contain information related to the progress of the assignment request. Refer to the Progress API for more information",
#           "$ref": "Progress"
#         }
#       }
#     }
#
class GroupCategoriesController < ApplicationController
  before_filter :get_context
  before_filter :require_context, :only => [:create, :index]
  before_filter :get_category_context, :only => [:show, :update, :destroy, :groups, :users, :assign_unassigned_members]

  include Api::V1::Attachment
  include Api::V1::GroupCategory
  include Api::V1::Group
  include Api::V1::Progress

  SETTABLE_GROUP_ATTRIBUTES = %w(name description join_level is_public group_category avatar_attachment).freeze

  include TextHelper

  # @API List group categories for a context
  #
  # Returns a list of group categories in a context
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/<account_id>/group_categories \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [GroupCategory]
  def index
    @categories = @context.group_categories
    respond_to do |format|
      format.json do
        if authorized_action(@context, @current_user, :manage_groups)
          path = send("api_v1_#{@context.class.to_s.downcase}_group_categories_url")
          paginated_categories = Api.paginate(@categories, self, path)
          includes = ['progress_url']
          includes.concat(params[:includes]) if params[:includes]
          render :json => paginated_categories.map { |c| group_category_json(c, @current_user, session, :include => includes) }
        end
      end
    end
  end

  # @API Get a single group category
  #
  # Returns the data for a single group category, or a 401 if the caller doesn't have
  # the rights to see it.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/<group_category_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns GroupCategory
  def show
    respond_to do |format|
      format.json do
        if authorized_action(@group_category.context, @current_user, :manage_groups)
          includes = ['progress_url']
          includes.concat(params[:includes]) if params[:includes]
          render :json => group_category_json(@group_category, @current_user, session, :include => includes)
        end
      end
    end
  end


  # @API Create a Group Category
  # Create a new group category
  #
  # @argument name [Required, String]
  #   Name of the group category
  #
  # @argument self_signup [String, "enabled"|"restricted"]
  #   Allow students to sign up for a group themselves (Course Only).
  #   valid values are:
  #   "enabled":: allows students to self sign up for any group in course
  #   "restricted":: allows students to self sign up only for groups in the
  #                  same section null disallows self sign up
  #
  # @argument auto_leader [String, "first"|"random"]
  #   Assigns group leaders automatically when generating and allocating students to groups
  #   Valid values are:
  #   "first":: the first student to be allocated to a group is the leader
  #   "random":: a random student from all members is chosen as the leader
  #
  # @argument group_limit [Integer]
  #   Limit the maximum number of users in each group (Course Only). Requires
  #   self signup.
  #
  # @argument create_group_count [Integer]
  #   Create this number of groups (Course Only).
  #
  # @argument split_group_count (Deprecated)
  #   Create this number of groups, and evenly distribute students
  #   among them. not allowed with "enable_self_signup". because
  #   the group assignment happens synchronously, it's recommended
  #   that you instead use the assign_unassigned_members endpoint.
  #   (Course Only)
  #
  # @example_request
  #     curl htps://<canvas>/api/v1/courses/<course_id>/group_categories \
  #         -F 'name=Project Groups' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns GroupCategory
  def create
    if authorized_action(@context, @current_user, :manage_groups)
      @group_category = @context.group_categories.build
      if populate_group_category_from_params
        if api_request?
          includes = ["unassigned_users_count", "groups_count"]
          includes.concat(params[:includes]) if params[:includes]
          render :json => group_category_json(@group_category, @current_user, session, include: includes)
        else
          flash[:notice] = t('notices.create_category_success', 'Category was successfully created.')
          render :json => [@group_category.as_json, @group_category.groups.map { |g| g.as_json(:include => :users) }]
        end
      end
    end
  end

  # @API Update a Group Category
  # Modifies an existing group category.
  #
  # @argument name [String]
  #   Name of the group category
  #
  # @argument self_signup [String, "enabled"|"restricted"]
  #   Allow students to sign up for a group themselves (Course Only).
  #   Valid values are:
  #   "enabled":: allows students to self sign up for any group in course
  #   "restricted":: allows students to self sign up only for groups in the
  #                  same section null disallows self sign up
  #
  # @argument auto_leader [String, "first"|"random"]
  #   Assigns group leaders automatically when generating and allocating students to groups
  #   Valid values are:
  #   "first":: the first student to be allocated to a group is the leader
  #   "random":: a random student from all members is chosen as the leader
  #
  # @argument group_limit [Integer]
  #   Limit the maximum number of users in each group (Course Only). Requires
  #   self signup.
  #
  # @argument create_group_count [Integer]
  #   Create this number of groups (Course Only).
  #
  # @argument split_group_count (Deprecated)
  #   Create this number of groups, and evenly distribute students
  #   among them. not allowed with "enable_self_signup". because
  #   the group assignment happens synchronously, it's recommended
  #   that you instead use the assign_unassigned_members endpoint.
  #   (Course Only)
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/<group_category_id> \
  #         -X PUT \
  #         -F 'name=Project Groups' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns GroupCategory
  def update
    if authorized_action(@context, @current_user, :manage_groups)
      @group_category ||= @context.group_categories.where(id: params[:category_id]).first
      if api_request?
        if populate_group_category_from_params
          includes = ['progress_url']
          includes.concat(params[:includes]) if params[:includes]
          render :json => group_category_json(@group_category, @current_user, session, :include => includes)
        end
      else
        return render(:json => {'status' => 'not found'}, :status => :not_found) unless @group_category
        return render(:json => {'status' => 'unauthorized'}, :status => :unauthorized) if @group_category.protected?
        if populate_group_category_from_params
          flash[:notice] = t('notices.update_category_success', 'Category was successfully updated.')
          render :json => @group_category
        end
      end
    end
  end

  # @API Delete a Group Category
  # Deletes a group category and all groups under it. Protected group
  # categories can not be deleted, i.e. "communities" and "student_organized".
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/<group_category_id> \
  #           -X DELETE \
  #           -H 'Authorization: Bearer <token>'
  #
  def destroy
    if authorized_action(@context, @current_user, :manage_groups)
      @group_category = @group_category || @context.group_categories.where(id: params[:category_id]).first
      return render(:json => {'status' => 'not found'}, :status => :not_found) unless @group_category
      return render(:json => {'status' => 'unauthorized'}, :status => :unauthorized) if @group_category.protected?
      if @group_category.destroy
        if api_request?
          render :json => group_category_json(@group_category, @current_user, session)
        else
          flash[:notice] = t('notices.delete_category_success', "Category successfully deleted")
          render :json => {:deleted => true}
        end
      else
        if api_request?
          render :json => @group_category.errors, :status => :bad_request
        else
          render :json => {:deleted => false}
        end
      end
    end
  end

  # @API List groups in group category
  #
  # Returns a list of groups in a group category
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/<group_cateogry_id>/groups \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Group]
  def groups
    if authorized_action(@context, @current_user, :manage_groups)
      @groups = @group_category.groups.active.by_name
      @groups = Api.paginate(@groups, self, api_v1_group_category_groups_url)
      render :json => @groups.map { |g| group_json(g, @current_user, session) }
    end
  end

  include Api::V1::User
  # @API List users in group category
  #
  # Returns a list of users in the group category.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the results
  #   list. Must be at least 3 characters.
  #
  # @argument unassigned [Boolean]
  #   Set this value to true if you wish only to search unassigned users in the
  #   group category.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/1/users \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def users
    if @context.is_a? Course
      return unless authorized_action(@context, @current_user, :read_roster)
    else
      return unless authorized_action(@context, @current_user, :read)
    end

    search_term = params[:search_term].presence
    search_params = params.slice(:search_term)
    search_params[:enrollment_type] = "student" if @context.is_a? Course

    @group_category ||= @context.group_categories.where(id: params[:category_id]).first
    exclude_groups = value_to_boolean(params[:unassigned]) ? @group_category.groups.active.pluck(:id) : []
    search_params[:exclude_groups] = exclude_groups

    if search_term
      users = UserSearch.for_user_in_context(search_term, @context, @current_user, session, search_params)
    else
      users = UserSearch.scope_for(@context, @current_user, search_params)
    end

    users = Api.paginate(users, self, api_v1_group_category_users_url)
    render :json => users_json(users, @current_user, session, Array(params[:include]), @context, nil, Array(params[:exclude]))
  end

  # @API Assign unassigned members
  #
  # Assign all unassigned members as evenly as possible among the existing
  # student groups.
  #
  # @argument sync [Boolean]
  #   The assigning is done asynchronously by default. If you would like to
  #   override this and have the assigning done synchronously, set this value
  #   to true.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/1/assign_unassigned_members \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #    # Progress (default)
  #    {
  #        "completion": 0,
  #        "context_id": 20,
  #        "context_type": "GroupCategory",
  #        "created_at": "2013-07-05T10:57:48-06:00",
  #        "id": 2,
  #        "message": null,
  #        "tag": "assign_unassigned_members",
  #        "updated_at": "2013-07-05T10:57:48-06:00",
  #        "user_id": null,
  #        "workflow_state": "running",
  #        "url": "http://localhost:3000/api/v1/progress/2"
  #    }
  #
  # @example_response
  #    # New Group Memberships (when sync = true)
  #    [
  #      {
  #        "id": 65,
  #        "new_members": [
  #          {
  #            "user_id": 2,
  #            "name": "Sam",
  #            "display_name": "Sam",
  #            "sections": [
  #              {
  #                "section_id": 1,
  #                "section_code": "Section 1"
  #              }
  #            ]
  #          },
  #          {
  #            "user_id": 3,
  #            "name": "Sue",
  #            "display_name": "Sue",
  #            "sections": [
  #              {
  #                "section_id": 2,
  #                "section_code": "Section 2"
  #              }
  #            ]
  #          }
  #        ]
  #      },
  #      {
  #        "id": 66,
  #        "new_members": [
  #          {
  #            "user_id": 5,
  #            "name": "Joe",
  #            "display_name": "Joe",
  #            "sections": [
  #              {
  #                "section_id": 2,
  #                "section_code": "Section 2"
  #              }
  #            ]
  #          },
  #          {
  #            "user_id": 11,
  #            "name": "Cecil",
  #            "display_name": "Cecil",
  #            "sections": [
  #              {
  #                "section_id": 3,
  #                "section_code": "Section 3"
  #              }
  #            ]
  #          }
  #        ]
  #      }
  #    ]
  #
  # @returns GroupMembership | Progress
  def assign_unassigned_members
    return unless authorized_action(@context, @current_user, :manage_groups)

    # option disabled for student organized groups or section-restricted
    # self-signup groups. (but self-signup is ignored for non-Course groups)
    return render(:json => {}, :status => :bad_request) if @group_category.student_organized?
    return render(:json => {}, :status => :bad_request) if @context.is_a?(Course) && @group_category.restricted_self_signup?

    if value_to_boolean(params[:sync])
      # do the distribution and note the changes
      memberships = @group_category.assign_unassigned_members

      # render the changes
      json = memberships.group_by{ |m| m.group_id }.map do |group_id, new_members|
        { :id => group_id, :new_members => new_members.map{ |m| m.user.group_member_json(@context) } }
      end
      render :json => json
    else
      @group_category.assign_unassigned_members_in_background
      render :json => progress_json(@group_category.current_progress, @current_user, session)
    end
  end

  def populate_group_category_from_params
    args = api_request? ? params : params[:category]
    @group_category = GroupCategories::ParamsPolicy.new(@group_category, @context).populate_with(args)
    unless @group_category.save
      render :json => @group_category.errors, :status => :bad_request
      return false
    end
    true
  end

  def clone_with_name
    if authorized_action(get_category_context, @current_user, :manage_groups)
      GroupCategory.transaction do
        group_category = GroupCategory.active.find(params[:id])
        new_group_category = group_category.dup
        new_group_category.name = params[:name]
        begin
          new_group_category.save!
          group_category.clone_groups_and_memberships(new_group_category)
          render :json => new_group_category
        rescue ActiveRecord::RecordInvalid
          render :json => new_group_category.errors, :status => :bad_request
        end
      end
    end
  end

  protected
  def get_category_context
    begin
      @group_category = api_request? ? GroupCategory.active.find(params[:group_category_id]) : GroupCategory.active.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render(:json => {'status' => 'not found'}, :status => :not_found) unless @group_category
    end
    @context ||= @group_category.context
  end

end
