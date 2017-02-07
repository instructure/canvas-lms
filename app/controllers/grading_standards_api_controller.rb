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

# @API Grading Standards
#
# @model GradingSchemeEntry
#     {
#       "id": "GradingSchemeEntry",
#       "description": "",
#       "properties": {
#         "name": {
#           "description": "The name for an entry value within a GradingStandard that describes the range of the value",
#           "example": "A",
#           "type": "string"
#         },
#         "value": {
#           "description": "The value for the name of the entry within a GradingStandard.  The entry represents the lower bound of the range for the entry. This range includes the value up to the next entry in the GradingStandard, or 100 if there is no upper bound. The lowest value will have a lower bound range of 0.",
#           "example": 0.9,
#           "type": "integer"
#         }
#       }
#     }
#
# @model GradingStandard
#     {
#       "id": "GradingStandard",
#       "description": "",
#       "properties": {
#         "title": {
#           "description": "the title of the grading standard",
#           "example": "Account Standard",
#           "type": "string"
#         },
#         "id": {
#           "description": "the id of the grading standard",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "description": "the context this standard is associated with, either 'Account' or 'Course'",
#           "example": "Account",
#           "type": "string"
#         },
#         "context_id": {
#           "description": "the id for the context either the Account or Course id",
#           "example": 1,
#           "type": "integer"
#         },
#         "grading_scheme": {
#           "description": "A list of GradingSchemeEntry that make up the Grading Standard as an array of values with the scheme name and value",
#           "example": [{"name":"A", "value":0.9}, {"name":"B", "value":0.8}, {"name":"C", "value":0.7}, {"name":"D", "value":0.6}],
#           "type": "array",
#           "items": {"$ref": "GradingSchemeEntry"}
#         }
#       }
#     }
#
class GradingStandardsApiController < ApplicationController
  include Api::V1::GradingStandard

  before_filter :require_user
  before_filter :require_context

  # @API Create a new grading standard
  # Create a new grading standard
  #
  #If grading_scheme_entry arguments are omitted, then a default grading scheme
  #will be set. The default scheme is as follows:
  #      "A" : 94,
  #      "A-" : 90,
  #      "B+" : 87,
  #      "B" : 84,
  #      "B-" : 80,
  #      "C+" : 77,
  #      "C" : 74,
  #      "C-" : 70,
  #      "D+" : 67,
  #      "D" : 64,
  #      "D-" : 61,
  #      "F" : 0,
  #
  # @argument title [Required, String]
  #   The title for the Grading Standard.
  #
  # @argument grading_scheme_entry[][name] [Required, String]
  #   The name for an entry value within a GradingStandard that describes the range of the value
  #   e.g. A-
  #
  # @argument grading_scheme_entry[][value] [Required, Integer]
  #   The value for the name of the entry within a GradingStandard.
  #   The entry represents the lower bound of the range for the entry.
  #   This range includes the value up to the next entry in the GradingStandard,
  #   or 100 if there is no upper bound. The lowest value will have a lower bound range of 0.
  #   e.g. 93
  #
  # @returns GradingStandard
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/grading_standards \
  #     -X POST \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'title=New standard name' \
  #     -d 'grading_scheme_entry[][name]=A'
  #     -d 'grading_scheme_entry[][value]=90'
  #     -d 'grading_scheme_entry[][name]=B'
  #     -d 'grading_scheme_entry[][value]=80'
  #
  # @example_response
  #   {
  #     "title": "New standard name",
  #     "id": 1,
  #     "context_id": 1,
  #     "context_type": "Course",
  #     "grading_scheme": [
  #       {"name": "A", "value": 0.9},
  #       {"name": "B", "value": 0.8}
  #     ]
  #   }
  def create
    if authorized_action(@context, @current_user, :manage_grades)
      @standard = @context.grading_standards.build(build_grading_scheme(params))
      @standard.user = @current_user
      respond_to do |format|
        if @standard.save
          format.json{ render :json => grading_standard_json(@standard, @current_user, session) }
        else
          format.json{ render :json => @standard.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API List the grading standards available in a context.
  #
  # Returns the list of grading standards in the given context that are visible to user.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/grading_standards \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [GradingStandard]
  def context_index
    if authorized_action(@context, @current_user, :read)
      grading_standards_json = @context.grading_standards.map do |g|
        grading_standard_json(g, @current_user, session)
      end
      render json: grading_standards_json
    end
  end

  private

  def build_grading_scheme(params)
    grading_standard_params = params.permit('title')
    grading_standard_params['standard_data']={}
    if params['grading_scheme_entry']
      params['grading_scheme_entry'].each_with_index do |scheme, index|
        grading_standard_params['standard_data']["scheme_#{index}"] = scheme
      end
    end
    grading_standard_params
  end
end
