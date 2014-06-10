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
  # Manage live assessments
  #
  # @model Assessment
  #     {
  #       "id": "Assessment",
  #       "description": "A simple assessment that collects pass/fail results for a student",
  #       "properties": {
  #         "id": {
  #           "type": "string",
  #           "example": "42",
  #           "description": "A unique identifier for this live assessment"
  #         },
  #         "key": {
  #           "type": "string",
  #           "example": "2014-05-27,outcome_52",
  #           "description": "A client specified unique identifier for the assessment"
  #         },
  #         "title": {
  #           "type": "string",
  #           "example": "May 27th Reading Assessment",
  #           "description": "A human readable title for the assessment"
  #         }
  #       }
  #     }

  class AssessmentsController < ApplicationController
    before_filter :require_user
    before_filter :require_context

    # @API Create or find a live assessment
    # @beta
    #
    # Creates or finds an existing live assessment with the given key and aligns it with
    # the linked outcome
    #
    # @example_request
    #  {
    #    "assessments": [{
    #      "key": "2014-05-27-Outcome-52",
    #      "title": "Tuesday's LiveAssessment",
    #      "links": {
    #        "outcome": "1"
    #      }
    #    }]
    #  }
    #
    # @example_response
    #  {
    #    "links": {
    #      "assessments.results": "http://example.com/courses/1/live_assessments/5/results"
    #    },
    #    "assessments": [Assessment]
    #  }
    #
    def create
      return unless authorized_action(Assessment.new(context: @context), @current_user, :create)
      reject! 'missing required key :assessments' unless params[:assessments].is_a?(Array)

      @assessments = []

      Assessment.transaction do
        params[:assessments].each do |assessment_hash|
          if assessment_hash[:links] && outcome_id = assessment_hash[:links][:outcome]
            return unless authorized_action(@context, @current_user, :manage_outcomes)
            @outcome = @context.linked_learning_outcomes.where(id: outcome_id).first
            reject! 'outcome must be linked to the context' unless @outcome
          end

          reject! 'missing required key :title' if assessment_hash[:title].blank?
          reject! 'missing required key :key' if assessment_hash[:key].blank?
          assessment = Assessment.find_or_initialize_by_context_id_and_context_type_and_key(@context.id, @context.class.to_s, assessment_hash[:key])
          assessment.title = assessment_hash[:title]
          assessment.save!
          if @outcome
            criterion = @outcome.data && @outcome.data[:rubric_criterion]
            mastery_score = criterion && criterion[:mastery_points] / criterion[:points_possible]
            @outcome.align(assessment, @context, mastery_type: "none", mastery_score: mastery_score)
          end
          @assessments << assessment
        end
      end

      render json: serialize_jsonapi(@assessments)
    end

    # @API List live assessments
    # @beta
    #
    # Returns a list of live assessments.
    #
    # @example_response
    #  {
    #    "links": {
    #      "assessments.results": "http://example.com/courses/1/live_assessments/{assessments.id}/results"
    #    },
    #    "assessments": [Assessment]
    #  }
    #
    def index
      return unless authorized_action(Assessment.new(context: @context), @current_user, :read)

      @assessments = Assessment.for_context(@context)
      @assessments, meta = Api.jsonapi_paginate(@assessments, self, polymorphic_url([:api_v1, @context, :live_assessments]))

      render json: serialize_jsonapi(@assessments).merge(meta: meta)
    end

    protected

    def serialize_jsonapi(assessments)
      serialized = Canvas::APIArraySerializer.new(assessments, {
                                                    each_serializer: LiveAssessments::AssessmentSerializer,
                                                    controller: self,
                                                    scope: @current_user,
                                                    root: false,
                                                    include_root: false
                                                  }).as_json
      {
        links: {
          'assessments.results' => polymorphic_url([:api_v1, @context]) + '/live_assessments/{assessments.id}/results'
        },
        assessments: serialized
      }
    end
  end
end
