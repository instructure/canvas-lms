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
  # @returns [SearchResult]
  def search
    return render_unauthorized_action unless @context.grants_right?(@current_user, session, :read)
    return render_unauthorized_action unless OpenAi.smart_search_available?(@domain_root_account)
    return render json: { error: "missing 'q' param" }, status: :bad_request unless params.key?(:q)

    OpenAi.with_pgvector do
      response = {
        results: []
      }

      if params[:q].present?
        embedding = OpenAi.generate_embedding(params[:q])

        # Prototype query using "neighbor". Embedding is now on join table so manual SQL for now
        # wiki_pages = WikiPage.nearest_neighbors(:embedding, embedding, distance: "inner_product")
        # response[:results].concat( wiki_pages.select { |x| x.neighbor_distance >= MIN_DISTANCE }.first(MAX_RESULT))
        # Wiki Pages
        scope = @context.wiki_pages.not_deleted
        scope = WikiPages::ScopedToUser.new(@context, @current_user, scope).scope
                                       .select(WikiPage.send(:sanitize_sql, ["wiki_pages.*, MIN(wpe.embedding <=> ?) AS distance", embedding.to_s]))
                                       .joins("INNER JOIN #{WikiPageEmbedding.quoted_table_name} wpe ON wiki_pages.id = wpe.wiki_page_id")
                                       .group("wiki_pages.id")
                                       .order("distance ASC")
        wiki_pages = Api.paginate(scope, self, api_v1_course_smart_search_query_url(@context))
        response[:results].concat(search_results_json(wiki_pages))
      end

      render json: response
    end
  end

  def show
    render_unauthorized_action unless OpenAi.smart_search_available?(@domain_root_account)
    # TODO: Add state required for new page render
  end
end
