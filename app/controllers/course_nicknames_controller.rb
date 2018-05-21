#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API Users
# @subtopic Course Nicknames
#
# API for manipulating course nicknames
#
# Course nicknames are alternate names for courses that are unique to each user.
# They are useful when the course's name is too long or less meaningful.
# If a user defines a nickname for a course, that name will be returned by the
# API in place of the course's actual name.
#
# @model CourseNickname
#     {
#       "id": "CourseNickname",
#       "description": "",
#       "properties": {
#         "course_id": {
#           "description": "the ID of the course",
#           "example": 88,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the actual name of the course",
#           "example": "S1048576 DPMS1200 Intro to Newtonian Mechanics",
#           "type": "string"
#         },
#         "nickname": {
#           "description": "the calling user's nickname for the course",
#           "example": "Physics",
#           "type": "string"
#         }
#       }
#     }
#
class CourseNicknamesController < ApplicationController
  before_action :require_user

  # @API List course nicknames
  #
  # Returns all course nicknames you have set.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/course_nicknames \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [CourseNickname]
  def index
    # TODO if these are moved out of the user preferences hash
    #      and into AR objects, we should paginate
    render(:json => course_nicknames_json(@current_user))
  end

  # @API Get course nickname
  #
  # Returns the nickname for a specific course.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/course_nicknames/<course_id> \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns CourseNickname
  def show
    course = api_find(Course, params[:course_id])
    return unless authorized_action(course, @current_user, :read)
    render(:json => course_nickname_json(@current_user, course))
  end

  # @API Set course nickname
  #
  # Set a nickname for the given course. This will replace the course's name
  # in output of API calls you make subsequently, as well as in selected
  # places in the Canvas web user interface.
  #
  # @argument nickname [Required, String]
  #   The nickname to set.  It must be non-empty and shorter than 60 characters.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/course_nicknames/<course_id> \
  #     -X PUT \
  #     -F 'nickname=Physics' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns CourseNickname
  def update
    course = api_find(Course, params[:course_id])
    return unless authorized_action(course, @current_user, :read)
    return render(:json => {:message => 'missing nickname'}, :status => :bad_request) unless params[:nickname].present?
    return render(:json => {:message => 'nickname too long'}, :status => :bad_request) if params[:nickname].length >= 60

    @current_user.shard.activate do
      @current_user.course_nicknames[course.id] = params[:nickname]
      if @current_user.save
        render :json => course_nickname_json(@current_user, course)
      else
        render :json => @current_user.errors, :status => :bad_request
      end
    end
  end

  # @API Remove course nickname
  # Remove the nickname for the given course.
  # Subsequent course API calls will return the actual name for the course.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/course_nicknames/<course_id> \
  #     -X DELETE \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns CourseNickname
  def delete
    course = api_find(Course, params[:course_id])

    @current_user.shard.activate do
      if @current_user.course_nicknames.delete(course.id)
        if @current_user.save
          render :json => course_nickname_json(@current_user, course)
        else
          render :json => @current_user.errors, :status => :bad_request
        end
      else
        render :json => { :message => 'no nickname exists for course' } , :status => :not_found
      end
    end
  end

  # @API Clear course nicknames
  # Remove all stored course nicknames.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/course_nicknames \
  #     -X DELETE \
  #     -H 'Authorization: Bearer <token>'
  #
  def clear
    @current_user.course_nicknames.clear
    if @current_user.save
      render :json => { :message => 'OK' }
    else
      render :json => @current_user.errors, :status => :bad_request
    end
  end

  private

  def course_nicknames_json(user)
    user.shard.activate do
      user.course_nicknames.map do |course_id, nickname|
        course = Course.where(id: course_id).first
        course && course_nickname_json(user, course, nickname)
      end.compact
    end
  end

  def course_nickname_json(user, course, nickname = nil)
    {
      course_id: course.id,
      name: course.name,
      nickname: nickname || course.nickname_for(user, nil)
    }
  end

end
