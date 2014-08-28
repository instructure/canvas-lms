#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

# @API Quiz IP Filters
# @beta
#
# API for accessing quiz IP filters
#
# @model QuizIPFilter
#     {
#       "id": "QuizIPFilter",
#       "required": ["name", "account", "filter"],
#       "properties": {
#         "name": {
#           "description": "A unique name for the filter.",
#           "example": "Current Filter",
#           "type": "string"
#         },
#         "account": {
#           "description": "Name of the Account (or Quiz) the IP filter is defined in.",
#           "example": "Some Quiz",
#           "type": "string"
#         },
#         "filter": {
#           "description": "An IP address (or range mask) this filter embodies.",
#           "example": "192.168.1.1/24",
#           "type": "string"
#         }
#       }
#     }
#
class Quizzes::QuizIpFiltersController < ApplicationController
  include Api::V1::QuizIpFilter
  include Filters::Quizzes

  before_filter :require_user, :require_context, :require_quiz

  # @API Get available quiz IP filters.
  # @beta
  #
  # Get a list of available IP filters for this Quiz.
  #
  # <b>200 OK</b> response code is returned if the request was successful.
  #
  # @example_response
  #  {
  #    "quiz_ip_filters": [QuizIPFilter]
  #  }
  def index
    if authorized_action(@quiz, @current_user, :update)
      quiz_ip_filters = @quiz.available_ip_filters
      paginated_set = Api.paginate(quiz_ip_filters, self, api_v1_course_quiz_ip_filters_url(@context, @quiz))

      renderable = quiz_ip_filters_json(paginated_set, @context, @current_user, session)

      render :json => renderable
    end
  end
end
