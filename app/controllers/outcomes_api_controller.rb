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

# @API Outcomes
#
# API for accessing learning outcome information.
#
# @object Outcome
#
#     {
#       // the ID of the outcome
#       "id": 1,
#
#       // the URL for fetching/updating the outcome. should be treated as
#       // opaque
#       "url": "/api/v1/outcomes/1",
#
#       // the context owning the outcome. may be null for global outcomes
#       "context_id": 1,
#       "context_type": "Account",
#
#       // title of the outcome
#       "title": "Outcome title",
#
#       // description of the outcome. omitted in the abbreviated form.
#       "description": "Outcome description",
#
#       // maximum points possible. included only if the outcome embeds a
#       // rubric criterion. omitted in the abbreviated form.
#       "points_possible": 5,
#
#       // points necessary to demonstrate mastery outcomes. included only if
#       // the outcome embeds a rubric criterion. omitted in the abbreviated
#       // form.
#       "mastery_points": 3,
#
#       // possible ratings for this outcome. included only if the outcome
#       // embeds a rubric criterion. omitted in the abbreviated form.
#       "ratings": [
#         { "description": "Exceeds Expectations", "points": 5 },
#         { "description": "Meets Expectations", "points": 3 },
#         { "description": "Does Not Meet Expectations", "points": 0 }
#       ],
#
#       // whether the current user can update the outcome
#       "can_edit": true
#     }
#
class OutcomesApiController < ApplicationController
  include Api::V1::Outcome

  before_filter :require_user
  before_filter :get_outcome

  # @API Show an outcome
  #
  # Returns the details of the outcome with the given id.
  #
  # @returns Outcome
  #
  def show
    if authorized_action(@outcome, @current_user, :read)
      render :json => outcome_json(@outcome, @current_user, session)
    end
  end

  # @API Update an outcome
  #
  # Modify an existing outcome. Fields not provided are left as is;
  # unrecognized fields are ignored.
  #
  # If any new ratings are provided, the combination of all new ratings
  # provided completely replace any existing embedded rubric criterion; it is
  # not possible to tweak the ratings of the embedded rubric criterion.
  #
  # A new embedded rubric criterion's mastery_points default to the maximum
  # points in the highest rating if not specified in the mastery_points
  # parameter. Any new ratings lacking a description are given a default of "No
  # description". Any new ratings lacking a point value are given a default of
  # 0.
  #
  # @argument title [Optional] The new outcome title.
  # @argument description [Optional] The new outcome description.
  # @argument mastery_points [Optional, Integer] The new mastery threshold for the embedded rubric criterion.
  # @argument ratings[][description] [Optional] The description of a new rating level for the embedded rubric criterion.
  # @argument ratings[][points] [Optional, Integer] The points corresponding to a new rating level for the embedded rubric criterion.
  #
  # @returns Outcome
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/outcomes/1.json' \ 
  #        -X PUT \ 
  #        -F 'title=Outcome Title' \ 
  #        -F 'description=Outcome description' \ 
  #        -F 'mastery_points=3' \ 
  #        -F 'ratings[][description]=Exceeds Expectations' \ 
  #        -F 'ratings[][points]=5' \ 
  #        -F 'ratings[][description]=Meets Expectations' \ 
  #        -F 'ratings[][points]=3' \ 
  #        -F 'ratings[][description]=Does Not Meet Expectations' \ 
  #        -F 'ratings[][points]=0' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/outcomes/1.json' \ 
  #        -X PUT \ 
  #        --data-binary '{
  #              "title": "Outcome Title",
  #              "description": "Outcome description",
  #              "mastery_points": 3,
  #              "ratings": [
  #                { "description": "Exceeds Expectations", "points": 5 },
  #                { "description": "Meets Expectations", "points": 3 },
  #                { "description": "Does Not Meet Expectations", "points": 0 }
  #              ]
  #            }' \ 
  #        -H "Content-Type: application/json" \ 
  #        -H "Authorization: Bearer <token>"
  #
  def update
    if authorized_action(@outcome, @current_user, :update)
      @outcome.update_attributes(params.slice(:title, :description))
      if params[:mastery_points] || params[:ratings]
        criterion = @outcome.data && @outcome.data[:rubric_criterion]
        criterion ||= {}
        if params[:mastery_points]
          criterion[:mastery_points] = params[:mastery_points]
        else
          criterion.delete(:mastery_points)
        end
        if params[:ratings]
          criterion[:ratings] = params[:ratings]
        end
        @outcome.rubric_criterion = criterion
      end
      if @outcome.save
        render :json => outcome_json(@outcome, @current_user, session)
      else
        render :json => @outcome.errors, :status => :bad_request
      end
    end
  end

  protected

  def get_outcome
    @outcome = LearningOutcome.active.find(params[:id])
  end
end
