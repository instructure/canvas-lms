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
# @object Group Category
#     {
#       // The ID of the group category.
#       id: 17,
#
#       // The display name of the group category.
#       name: "Math Groups",
#
#       // Certain types of group categories have special role designations. Currently,
#       // these include: "communities", "student_organized", and "imported".
#       // Regular course/account group categories have a role of null.
#       role: "communities",
#
#       // If the group category allows users to join a group themselves, thought they may
#       // only be a member of one group per group category at a time.
#       // Values include "restricted", "enabled", and null
#       // "enabled" allows students to assign themselves to a group
#       // "restricted" restricts them to only joining a group in their section
#       // null disallows students from joining groups
#       self_signup: null,
#
#       // The course or account that the category group belongs to. The pattern here is
#       // that whatever the context_type is, there will be an _id field named
#       // after that type. So if instead context_type was "Course", the
#       // course_id field would be replaced by an course_id field.
#       context_type: "Account",
#       account_id: 3,
#
#     }
#
class GroupCategoriesController < ApplicationController
  before_filter :get_context
  before_filter :require_context, :only => [:create, :index]
  before_filter :get_category_context, :only => [:show, :update, :destroy, :groups, :users]

  include Api::V1::Attachment
  include Api::V1::GroupCategory
  include Api::V1::Group

  SETTABLE_GROUP_ATTRIBUTES = %w(name description join_level is_public group_category avatar_attachment)

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
          render :json => paginated_categories.map { |c| group_category_json(c, @current_user, session) }
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
          render :json => group_category_json(@group_category, @current_user, session)
        end
      end
    end
  end


  # @API Create a Group Category
  # Create a new group category
  #
  # @argument name
  # @argument self_signup [Optional] [Course Only] allow students to signup for a group themselves
  #     valid values are:
  #           "enabled" allows students to self sign up for any group in course
  #           "restricted" allows students to self sign up only for groups in the same section
  #           null disallows self sign up
  # @argument create_group_count [Optional] [Course Only] automatically create groups, requires "enable_self_signup"
  # @argument split_group_count [Optional] [Course Only] split students into groups, not allowed with "enable_self_signup"
  #
  # @example_request
  #     curl htps://<canvas>/api/v1/courses/<course_id>/group_categories \ 
  #         -F 'name=Project Groups' \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns GroupCategory
  def create
    if authorized_action(@context, @current_user, :manage_groups)
      if api_request?
        error = process_group_category_api_params
        return render :json => error, :status => :bad_request unless error.empty?
      end
      @group_category = @context.group_categories.build
      if populate_group_category_from_params
        create_default_groups_in_category
          if api_request?
            render :json => group_category_json(@group_category, @current_user, session)
          else
            flash[:notice] = t('notices.create_category_success', 'Category was successfully created.')
            render :json => [@group_category.as_json, @group_category.groups.map { |g| g.as_json(:include => :users) }].to_json
          end
      end
    end
  end

  # @API Update a Group Category
  # Modifies an existing group category.
  #
  # @argument name
  # @argument self_signup [Optional] [Course Only] allow students to signup for a group themselves
  #     valid values are:
  #           "enabled" allows students to self sign up for any group in course
  #           "restricted" allows students to self sign up only for groups in the same section
  #           null disallows self sign up
  # @argument create_group_count [Optional] [Course Only] automatically create groups, requires "enable_self_signup"
  # @argument split_group_count [Optional] [Course Only] creates groups and split students into groups, not allowed with "enable_self_signup"
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
      @group_category ||= @context.group_categories.find_by_id(params[:category_id])
      if api_request?
        error = process_group_category_api_params
        return render :json => error, :status => :bad_request unless error.empty?
        if populate_group_category_from_params
          create_default_groups_in_category
          render :json => group_category_json(@group_category, @current_user, session)
        end
      else
        return render(:json => {'status' => 'not found'}, :status => :not_found) unless @group_category
        return render(:json => {'status' => 'unauthorized'}, :status => :unauthorized) if @group_category.protected?
        if populate_group_category_from_params
          flash[:notice] = t('notices.update_category_success', 'Category was successfully updated.')
          render :json => @group_category.to_json
        end
      end
    end
  end

  # @API Delete a Group Category
  # Deletes a group category and all groups under it. Protected group
  # categories can not be deleted, i.e. "communities", "student_organized", and "imported".
  #
  # @example_request
  #     curl https://<canvas>/api/v1/group_categories/<group_category_id> \
  #           -X DELETE \ 
  #           -H 'Authorization: Bearer <token>'
  #
  def destroy
    if authorized_action(@context, @current_user, :manage_groups)
      @group_category = @group_category || @context.group_categories.find_by_id(params[:category_id])
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
  # @returns [Groups]
  def groups
    if authorized_action(@context, @current_user, :manage_groups)
      @groups = @group_category.groups.active
      @groups = Api.paginate(@groups, self, api_v1_group_category_groups_url)
      render :json => @groups.map { |g| group_json(g, @current_user, session) }
    end
  end

  include Api::V1::User
  # @API List users
  #
  # Returns a list of users in the group category.
  #
  # @argument search_term (optional)
  #   The partial name or full ID of the users to match and return in the results list.
  #   Must be at least 3 characters.
  #
  # @argument unassigned (optional)
  #   Set this value to true if you wish only to search unassigned users in the group category
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

    search_term = params[:search_term]

    if search_term && search_term.size < 3
      return render \
          :json => {
          "status" => "argument_error",
          "message" => "search_term of 3 or more characters is required" },
          :status => :bad_request
    end

    search_params = params.slice(:search_term)
    search_params[:enrollment_role] = "StudentEnrollment" if @context.is_a? Course

    @group_category ||= @context.group_categories.find_by_id(params[:category_id])
    exclude_groups = params[:unassigned] ? @group_category.groups.active : []
    search_params[:exclude_groups] = exclude_groups

    if search_term
      users = UserSearch.for_user_in_context(search_term, @context, @current_user, search_params)
    else
      users = UserSearch.scope_for(@context, @current_user, search_params)
    end

    users = Api.paginate(users, self, api_v1_group_category_users_url)
    render :json => users.map { |u| user_json(u, @current_user, session, [], @context) }
  end

  def populate_group_category_from_params
    if api_request?
      args = params
    else
      args = params[:category]
    end
    name = args[:name] || @group_category.name
    name = t(:default_category_title, "Study Groups") if name.blank?
    if GroupCategory.protected_name_for_context?(name, @context)
      render :json => {'category[name]' => t('errors.category_name_reserved', "%{category_name} is a reserved name.", :category_name => name)}, :status => :bad_request
      return false
    elsif @context.group_categories.other_than(@group_category).find_by_name(name)
      render :json => {'category[name]' => t('errors.category_name_unavailable', "%{category_name} is already in use.", :category_name => name)}, :status => :bad_request
      return false
    elsif name.length >= 250 && args[:split_group_count].to_i > 0
      render :json => {'category[name]' => t('errors.category_name_too_long', "Enter a shorter category name to split students into groups")}, :status => :bad_request
      return false
    end

    enable_self_signup = value_to_boolean args[:enable_self_signup]
    restrict_self_signup = value_to_boolean args[:restrict_self_signup]
    if enable_self_signup && restrict_self_signup && @group_category.has_heterogenous_group?
      render :json => {'category[restrict_self_signup]' => t('errors.cant_restrict_self_signup', "Can't enable while a mixed-section group exists in the category.")}, :status => :bad_request
      return false
    end
    @group_category.name = name
    @group_category.configure_self_signup(enable_self_signup, restrict_self_signup)
    @group_category.group_limit = args[:group_limit]
    @group_category.save
  end

  def create_default_groups_in_category
    if api_request?
      args = params
    else
      args = params[:category]
    end
    self_signup = args[:enable_self_signup] == "1"
    distribute_members = !self_signup && args[:split_groups] == "1"
    return unless self_signup || distribute_members
    potential_members = distribute_members ? @context.users_not_in_groups([]) : nil
    count_field = self_signup ? :create_group_count : :split_group_count
    count = args[count_field].to_i
    count = 0 if count < 0
    count = [count, Setting.get_cached('max_groups_in_new_category', '200').to_i].min
    count = potential_members.length if distribute_members && count > potential_members.length
    return if count.zero?

    # TODO i18n
    group_name = @group_category.name
    group_name = group_name.singularize if I18n.locale == :en
    count.times do |idx|
      @group_category.groups.create(:name => "#{group_name} #{idx + 1}", :context => @context)
    end

    @group_category.distribute_members_among_groups(potential_members, @group_category.groups) if distribute_members
  end

  def process_group_category_api_params
    error = {}
    if params.has_key? 'self_signup'
      params[:enable_self_signup] = "1" if %w(enabled restricted).include? params[:self_signup].downcase
      params[:restrict_self_signup] = "1" if "restricted" == params[:self_signup].downcase
    end
    keys = (params.keys & %w{enable_self_signup split_group_count create_group_count})
    if keys.any? and not @context.instance_of?(Course)
      error = {:invalid_params => "the following keys are only applicable to Course groups: #{keys.join(', ')}"}
    elsif value_to_boolean params[:enable_self_signup]  and params[:split_group_count]
      error = {:self_signup => "is not applicable with 'split_group_count'" }
    elsif params[:create_group_count]
      error = {:create_group_count => "requires enable_self_signup"} unless value_to_boolean params[:enable_self_signup]
    elsif params[:split_group_count]
      params[:split_groups] = '1'
    end
    return error
  end

  protected
  def get_category_context
    begin
      @group_category = api_request? ? GroupCategory.find(params[:group_category_id]) : GroupCategory.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render(:json => {'status' => 'not found'}, :status => :not_found) unless @group_category
    end
    @context ||= @group_category.context
  end

end
