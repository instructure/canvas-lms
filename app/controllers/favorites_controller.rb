#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Favorites
#
# @model Favorite
#     {
#       "id": "Favorite",
#       "description": "",
#       "required": [""],
#       "properties": {
#         "context_id": {
#           "description": "The ID of the object the Favorite refers to",
#           "example": 1170,
#           "type": "integer"
#         },
#         "context_type": {
#           "description": "The type of the object the Favorite refers to (currently, only 'Course' is supported)",
#           "example": "Course",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "Course"
#             ]
#           }
#         }
#       }
#     }
#
class FavoritesController < ApplicationController

  before_filter :require_user
  after_filter :touch_user, :only => [:add_favorite_course, :remove_favorite_course, :reset_course_favorites]

  include Api::V1::Favorite
  include Api::V1::Course
  include Api::V1::Group

  # @API List favorite courses
  # Retrieve the list of favorite courses for the current user. If the user has not chosen
  # any favorites, then a selection of currently enrolled courses will be returned.
  #
  # See the {api:CoursesController#index List courses API} for details on accepted include[] parameters.
  #
  # @returns [Course]
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/courses \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def list_favorite_courses
    includes = Set.new(Array(params[:include]))
    render :json => @current_user.menu_courses.map { |course|
      enrollments = course.current_enrollments.where(:user_id => @current_user).to_a
      if includes.include?('observed_users') &&
          enrollments.any?(&:assigned_observer?)
        enrollments.concat(ObserverEnrollment.observed_enrollments_for_courses(course, @current_user))
      end

      course_json(course, @current_user, session, includes, enrollments)
    }
  end

  # @API List favorite groups
  # Retrieve the list of favorite groups for the current user. If the user has not chosen
  # any favorites, then a selection of groups that the user is a member of will be returned.
  #
  #
  #
  # @returns [Group]
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/groups \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def list_favorite_groups
    fave_group_memberships = nil

    @current_user.shard.activate do
      fave_group_memberships = @current_user.groups.active.shard(@current_user).where.not(id: @current_user.hidden_context_ids("Group"))
    end
    if fave_group_memberships.any?
      render :json => fave_group_memberships.map{ |g| group_json(g, @current_user,session)}
    else
      render :json => @current_user.groups.active.shard(@current_user).map{ |g| group_json(g, @current_user,session)}
    end
  end
  # @API Add course to favorites
  # Add a course to the current user's favorites.  If the course is already
  # in the user's favorites, nothing happens.
  #
  # @argument id [Required, String]
  #   The ID or SIS ID of the course to add.  The current user must be
  #   registered in the course.
  #
  # @returns Favorite
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/courses/1170 \
  #       -X POST \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  #       -H 'Content-Length: 0'
  #
  def add_favorite_course
    set_favorite(find_course)
  end

  # @API Add group to favorites
  # Add a group to the current user's favorites.  If the group is already
  # in the user's favorites, nothing happens.
  #
  # @argument id [Required, String]
  #   The ID or SIS ID of the group to add.  The current user must be
  #   a member of the group.
  #
  # @returns Favorite
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/group/1170 \
  #       -X POST \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  #       -H 'Content-Length: 0'
  #
  def add_favorite_group
    set_favorite(find_group)
  end

  # @API Remove course from favorites
  # Remove a course from the current user's favorites.
  #
  # @argument id [Required, String]
  #   the ID or SIS ID of the course to remove
  #
  # @returns Favorite
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/courses/1170 \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def remove_favorite_course
    unset_favorite(find_course)
  end

  # @API Remove group from favorites
  # Remove a group from the current user's favorites.
  #
  # @argument id [Required, String]
  #   the ID or SIS ID of the group to remove
  #
  # @returns Favorite
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/groups/1170 \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def remove_favorite_group
    unset_favorite(find_group)
  end


  # @API Reset course favorites
  # Reset the current user's course favorites to the default
  # automatically generated list of enrolled courses
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/courses \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def reset_course_favorites
    Favorite.reset(@current_user, Course)
    render json: { status: 'ok' }
  end

  # @API Reset group favorites
  # Reset the current user's group favorites to the default
  # automatically generated list of enrolled group
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/self/favorites/groups \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def reset_group_favorites
    Favorite.reset(@current_user, Group)
    render json: { status: 'ok' }
  end

  protected

  def touch_user
    # Menu is cached, clear it
    @current_user.touch
  end

  def find_course
    api_find(Course, params[:id])
  end

  def find_group
    api_find(Group, params[:id])
  end

  def set_favorite(context)
    fave = Favorite.show_context(@current_user, context)
    render json: favorite_json(fave, @current_user, session)
  end

  def unset_favorite(context)
    if fave = Favorite.hide_context(@current_user, context)
      render json: favorite_json(fave, @current_user, session)
    else
      render :json => {}
    end
  end
end
