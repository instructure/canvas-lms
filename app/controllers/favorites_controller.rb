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
  before_filter :check_defaults, :only => [:remove_favorite_course]
  after_filter :touch_user, :only => [:add_favorite_course, :remove_favorite_course, :reset_course_favorites]

  include Api::V1::Favorite
  include Api::V1::Course

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
      course_json(course, @current_user, session, includes, enrollments)
    }
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
    course = api_find(Course, params[:id])
    fave = nil

    @current_user.shard.activate do
      Favorite.unique_constraint_retry do
        fave = @current_user.favorites.where(:context_type => 'Course', :context_id => course).first
        fave ||= @current_user.favorites.create!(:context => course)
      end
    end

    render :json => favorite_json(fave, @current_user, session)
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
    # allow removing a Favorite whose context object no longer exists
    # but also allow referencing by sis id, if possible
    courses = api_find_all(Course, [params[:id]])
    course_id = Shard.relative_id_for(courses.any? ? courses.first.id : params[:id], Shard.current, @current_user.shard)
    fave = @current_user.favorites.where(:context_type => 'Course', :context_id => course_id).first
    if fave
      result = favorite_json(fave, @current_user, session)
      fave.destroy
      render :json => result
    else
      # can't really return a 404 here without making browsers freak out
      # in the Courses UI (it's easy for the client's state to get out of
      # sync with the server's, especially with multiple browsers open)
      render :json => {}
    end
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
    @current_user.favorites.by('Course').destroy_all
    render :json => { :status => 'ok' }
  end


  protected

  # When we have other favorites, this needs to be modified to handle the other
  # types, rather than just courses.
  def check_defaults
    return unless @current_user.favorites.count == 0
    @current_user.menu_courses.each do |course|
      @current_user.favorites.create :context => course
    end
  end

  def touch_user
    # Menu is cached, clear it
    @current_user.touch
  end

end
