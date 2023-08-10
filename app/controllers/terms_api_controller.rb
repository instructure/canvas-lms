# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# @API Enrollment Terms
#
# API for viewing enrollment terms.  For all actions, the specified account
# must be a root account and the caller must have permission to manage the
# account (when called on non-root accounts, the errorwill be indicate the
# appropriate root account).
#
# @model EnrollmentTerm
#     {
#       "id": "EnrollmentTerm",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the enrollment term.",
#           "example": "1",
#           "type": "integer"
#         },
#         "sis_term_id": {
#           "description": "The SIS id of the term. Only included if the user has permission to view SIS information.",
#           "example": "Sp2014",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "the unique identifier for the SIS import. This field is only included if the user has permission to manage SIS information.",
#           "example": 34,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the term.",
#           "example": "Spring 2014",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "The datetime of the start of the term.",
#           "example": "2014-01-06T08:00:00-05:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "The datetime of the end of the term.",
#           "example": "2014-05-16T05:00:00-04:00",
#           "type": "datetime"
#         },
#           "workflow_state": {
#           "description": "The state of the term. Can be 'active' or 'deleted'.",
#           "example": "active",
#           "type": "string"
#         },
#         "overrides": {
#           "description": "Term date overrides for specific enrollment types",
#           "example": {"StudentEnrollment": {"start_at": "2014-01-07T08:00:00-05:00", "end_at": "2014-05-14T05:00:00-04:0"}},
#           "type": "object"
#         },
#         "course_count": {
#           "description": "The number of courses in the term (available via include)",
#           "example": "80",
#           "type": "integer"
#         }
#       }
#     }
#
# @model EnrollmentTermsList
#     {
#       "id": "EnrollmentTermsList",
#       "description": "",
#       "properties": {
#         "enrollment_terms": {
#           "description": "a paginated list of all terms in the account",
#           "type": "array",
#           "example": [],
#           "items": { "$ref": "EnrollmentTerm" }
#         }
#       }
#     }
#
class TermsApiController < ApplicationController
  PER_PAGE = 20

  before_action :require_context, :require_root_account, :require_account_access

  include Api::V1::EnrollmentTerm

  # @API List enrollment terms
  #
  # An object with a paginated list of all of the terms in the account.
  #
  # @argument workflow_state[] [String, "active"|"deleted"|"all"]
  #   If set, only returns terms that are in the given state.
  #   Defaults to 'active'.
  #
  # @argument include[] [String, "overrides"]
  #   Array of additional information to include.
  #
  #   "overrides":: term start/end dates overridden for different enrollment types
  #   "course_count":: the number of courses in each term
  #
  # @argument term_name [String]
  #  If set, only returns terms that match the given search keyword.
  #  Search keyword is matched against term name.
  #
  # @example_request
  #   curl -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/1/terms?include[]=overrides
  #
  # @example_response
  #   {
  #     "enrollment_terms": [
  #       {
  #         "id": 1,
  #         "name": "Fall 20X6"
  #         "start_at": "2026-08-31T20:00:00Z",
  #         "end_at": "2026-12-20T20:00:00Z",
  #         "created_at": "2025-01-02T03:43:11Z",
  #         "workflow_state": "active",
  #         "grading_period_group_id": 1,
  #         "sis_term_id": null,
  #         "overrides": {
  #           "StudentEnrollment": {
  #             "start_at": "2026-09-03T20:00:00Z",
  #             "end_at": "2026-12-19T20:00:00Z"
  #           },
  #           "TeacherEnrollment": {
  #             "start_at": null,
  #             "end_at": "2026-12-30T20:00:00Z"
  #           }
  #         }
  #       }
  #     ]
  #   }
  #
  # @returns EnrollmentTermsList
  def index
    @terms = @context.enrollment_terms

    @term_name = params[:term_name]
    if @term_name.present?
      @terms = @terms.where(["name ILIKE ?", "%#{@term_name}%"])
    end

    respond_to do |format|
      format.html do
        @root_account = @context.root_account

        @terms = @terms.active.preload(:enrollment_dates_overrides)
        @terms = @terms.order(Arel.sql("COALESCE(start_at, created_at) DESC"))
        @terms = @terms.paginate(per_page: PER_PAGE, page: params[:page])

        @course_counts_by_term = EnrollmentTerm.course_counts(@terms)
      end
      format.json do
        state = Array(params[:workflow_state]) & %w[all active deleted]
        state = "active" if state == []
        state = nil if Array(state).include?("all")

        @terms = @terms.where(workflow_state: state) if state.present?
        @terms = @terms.order("start_at DESC, end_at DESC, id ASC")
        @terms = Api.paginate(@terms,
                              self,
                              api_v1_enrollment_terms_url)

        render json: { enrollment_terms:
                         enrollment_terms_json(
                           @terms,
                           @current_user,
                           session,
                           nil,
                           Array(params[:include])
                         ) }
      end
    end
  end

  # @API Retrieve enrollment term
  #
  # Retrieves the details for an enrollment term in the account. Includes overrides by default.
  #
  # @example_request
  #   curl -H 'Authorization: Bearer <token>' \
  #   https://<canvas>/api/v1/accounts/1/terms/2
  #
  # @returns EnrollmentTerm
  def show
    term = api_find(@context.enrollment_terms, params[:id])
    render json: enrollment_term_json(term, @current_user, session, nil, %w[course_count overrides])
  end

  protected

  def require_root_account
    unless @context.root_account?
      render json: { message: "Terms only belong to root_accounts." }, status: :bad_request
      false
    end
  end

  def require_account_access
    authorized_action(@context, @current_user, :read_terms)
  end
end
