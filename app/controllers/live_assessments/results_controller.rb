#
# Copyright (C) 2014 Instructure, Inc.
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

module LiveAssessments
  # @API LiveAssessments
  # @beta
  # Manage live assessment results
  #
  # @model Result
  #     {
  #       "id": "Result",
  #       "description": "A pass/fail results for a student",
  #       "properties": {
  #         "id": {
  #           "type": "string",
  #           "example": "42",
  #           "description": "A unique identifier for this result"
  #         },
  #         "passed": {
  #           "type": "boolean",
  #           "example": true,
  #           "description": "Whether the user passed or not"
  #         },
  #         "assessed_at": {
  #           "type": "datetime",
  #           "example": "2014-05-13T00:01:57-06:00",
  #           "description": "When this result was recorded"
  #         },
  #         "links": {
  #           "$ref": "ResultLinks",
  #           "example": {"user": "42", "assessor": "23", "assessment": "5"},
  #           "description": "Unique identifiers of objects associated with this result"
  #         }
  #       }
  #     }
  #
  # @model ResultLinks
  #     {
  #       "id": "ResultLinks",
  #       "description": "Unique identifiers of objects associated with a result",
  #       "properties": {
  #         "user": {
  #           "type": "string",
  #           "example": "42",
  #           "description": "A unique identifier for the user to whom this result applies"
  #         },
  #         "assessor": {
  #           "type": "string",
  #           "example": "23",
  #           "description": "A unique identifier for the user who created this result"
  #         },
  #         "assessment": {
  #           "type": "string",
  #           "example": "5",
  #           "description": "A unique identifier for the assessment that this result is for"
  #         }
  #       }
  #     }
  class ResultsController < ApplicationController
    include ::Filters::LiveAssessments

    before_action :require_user
    before_action :require_context
    before_action :require_assessment

    # @API Create live assessment results
    # @beta
    #
    # Creates live assessment results and adds them to a live assessment
    #
    # @example_request
    #  {
    #    "results": [{
    #      "passed": false,
    #      "assessed_at": "2014-05-26T14:57:23-07:00",
    #      "links": {
    #        "user": "15"
    #      }
    #    },{
    #      "passed": true,
    #      "assessed_at": "2014-05-26T13:05:40-07:00",
    #      "links": {
    #        "user": "16"
    #      }
    #    }]
    #  }
    #
    # @example_response
    #  {
    #    "results": [Result]
    #  }
    #
    def create
      return unless authorized_action(@assessment.results.new, @current_user, :create)
      reject! 'missing required key :results' unless params[:results].is_a?(Array)

      @results = []
      result_hashes_by_user_id = params[:results].group_by {|result| result[:links] and result[:links][:user]}
      Result.transaction do
        result_hashes_by_user_id.each do |user_id, result_hashes|
          reject! 'missing required key :user' unless user_id
          @user = @context.users.where(id: user_id).first
          reject! 'user must be in the context' unless @user

          result_hashes.each do |result_hash|
            result = @assessment.results.build(
              user: @user,
              assessor: @current_user,
              passed: result_hash[:passed],
              assessed_at: result_hash[:assessed_at]
            )
            result.save!
            @results << result
          end
        end
      end

      @assessment.send_later_if_production(:generate_submissions_for, @results.map(&:user).uniq)
      render json: serialize_jsonapi(@results)
    end

    # @API List live assessment results
    # @beta
    #
    # Returns a list of live assessment results
    #
    # @argument user_id [Integer]
    #   If set, restrict results to those for this user
    #
    # @example_response
    #  {
    #    "results": [Result]
    #  }
    #
    def index
      return unless authorized_action(@assessment.results.new, @current_user, :read)
      @results = @assessment.results
      @results = @results.for_user(params[:user_id]) if params[:user_id]
      @results, meta = Api.jsonapi_paginate(@results, self, polymorphic_url([:api_v1, @context, :live_assessment_results], assessment_id: @assessment.id))

      render json: serialize_jsonapi(@results).merge(meta: meta)
    end

    protected

    def serialize_jsonapi(results)
      serialized = Canvas::APIArraySerializer.new(results, {
                                                    each_serializer: LiveAssessments::ResultSerializer,
                                                    controller: self,
                                                    scope: @current_user,
                                                    root: false,
                                                    include_root: false
                                                  }).as_json
      { results: serialized }
    end
  end
end
