# frozen_string_literal: true

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

module Lti::IMS
  # @API Result
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
  #            "type": "string"
  #          },
  #          "resultScore": {
  #            "description": "The score of the result as defined by Canvas, scaled to the resultMaximum",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "resultMaximum": {
  #            "description": "Maximum possible score for this result; 1 is the default value and will be assumed if not specified otherwise. Minimum value of 0 required.",
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

    before_action :verify_line_item_in_context
    before_action :verify_result_in_line_item, only: %i[show]

    MIME_TYPE = "application/vnd.ims.lis.v2.resultcontainer+json"

    # @API Show a collection of Results
    #
    # Show existing Results of a line item. Can be used to retrieve a specific student's
    # result by adding the user_id (defined as the lti_user_id or the Canvas user_id) as
    # a query parameter (i.e. user_id=1000). If user_id is included, it will return only
    # one Result in the collection if the result exists, otherwise it will be empty. May
    # also limit number of results by adding the limit query param (i.e. limit=100)
    #
    # @returns Result
    def index
      render(json: [], content_type: MIME_TYPE) and return if user.present? && !context.user_is_student?(user)

      results = Lti::Result.active.where(line_item:).preload(:assignment, :submission)
      results = results.where(user:).preload(:user) if params.key?(:user_id)
      results = Api.paginate(results, self, "#{line_item_url}/results", pagination_args)
      render json: results_collection(results), content_type: MIME_TYPE
    end

    # @API Show a Result
    #
    # Show existing Result of a line item.
    #
    # @returns Result
    def show
      render json: Lti::IMS::ResultsSerializer.new(result, line_item_url).as_json, content_type: MIME_TYPE
    end

    private

    def scopes_matcher
      # Spec seems to strongly imply this scope is sufficient. I.e. even tho a Result belongs to a LineItem,
      # doesn't look like we're compelled to require at least one of LTI_AGS_LINE_ITEM_SCOPE and
      # LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE
      self.class.all_of(TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE)
    end

    def verify_result_in_line_item
      raise ActiveRecord::RecordNotFound unless result.line_item == line_item
    end

    def line_item_url
      lti_line_item_show_url(
        host: line_item.root_account.environment_specific_domain,
        course_id: params[:course_id],
        id: params[:line_item_id]
      )
    end

    def result
      @_result = Lti::Result.active.find(params[:id])
    end

    def results_collection(results)
      results.map do |result|
        Lti::IMS::ResultsSerializer.new(result, line_item_url).as_json
      end
    end
  end
end
