# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
# Groups serve as the data for a few different ideas in Canvas.  The first is
# that they can be a community in the canvas network.  The second is that they
# can be organized by students in a course, for study or communication (but not
# grading).  The third is that they can be organized by teachers or account
# administrators for the purpose of projects, assignments, and grading.  This
# last kind of group is always part of a group category, which adds the
# restriction that a user may only be a member of one group per category.
#
# All of these types of groups function similarly, and can be the parent
# context for many other types of functionality and interaction, such as
# collections, discussions, wikis, and shared files.
#
# @model Group
#     {
#       "id": "Group",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the group.",
#           "example": 17,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The display name of the group.",
#           "example": "Math Group 1",
#           "type": "string"
#         },
#         "description": {
#           "description": "A description of the group. This is plain text.",
#           "type": "string"
#         },
#         "is_public": {
#           "description": "Whether or not the group is public.  Currently only community groups can be made public.  Also, once a group has been set to public, it cannot be changed back to private.",
#           "example": false,
#           "type": "boolean"
#         },
#         "followed_by_user": {
#           "description": "Whether or not the current user is following this group.",
#           "example": false,
#           "type": "boolean"
#         },
#         "join_level": {
#           "description": "How people are allowed to join the group.  For all groups except for community groups, the user must share the group's parent course or account.  For student organized or community groups, where a user can be a member of as many or few as they want, the applicable levels are 'parent_context_auto_join', 'parent_context_request', and 'invitation_only'.  For class groups, where students are divided up and should only be part of one group of the category, this value will always be 'invitation_only', and is not relevant. * If 'parent_context_auto_join', anyone can join and will be automatically accepted. * If 'parent_context_request', anyone  can request to join, which must be approved by a group moderator. * If 'invitation_only', only those how have received an invitation my join the group, by accepting that invitation.",
#           "example": "invitation_only",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "parent_context_auto_join",
#               "parent_context_request",
#               "invitation_only"
#             ]
#           }
#         },
#         "members_count": {
#           "description": "The number of members currently in the group",
#           "example": 0,
#           "type": "integer"
#         },
#         "avatar_url": {
#           "description": "The url of the group's avatar",
#           "example": "https://<canvas>/files/avatar_image.png",
#           "type": "string"
#         },
#         "context_type": {
#           "description": "The course or account that the group belongs to. The pattern here is that whatever the context_type is, there will be an _id field named after that type. So if instead context_type was 'account', the course_id field would be replaced by an account_id field.",
#           "example": "Course",
#           "type": "string"
#         },
#         "course_id": {
#           "example": 3,
#           "type": "integer"
#         },
#         "role": {
#           "description": "Certain types of groups have special role designations. Currently, these include: 'communities', 'student_organized', and 'imported'. Regular course/account groups have a role of null.",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "communities",
#               "student_organized",
#               "imported"
#             ]
#           }
#         },
#         "group_category_id": {
#           "description": "The ID of the group's category.",
#           "example": 4,
#           "type": "integer"
#         },
#         "sis_group_id": {
#           "description": "The SIS ID of the group. Only included if the user has permission to view SIS information.",
#           "example": "group4a",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "The id of the SIS import if created through SIS. Only included if the user has permission to manage SIS information.",
#           "example": 14,
#           "type": "integer"
#         },
#         "storage_quota_mb": {
#           "description": "the storage quota for the group, in megabytes",
#           "example": 50,
#           "type": "integer"
#         },
#         "permissions": {
#           "description": "optional: the permissions the user has for the group. returned only for a single group and include[]=permissions",
#           "example": {"create_discussion_topic": true, "create_announcement": true},
#           "type": "object",
#           "key": { "type": "string" },
#           "value": { "type": "boolean" }
#         },
#         "users": {
#           "description": "optional: A list of users that are members in the group. Returned only if include[]=users. WARNING: this collection's size is capped (if there are an extremely large number of users in the group (thousands) not all of them will be returned).  If you need to capture all the users in a group with certainty consider using the paginated /api/v1/groups/<group_id>/memberships endpoint.",
#           "type": "array",
#           "items": { "$ref": "User" }
#         }
#       }
#     }
#
class GroupsController < ApplicationController
  before_action :get_context
  before_action :require_user, only: %w[index accept_invitation activity_stream activity_stream_summary]

  include Api::V1::Attachment
  include Api::V1::Group
  include Api::V1::GroupCategory
  include Context
  include K5Mode

  SETTABLE_GROUP_ATTRIBUTES = %w[
    name
    description
    join_level
    is_public
    group_category
    avatar_attachment
    storage_quota_mb
    max_membership
    leader
  ].freeze

  include TextHelper

  def context_group_members
    @group = @context
    if authorized_action(@group, @current_user, :read_roster)
      render json: @group.members_json_cached
    end
  end

  def unassigned_members
    category = @context.group_categories.where(id: params[:category_id]).first
    return render json: {}, status: :not_found unless category

    page = (params[:page] || 1).to_i rescue 1
    per_page = Api.per_page_for(self, default: 15, max: 100)
    groups = if category && !category.student_organized?
               category.groups.active
             else
               []
             end

    users = @context.users_not_in_groups(groups, order: User.sortable_name_order_by_clause("users"))
                    .paginate(page:, per_page:)

    if authorized_action(@context, @current_user, :manage)
      json = {
        pages: users.total_pages,
        current_page: users.current_page,
        next_page: users.next_page,
        previous_page: users.previous_page,
        total_entries: users.total_entries,
        users: users.map { |u| u.group_member_json(@context) }
      }
      json[:pagination_html] = render_to_string(partial: "user_pagination", locals: { users: }) unless params[:no_html]
      render json:
    end
  end

  # @API List your groups
  #
  # Returns a paginated list of active groups for the current user.
  #
  # @argument context_type [String, "Account"|"Course"]
  #  Only include groups that are in this type of context.
  #
  # @argument include[] [String, "tabs"]
  #   - "tabs": Include the list of tabs configured for each group.  See the
  #     {api:TabsController#index List available tabs API} for more information.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/groups?context_type=Account \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Group]
  def index
    return context_index if @context

    includes = { include: params[:include] }
    groups_scope = @current_user.current_groups
    respond_to do |format|
      format.html do
        groups_scope = groups_scope.where(context_type: params[:context_type]) if params[:context_type]
        groups_scope = groups_scope.preload(:group_category, :context, :root_account)

        groups = groups_scope.shard(@current_user).to_a
        groups.select! { |group| group.context_type != "Course" || group.context.grants_right?(@current_user, :read) }
        groups.sort_by! { |group| Canvas::ICU.collation_key(group&.name) }

        # Split the groups out into those in concluded courses and those not in concluded courses
        @current_groups, @previous_groups = groups.partition do |group|
          group.context_type != "Course" || !group.context.concluded?("StudentEnrollment")
        end
      end

      format.json do
        @groups = ShardedBookmarkedCollection.build(Group::Bookmarker, groups_scope.order(:name, :id)) do |scope|
          scope = scope.where(context_type: params[:context_type]) if params[:context_type]
          scope.preload(:group_category, :context)
        end
        @groups = Api.paginate(@groups, self, api_v1_current_user_groups_url)
        render json: (@groups.map { |g| group_json(g, @current_user, session, includes) })
      end
    end
  end

  # @API List the groups available in a context.
  #
  # Returns the paginated list of active groups in the given context that are visible to user.
  #
  # @argument only_own_groups [Boolean]
  #  Will only include groups that the user belongs to if this is set
  #
  # @argument include[] [String, "tabs"]
  #   - "tabs": Include the list of tabs configured for each group.  See the
  #     {api:TabsController#index List available tabs API} for more information.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/groups \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Group]
  def context_index
    return unless authorized_action(@context, @current_user, :read_roster)

    @groups = all_groups = @context.groups.active
    unless params[:filter].nil?
      @groups = all_groups = @groups.left_outer_joins(:users).where("groups.name ILIKE :query OR users.name ILIKE :query", query: "%#{ActiveRecord::Base.sanitize_sql_like(params[:filter])}%")
    end
    @groups = all_groups = @groups.order(GroupCategory::Bookmarker.order_by, Group::Bookmarker.order_by)
                                  .eager_load(:group_category).preload(:root_account)

    # run this only for students
    if params[:section_restricted] && @context.is_a?(Course) && @context.user_is_student?(@current_user)
      is_current_user_section_restricted = @context.membership_for_user(@current_user)&.limit_privileges_to_course_section
      if is_current_user_section_restricted
        # Gets all groups in the context
        group_scope = @context.groups.active.eager_load(:group_category).preload(:root_account)
        # Find all groups from that scope that can be limited from the section restriction parameter
        groups_with_restricted_categories_or_teacher_assigned = group_scope.where(group_categories: { self_signup: nil }).or(group_scope.where(group_categories: { self_signup: "restricted" }))
        # Find all groups that have users with different sections than the current user and DONT have the current_user in them
        groups_with_no_common_section_with_current_user = groups_with_restricted_categories_or_teacher_assigned.reject { |g| g.has_common_section_with_user?(@current_user) || g.includes_user?(@current_user) }
        # Remove the groups found above from the groups returned by the api
        @groups = all_groups -= groups_with_no_common_section_with_current_user
      end
    end

    unless api_request?
      # The Groups end-point relies on the People's tab configuration since it's a subsection of it.
      return unless tab_enabled?(Course::TAB_PEOPLE)

      if @context.is_a?(Account)
        user_crumb = t("#crumbs.users", "Users")
        set_active_tab "users"
        @group_user_type = "user"
        @allow_self_signup = false
      else
        user_crumb = t("#crumbs.people", "People")
        set_active_tab "people"
        @group_user_type = "student"
        @allow_self_signup = true
        if @context.grants_right? @current_user, session, :read_as_admin
          set_student_context_cards_js_env
        end
      end

      add_crumb user_crumb, named_context_url(@context, :context_users_url)
      add_crumb t("#crumbs.groups", "Groups"), named_context_url(@context, :context_groups_url)
    end

    respond_to do |format|
      format.html do
        @categories  = @context.group_categories.order(Arel.sql("role <> 'student_organized'"), GroupCategory.best_unicode_collation_key("name")).preload(:root_account)
        @user_groups = @current_user.group_memberships_for(@context) if @current_user

        if @context.grants_any_right?(@current_user, session, :manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS)
          categories_json = @categories.map { |cat| group_category_json(cat, @current_user, session, include: %w[progress_url unassigned_users_count groups_count]) }
          uncategorized = @context.groups.active.uncategorized.to_a
          if uncategorized.present?
            json = group_category_json(GroupCategory.uncategorized(context: @context), @current_user, session)
            json["groups"] = uncategorized.map { |group| group_json(group, @current_user, session) }
            categories_json << json
          end

          js_permissions = {
            can_add_groups: @context.grants_any_right?(@current_user, session, :manage_groups, :manage_groups_add),
            can_manage_groups: @context.grants_any_right?(@current_user, session, :manage_groups, :manage_groups_manage),
            can_delete_groups: @context.grants_any_right?(@current_user, session, :manage_groups, :manage_groups_delete)
          }

          js_env group_categories: categories_json,
                 group_user_type: @group_user_type,
                 allow_self_signup: @allow_self_signup,
                 context_class_name: @context.class.name,
                 permissions: js_permissions

          if @context.is_a?(Course)
            # get number of sections with students in them so we can enforce a min group size for random assignment on sections
            js_env(student_section_count: @context.enrollments.active_or_pending.where(type: "StudentEnrollment").distinct.count(:course_section_id))
          end
          # since there are generally lots of users in an account, always do large roster view
          @js_env[:IS_LARGE_ROSTER] ||= @context.is_a?(Account)
          render :context_manage_groups
        else
          return render_unauthorized_action if @context.is_a?(Account)

          @groups = @user_groups = @groups & (@user_groups || [])
          @available_groups = (all_groups - @user_groups).select do |group|
            group.grants_right?(@current_user, :join)
          end
          render :context_groups
        end
      end

      format.atom { render xml: @groups.map(&:to_atom).to_xml }
      format.json do
        path = send(:"api_v1_#{@context.class.to_s.downcase}_user_groups_url")

        if value_to_boolean(params[:only_own_groups]) || !tab_enabled?(Course::TAB_PEOPLE, no_render: true)
          all_groups = all_groups.merge(@current_user.current_groups)
        end
        @paginated_groups = Api.paginate(all_groups, self, path)
        render json: @paginated_groups.map { |g|
          include_inactive_users = value_to_boolean(params[:include_inactive_users])
          group_json(g,
                     @current_user,
                     session,
                     include: Array(params[:include]),
                     include_inactive_users:)
        }
      end
    end
  end

  # @API Get a single group
  #
  # Returns the data for a single group, or a 401 if the caller doesn't have
  # the rights to see it.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @argument include[] [String, "permissions", "tabs"]
  #   - "permissions": Include permissions the current user has
  #     for the group.
  #   - "tabs": Include the list of tabs configured for each group.  See the
  #     {api:TabsController#index List available tabs API} for more information.
  #
  # @returns Group
  def show
    find_group
    respond_to do |format|
      format.html do
        if @group&.context
          add_crumb @group.context.short_name, named_context_url(@group.context, :context_url)
          add_crumb @group.short_name, named_context_url(@group, :context_url)
        elsif @group
          add_crumb @group.short_name, named_context_url(@group, :context_url)
        end
        @context = @group
        assign_localizer
        if @group.deleted? && @group.context
          flash[:notice] = t("notices.already_deleted", "That group has been deleted")
          redirect_to named_context_url(@group.context, :context_url)
          return
        elsif @group.context.concluded? && !@group.context.grants_right?(@current_user, session, :read_roster)
          flash[:error] = t("Cannot access group in concluded course")
          redirect_to dashboard_url
          return
        end
        @current_conferences = @group.web_conferences.active.select { |c| c.active? && c.users.include?(@current_user) } rescue []
        @scheduled_conferences = @context.web_conferences.active.select { |c| c.scheduled? && c.users.include?(@current_user) } rescue []
        @stream_items = @current_user.try(:cached_recent_stream_items, { contexts: @context }) || []
        if params[:join] && @group.grants_right?(@current_user, :join)
          if @group.full?
            flash[:error] = t("errors.group_full", "The group is full.")
            redirect_to course_groups_url(@group.context)
            return
          end
          @group.request_user(@current_user)
          if @group.grants_right?(@current_user, session, :read)
            flash[:notice] = t("notices.welcome", "Welcome to the group %{group_name}!", group_name: @group.name)
            redirect_to named_context_url(@group.context, :context_groups_url)
          else
            render :membership_pending
          end
          return
        end
        if params[:leave] && @group.grants_right?(@current_user, :leave)
          membership = @group.membership_for_user(@current_user)
          if membership
            membership.destroy
            flash[:notice] = t("notices.goodbye", "You have removed yourself from the group %{group_name}.", group_name: @group.name)
            redirect_to named_context_url(@group.context, :context_groups_url)
            return
          end
        end
        if authorized_action(@group, @current_user, :read)
          set_badge_counts_for(@group, @current_user)
          @home_page = @group.wiki.front_page
        end

        if @context_membership
          content_for_head helpers.auto_discovery_link_tag(:atom, feeds_group_format_url(@context_membership.feed_code, :atom), { title: t("group_atom_feed", "Group Atom Feed") })
        elsif @context.available?
          content_for_head helpers.auto_discovery_link_tag(:atom, feeds_group_format_url(@context.feed_code, :atom), { title: t("group_atom_feed", "Group Atom Feed") })
        end
      end
      format.json do
        if authorized_action(@group, @current_user, :read)
          render json: group_json(@group, @current_user, session, include: Array(params[:include]))
        end
      end
    end
  end

  def new
    if authorized_action(@context, @current_user, [:manage_groups, :manage_groups_add])
      @group = @context.groups.build
    end
  end

  # @API Create a group
  #
  # Creates a new group. Groups created using the "/api/v1/groups/"
  # endpoint will be community groups.
  #
  # @argument name [String]
  #  The name of the group
  #
  # @argument description [String]
  #  A description of the group
  #
  # @argument is_public [Boolean]
  #   whether the group is public (applies only to community groups)
  #
  # @argument join_level [String, "parent_context_auto_join"|"parent_context_request"|"invitation_only"]
  #
  # @argument storage_quota_mb [Integer]
  #   The allowed file storage for the group, in megabytes. This parameter is
  #   ignored if the caller does not have the manage_storage_quotas permission.
  #
  # @argument sis_group_id [String]
  #   The sis ID of the group. Must have manage_sis permission to set.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups \
  #          -F 'name=Math Teachers' \
  #          -F 'description=A place to gather resources for our classes.' \
  #          -F 'is_public=true' \
  #          -F 'join_level=parent_context_auto_join' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns Group
  def create
    attrs = api_request? ? params : params.require(:group)
    attrs = attrs.permit(:name, :description, :join_level, :is_public, :storage_quota_mb, :max_membership)

    if api_request?
      if params[:group_category_id]
        group_category = api_find(GroupCategory.active, params[:group_category_id])
        return render json: {}, status: bad_request unless group_category

        @context = group_category.context
        attrs[:group_category] = group_category
        return unless authorized_action(group_category.context, @current_user, [:manage_groups, :manage_groups_add])
      else
        @context = @domain_root_account
        attrs[:group_category] = GroupCategory.communities_for(@context)
      end
    elsif params[:group]
      group_category_id = params[:group].delete :group_category_id
      if group_category_id && @context.grants_any_right?(@current_user, session, :manage_groups, :manage_groups_add)
        group_category = @context.group_categories.where(id: group_category_id).first
        return render json: {}, status: :bad_request unless group_category

        attrs[:group_category] = group_category
      else
        attrs[:group_category] = nil
      end
    end

    attrs.delete :storage_quota_mb unless @context.grants_right? @current_user, session, :manage_storage_quotas
    @group = @context.groups.temp_record(attrs.slice(*SETTABLE_GROUP_ATTRIBUTES))

    if authorized_action(@group, @current_user, :create)
      @group.set_default_account
      if (sis_id = params.delete :sis_group_id)
        if @group.root_account.grants_right?(@current_user, :manage_sis)
          @group.sis_source_id = sis_id
        else
          return render json: { message: "You must have manage_sis permission to set sis attributes" }, status: :unauthorized
        end
      end
      respond_to do |format|
        if @group.save
          SubmissionLifecycleManager.with_executing_user(@current_user) do
            @group.add_user(@current_user, "accepted", true) if @group.should_add_creator?(@current_user)
          end

          @group.invitees = params[:invitees]
          flash[:notice] = t("notices.create_success", "Group was successfully created.")
          format.html { redirect_to group_url(@group) }
          format.json { render json: group_json(@group, @current_user, session, { include: %w[users group_category permissions] }) }
        else
          format.html { render :new }
          format.json { render json: @group.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Edit a group
  #
  # Modifies an existing group.  Note that to set an avatar image for the
  # group, you must first upload the image file to the group, and the use the
  # id in the response as the argument to this function.  See the
  # {file:file_uploads.html File Upload Documentation} for details on the file
  # upload workflow.
  #
  # @argument name [String]
  #  The name of the group
  #
  # @argument description [String]
  #  A description of the group
  #
  # @argument is_public [Boolean]
  #   Whether the group is public (applies only to community groups). Currently
  #   you cannot set a group back to private once it has been made public.
  #
  # @argument join_level [String, "parent_context_auto_join"|"parent_context_request"|"invitation_only"]
  #
  # @argument avatar_id [Integer]
  #   The id of the attachment previously uploaded to the group that you would
  #   like to use as the avatar image for this group.
  #
  # @argument storage_quota_mb [Integer]
  #   The allowed file storage for the group, in megabytes. This parameter is
  #   ignored if the caller does not have the manage_storage_quotas permission.
  #
  # @argument members[] [String]
  #   An array of user ids for users you would like in the group.
  #   Users not in the group will be sent invitations. Existing group
  #   members who aren't in the list will be removed from the group.
  #
  # @argument sis_group_id [String]
  #   The sis ID of the group. Must have manage_sis permission to set.
  #
  # @argument override_sis_stickiness [boolean]
  #   Default is true. If false, any fields containing “sticky” changes will not be updated.
  #   See SIS CSV Format documentation for information on which fields can have SIS stickiness
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id> \
  #          -X PUT \
  #          -F 'name=Algebra Teachers' \
  #          -F 'join_level=parent_context_request' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns Group
  def update
    find_group
    group_params = api_request? ? params : params.require(:group)
    attrs = group_params.permit(:name,
                                :description,
                                :join_level,
                                :is_public,
                                :avatar_id,
                                :storage_quota_mb,
                                :max_membership,
                                leader: strong_anything,
                                members: strong_anything)
    attrs[:leader] = nil if group_params.key?(:leader) && group_params[:leader].blank?

    if !api_request? && params[:group][:group_category_id]
      group_category_id = params[:group].delete :group_category_id
      group_category = @context.group_categories.where(id: group_category_id).first
      return render json: {}, status: :bad_request unless group_category

      attrs[:group_category] = group_category
    end

    attrs.delete :storage_quota_mb unless @group.context.grants_right? @current_user, session, :manage_storage_quotas

    attrs[:avatar_attachment] = @group.active_images.where(id: attrs[:avatar_id]).first if attrs[:avatar_id]

    if attrs[:leader]
      membership = @group.group_memberships.where(user_id: attrs[:leader][:id]).first
      return render json: {}, status: :bad_request unless membership

      attrs[:leader] = membership.user
    end

    if authorized_action(@group, @current_user, :update)
      if (sis_id = params.delete :sis_group_id)
        if @group.root_account.grants_right?(@current_user, :manage_sis)
          @group.sis_source_id = sis_id
        else
          return render json: { message: "You must have manage_sis permission to update sis attributes" }, status: :unauthorized
        end
      end
      respond_to do |format|
        @group.transaction do
          if params[:override_sis_stickiness] && !value_to_boolean(params[:override_sis_stickiness])
            @group.update(attrs.slice(*(SETTABLE_GROUP_ATTRIBUTES - @group.stuck_sis_fields.map(&:to_s))))
          else
            @group.update(attrs.slice(*SETTABLE_GROUP_ATTRIBUTES))
          end
          if attrs[:members]
            user_ids = Api.value_to_array(attrs[:members]).map(&:to_i).uniq
            users = if @group.context
                      @group.context.users.where(id: user_ids)
                    else
                      User.where(id: user_ids)
                    end
            @memberships = @group.set_users(users)
          end
        end

        if @group.errors.none?
          @group.users.touch_all
          flash[:notice] = t("notices.update_success", "Group was successfully updated.")
          format.html { redirect_to clean_return_to(params[:return_to]) || group_url(@group) }
          format.json { render json: group_json(@group, @current_user, session, { include: %w[users group_category permissions] }) }
        else
          format.html { render :edit }
          format.json { render json: @group.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Delete a group
  #
  # Deletes a group and removes all members.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns Group
  def destroy
    find_group
    if authorized_action(@group, @current_user, :delete)
      if @group.destroy
        flash[:notice] = t("notices.delete_success", "Group successfully deleted")
        respond_to do |format|
          format.html { redirect_to(dashboard_url) }
          format.json { render json: group_json(@group, @current_user, session) }
        end
      else
        respond_to do |format|
          format.html { redirect_to(dashboard_url) }
          format.json { render json: @group.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Invite others to a group
  #
  # @subtopic Group Memberships
  #
  # Sends an invitation to all supplied email addresses which will allow the
  # receivers to join the group.
  #
  # @argument invitees[] [Required, String]
  #   An array of email addresses to be sent invitations.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/invite \
  #          -F 'invitees[]=leonard@example.com' \
  #          -F 'invitees[]=sheldon@example.com' \
  #          -H 'Authorization: Bearer <token>'
  def invite
    find_group
    if authorized_action(@group, @current_user, :manage)
      root_account = @group.context.try(:root_account) || @domain_root_account
      ul = UserList.new(params[:invitees],
                        root_account:,
                        search_method: :preferred,
                        current_user: @current_user)
      @memberships = []
      ul.users.each { |u| @memberships << @group.invite_user(u) }
      render json: @memberships.map { |gm| group_membership_json(gm, @current_user, session) }
    end
  end

  def accept_invitation
    find_group
    @membership = @group.group_memberships.where(uuid: params[:uuid]).first if @group
    @membership.accept! if @membership.try(:invited?)
    if @membership.try(:active?)
      flash[:notice] = t("notices.welcome", "Welcome to the group %{group_name}!", group_name: @group.name)
      respond_to do |format|
        format.html { redirect_to(group_url(@group)) }
        format.json { render json: group_membership_json(@membership, @current_user, session) }
      end
    else
      flash[:notice] = t("notices.invalid_invitation", "", group_name: @group.name)
      respond_to do |format|
        format.html { redirect_to(dashboard_url) }
        format.json { render json: "Unable to find associated group invitation", status: :bad_request }
      end
    end
  end

  def add_user
    @group = @context
    if authorized_action(@group, @current_user, :manage)
      SubmissionLifecycleManager.with_executing_user(@current_user) do
        @membership = @group.add_user(User.find(params[:user_id]))
        if @membership.valid?
          @group.touch
          render json: @membership
        else
          render json: @membership.errors, status: :bad_request
        end
      end
    end
  end

  def remove_user
    @group = @context
    if authorized_action(@group, @current_user, :manage)
      @membership = @group.group_memberships.where(user_id: params[:user_id]).first
      @membership.destroy
      render json: @membership
    end
  end

  include Api::V1::User
  # @API List group's users
  #
  # Returns a paginated list of users in the group.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the
  #   results list. Must be at least 3 characters.
  #
  # @argument include[] [String, "avatar_url"]
  #   "avatar_url": Include users' avatar_urls.
  #
  # @argument exclude_inactive [Boolean]
  #   Whether to filter out inactive users from the results. Defaults to
  #   false unless explicitly provided.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/1/users \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def users
    return unless authorized_action(@context, @current_user, :read)

    search_term = params[:search_term].presence

    include_inactive = params[:exclude_inactive].present? ? !value_to_boolean(params[:exclude_inactive]) : true

    users = if search_term
              UserSearch.for_user_in_context(search_term, @context, @current_user, session, { include_inactive_enrollments: include_inactive })
            else
              UserSearch.scope_for(@context, @current_user, { include_inactive_enrollments: include_inactive })
            end

    includes = Array(params[:include])
    users = Api.paginate(users, self, api_v1_group_users_url)
    UserPastLtiId.manual_preload_past_lti_ids(users, @context) if ["uuid", "lti_id"].any? { |id| includes.include? id }
    json_users = users_json(users, @current_user, session, includes, @context, nil, Array(params[:exclude]))

    if includes.include?("group_submissions") && @context.context_type == "Course"
      submissions_by_user = @context.group_category.submission_ids_by_user_id(users.map(&:id))
      json_users.each do |user|
        user[:group_submissions] = submissions_by_user[user[:id]]
      end
    end

    if (includes.include? "active_status") && (@context.context.is_a? Course)
      enrollments = Enrollment.where(user_id: json_users.pluck(:id), course_id: @context.context_id)

      inactive_students = enrollments.group_by(&:user_id).select { |_id, es| es.all?(&:hard_inactive?) }.map(&:first)
      json_users.each do |user|
        user[:is_inactive] = inactive_students.include?(user[:id])
      end
    end

    render json: json_users
  end

  def public_feed
    return unless get_feed_context(only: [:group])

    title = t(:feed_title, "%{course_or_account_name} Feed", course_or_account_name: @context.full_name)
    link = group_url(@context)

    @entries = []
    @entries.concat @context.calendar_events.active
    @entries.concat(DiscussionTopic::ScopedToUser.new(@context, @current_user, @context.discussion_topics.published).scope.reject do |dt|
      dt.locked_for?(@current_user, check_policies: true)
    end)
    @entries.concat WikiPages::ScopedToUser.new(@context, @current_user, @context.wiki_pages.published).scope
    @entries = @entries.sort_by(&:updated_at)

    respond_to do |format|
      format.atom { render plain: AtomFeedHelper.render_xml(title:, link:, entries: @entries, context: @context) }
    end
  end

  # @API Upload a file
  #
  # Upload a file to the group.
  #
  # This API endpoint is the first step in uploading a file to a group.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Only those with the "Manage Files" permission on a group can upload files
  # to the group. By default, this is anybody participating in the
  # group, or any admin over the group.
  def create_file
    @attachment = Attachment.new(context: @context)
    if authorized_action(@attachment, @current_user, :create)
      submit_assignment = value_to_boolean(params[:submit_assignment])
      opts = { check_quota: true, submit_assignment: }
      if submit_assignment && @context.respond_to?(:submissions_folder)
        opts[:check_quota] = false
        opts[:folder] = @context.submissions_folder
      end
      api_attachment_preflight(@context, request, opts)
    end
  end

  include Api::V1::PreviewHtml
  # @API Preview processed html
  #
  # Preview html content processed for this group
  #
  # @argument html [String]
  #   The html content to process
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/preview_html \
  #          -F 'html=<p><badhtml></badhtml>processed html</p>' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "html": "<p>processed html</p>"
  #   }
  def preview_html
    get_context
    if @context && authorized_action(@context, @current_user, :read)
      render_preview_html
    end
  end

  include Api::V1::StreamItem
  # @API Group activity stream
  # Returns the current user's group-specific activity stream, paginated.
  #
  # For full documentation, see the API documentation for the user activity
  # stream, in the user api.
  def activity_stream
    get_context
    if authorized_action(@context, @current_user, :read)
      api_render_stream(contexts: [@context], paginate_url: :api_v1_group_activity_stream_url)
    end
  end

  # @API Group activity stream summary
  # Returns a summary of the current user's group-specific activity stream.
  #
  # For full documentation, see the API documentation for the user activity
  # stream summary, in the user api.
  def activity_stream_summary
    get_context
    if authorized_action(@context, @current_user, :read)
      api_render_stream_summary(contexts: [@context])
    end
  end

  # @API Permissions
  # Returns permission information for the calling user in the given group.
  # See also the {api:AccountsController#permissions Account} and
  # {api:CoursesController#permissions Course} counterparts.
  #
  # @argument permissions[] [String]
  #   List of permissions to check against the authenticated user.
  #   Permission names are documented in the {api:RoleOverridesController#add_role Create a role} endpoint.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/groups/<group_id>/permissions \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'permissions[]=read_roster'
  #       -d 'permissions[]=send_messages_all'
  #
  # @example_response
  #   {'read_roster': 'true', 'send_messages_all': 'false'}
  def permissions
    get_context
    return unless authorized_action(@context, @current_user, :read)

    permissions = Array(params[:permissions]).map(&:to_sym)
    render json: @context.rights_status(@current_user, session, *permissions)
  end

  protected

  def find_group
    if api_request?
      @group = api_find(Group.active, params[:group_id])
    else
      @group = @context if @context.is_a?(Group)
      @group ||= api_find(@context ? @context.groups : Group, params[:id])
    end
  end
end
