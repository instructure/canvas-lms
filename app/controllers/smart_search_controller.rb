# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

# @API Smart Search
# @beta
#
# API for AI-powered course content search. NOTE: This feature has limited availability at present.
#
# @model SearchResult
#     {
#       "id": "SearchResult",
#       "description": "Reference to an object that matches a smart search",
#       "properties": {
#         "content_id": {
#           "description": "The ID of the matching object.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "content_type": {
#           "description": "The type of the matching object.",
#           "example": "WikiPage",
#           "type": "string"
#         },
#         "title": {
#           "description": "The title of the matching object.",
#           "example": "Nicolaus Copernicus",
#           "type": "string"
#         },
#        "body": {
#          "description": "The body of the matching object.",
#          "example": "Nicolaus Copernicus was a Renaissance-era mathematician and astronomer who...",
#          "type": "string"
#         },
#         "html_url": {
#           "description": "The Canvas URL of the matching object.",
#           "example": "https://canvas.example.com/courses/123/pages/nicolaus-copernicus",
#           "type": "string"
#         },
#         "distance": {
#           "description": "The distance between the search query and the result. Smaller numbers indicate closer matches.",
#           "example": "0.212",
#           "type": "number"
#         }
#       }
#     }
#
class SmartSearchController < ApplicationController
  include Api::V1::SearchResult

  before_action :require_context, only: :search
  before_action :require_user

  # TODO: Other ways of tuning results?
  MIN_DISTANCE = 0.70

  # @API Search course content
  # Find course content using a meaning-based search
  #
  # @argument q [String, required]
  #   The search query
  #
  # @argument filter[] [String, optional]
  #   Types of objects to search. By default, all supported types are searched. Supported types
  #   include +pages+, +assignments+, +announcements+, and +discussion_topics+.
  #
  # @returns [SearchResult]
  def search
    return render_unauthorized_action unless @context.grants_right?(@current_user, session, :read)
    return render_unauthorized_action unless SmartSearch.smart_search_available?(@context)
    return render json: { error: "missing 'q' param" }, status: :bad_request unless params.key?(:q)

    response = {
      results: []
    }

    if params[:q].present?
      scope = SmartSearch.perform_search(@context, @current_user, params[:q], Array(params[:filter]))
      items = Api.paginate(scope, self, api_v1_course_smart_search_query_url(@context))
      response[:results].concat(search_results_json(items))
    end

    render json: response
  end

  def log
    # TODO: do something more with these params than logging them in the request logs
    # params[:a]
    # params[:c]
    # params[:course_id]
    # params[:oid]
    # params[:ot]
    # params[:q]

    head :no_content
  end

  def show
    @context = Course.find(params[:course_id])

    return render_unauthorized_action unless SmartSearch.smart_search_available?(@context)

    set_active_tab("search")
    @show_left_side = true
    add_crumb(t("#crumbs.search", "Search"), named_context_url(@context, :course_search_url)) unless @skip_crumb
    js_env({
             COURSE_ID: @context.id.to_s
           })
  end
end
