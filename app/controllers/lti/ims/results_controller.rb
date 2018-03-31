#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Ims
  # @API Result
  # @internal
  #
  # TODO: remove internal flags
  #
  # Result API for IMS Assignment and Grade Services
  #
  # @model Result
  #     {
  #       "id": "Result",
  #       "description": "",
  #       "properties": {
  #          "id": {
  #            "description": "The fully qualified URL for showing the Result",
  #            "example": "http://institution.canvas.com/api/lti/courses/5/line_items/2/results/1",
  #            "type": "string"
  #          },
  #          "userId": {
  #            "description": "The lti_user_id or the Canvas user_id",
  #            "example": "50 | 'abcasdf'",
  #            "type": "number|string"
  #          },
  #          "resultScore": {
  #            "description": "The score of the result as defined by Canvas, scaled to the resultMaximum",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "resultMaximum": {
  #            "description": "Maximum possible score for this result;
  #                            1 is the default value and will be assumed if not specified otherwise. Minimum
  #                            value of 0 required.",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "comment": {
  #            "description": "Comment visible to the student about the result.",
  #            "type": "string"
  #          },
  #          "scoreOf": {
  #            "description": "URL of the line item this belongs to",
  #            "example": "http://institution.canvas.com/api/lti/courses/5/line_items/2",
  #            "type": "string"
  #          }
  #       }
  #     }
  class ResultsController < ApplicationController
    include Concerns::GradebookServices

    skip_before_action :load_user
    before_action(
      :verify_tool_in_context,
      :verify_tool_permissions,
      :verify_line_item_in_context
    )
    before_action :verify_result_in_line_item, only: %i[show]

    MIME_TYPE = 'application/vnd.ims.lis.v2.resultcontainer+json'.freeze

    # @API Show a collection of Results
    # @internal
    #
    # Show existing Results of a line item. Can be used to retrieve a specific student's
    # result by adding the user_id (defined as the lti_user_id or the Canvas user_id) as
    # a query parameter (i.e. user_id=1000). If user_id is included, it will return only
    # one Result in the collection if the result exists, otherwise it will be empty. May
    # also limit number of results by adding the limit query param (i.e. limit=100)
    #
    # @returns Result
    def index
      render(json: [], content_type: MIME_TYPE) && return if user.present? && !context.user_is_student?(user)

      results = Lti::Result.where(line_item: line_item)
      results = results.where(user: user) if params.key?(:user_id)
      results = Api.paginate(results, self, results_url, pagination_args)
      render json: results_collection(results), content_type: MIME_TYPE
    end

    # @API Show a Result
    # @internal
    #
    # Show existing Result of a line item.
    #
    # @returns Result
    def show
      render json: Lti::Ims::ResultsSerializer.new(result, line_item_url).as_json, content_type: MIME_TYPE
    end

    private

    def verify_result_in_line_item
      raise ActiveRecord::RecordNotFound unless result.line_item == line_item
    end

    def results_url
      "#{line_item_url}/results"
    end

    def line_item_url
      lti_line_item_show_url(course_id: params[:course_id], id: params[:line_item_id])
    end

    def result
      @_result = Lti::Result.find(params[:id])
    end

    def pagination_args
      params[:limit] ? { per_page: params[:limit] } : {}
    end

    def results_collection(results)
      results.map do |result|
        Lti::Ims::ResultsSerializer.new(result, line_item_url).as_json
      end
    end
  end
end
