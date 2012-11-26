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

# @API Quizzes
#
# The Quizzes API is very primitive for now, and just returns a title and a url to the quiz.
#
# @object Quiz
#     {
#       // The ID of the quiz
#       id: 5,
#
#       // the title of the quiz
#       title: "My Quiz",
#
#       // The HTTP/HTTPS URL to the feed
#       html_url: "http://canvas.example.edu/courses/1/quizzes/2",
#
#     }
#
class QuizzesApiController < ApplicationController
  include Api::V1::Quiz

  before_filter :require_context

  # @API List quizzes in a course
  #
  # Returns the list of Quizzes in this course.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/quzzes \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [Quiz]
  def index
    if authorized_action(@context, @current_user, :read) && tab_enabled?(@context.class::TAB_QUIZZES)
      api_route = polymorphic_url([:api, :v1, @context, :quizzes])
      @quizzes = Api.paginate(@context.quizzes.active, self, api_route)
      render :json => quizzes_json(@quizzes, @context, @current_user, session)
    end
  end

end
