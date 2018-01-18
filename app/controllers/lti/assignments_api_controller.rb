#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti
# @API Plagiarism Detection Platform Assignments
# **Plagiarism Detection Platform API for Assignments (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
#
# @model LtiAssignment
#     {
#       "id": "Assignment",
#       "description": "A Canvas assignment",
#       "properties": {
#         "id": {
#           "example": 4,
#           "type": "integer"
#         },
#         "name": {
#           "example": "Midterm Review",
#           "type": "string"
#         },
#         "description": {
#           "example": "<p>Do the following:</p>...",
#           "type": "string"
#         },
#         "points_possible": {
#           "example": 10,
#           "type": "integer"
#         },
#         "due_at": {
#           "description": "The due date for the assignment. If a user id is supplied and an assignment override is in place this field will reflect the due date as it applies to the user.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "lti_id": {
#           "example": "86157096483e6b3a50bfedc6bac902c0b20a824f",
#           "type": "string"
#         }
#       }
#     }
  class AssignmentsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper

    skip_before_action :load_user
    before_action :authorized_lti2_tool, :tool_proxy_related_to_assignment?, :user_related_to_assignment?

    ASSIGNMENT_SERVICE = 'vnd.Canvas.Assignment'.freeze
    SERVICE_DEFINITIONS = [
      {
        id: ASSIGNMENT_SERVICE,
        endpoint: 'api/lti/assignments/{assignment_id}',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze
    ].freeze

    def lti2_service_name
      ASSIGNMENT_SERVICE
    end

    # @API Get a single assignment (lti)
    #
    # Get a single Canvas assignment by Canvas id or LTI id. Tool providers may only access
    # assignments that are associated with their tool.
    # @argument user_id [String]
    #   The id of the user. Can be a Canvas or LTI id for the user.
    # @returns LtiAssignment
    def show
      render json: assignment_json(user.present? ? assignment.overridden_for(user) : assignment)
    end

    private

    def assignment_json(assignment_instance)
      {
        'id' => assignment_instance.id,
        'name' => assignment_instance.name,
        'description' => assignment_instance.description,
        'due_at' => assignment_instance.due_at,
        'points_possible' => assignment_instance.points_possible,
        'lti_id' => assignment_instance.lti_context_id,
        'lti_course_id' => Lti::Asset.opaque_identifier_for(assignment_instance.context)
      }
    end

    def assignment
      @_assignment ||= Assignment.find_by(lti_context_id: params[:assignment_id]) || Assignment.find(params[:assignment_id])
      raise ActiveRecord::RecordNotFound unless @_assignment
      @_assignment
    end

    def user
      if params[:user_id].present?
        @_user ||= User.find_by(lti_context_id: params[:user_id]) || User.find(params[:user_id])
        raise ActiveRecord::RecordNotFound unless @_user
        @_user
      end
    end

    def user_related_to_assignment?
      if user
        render_unauthorized_action if assignment.context.students.find_by_id(user).blank?
      end
    end

    def tool_proxy_related_to_assignment?
      configuration = AssignmentConfigurationToolLookup.find_by_assignment_id(assignment)
      if configuration
        codes = {
          vendor_code: configuration.tool_vendor_code,
          product_code: configuration.tool_product_code,
          resource_type_code: configuration.tool_resource_type_code
        }
      end
      render_unauthorized_action unless codes && tool_proxy.matches?(codes)
    end
  end
end
