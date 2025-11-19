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

class LmgbUserDetailsController < ApplicationController
  include Outcomes::Enrollments

  before_action :require_user
  before_action :require_context
  before_action :require_outcome_context

  # @API Get LMGB user details
  #
  # Returns details about a user in the context of a course for LMGB
  #
  # @argument id [Required, String]
  #   The ID of the user to retrieve details for
  #
  # @returns LmgbUserDetails
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/users/2/lmgb_user_details \
  #     -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  # @example_response
  #   {
  #     "course": {
  #       "name": "Course's Name"
  #     },
  #     "user": {
  #       "sections": [
  #         {
  #           "id": 1,
  #           "name": "Section 1"
  #         },
  #         {
  #           "id": 2,
  #           "name": "Section 2"
  #         }
  #       ],
  #       "last_login": "2024-06-01T12:00:00Z"
  #     }
  #   }
  def show
    user = User.find(params[:id])

    # Get user's sections in this course
    sections = @context.course_sections.joins(:enrollments)
                       .where.not(enrollments: { workflow_state: "deleted" })
                       .where(enrollments: { user_id: user.id })
                       .distinct
                       .order(:name)

    # Get user's last login
    last_login = user.pseudonyms.where.not(last_login_at: nil)
                     .order(last_login_at: :desc)
                     .first&.last_login_at

    render json: {
      course: {
        name: @context.name
      },
      user: {
        sections: sections.map { |section| { id: section.id, name: section.name } },
        last_login: last_login&.iso8601
      }
    }
  end

  private

  # Authorization logic matching outcome_rollups
  def require_outcome_context
    reject! "invalid context type" unless @context.is_a?(Course)

    return true if @context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)

    # Students can only access their own data
    user_id = params[:id].to_i
    reject! "not authorized to read grades for specified user", :forbidden unless user_id == @current_user.id

    # Validate that the user_id is within the allowed set of users
    user_ids = Api.map_ids([params[:id]], users_for_outcome_context, @domain_root_account, @current_user)
    verify_readable_grade_enrollments(user_ids)
  end

  def users_for_outcome_context
    students = if @domain_root_account.feature_enabled?(:limit_section_visibility_in_lmgb)
                 @context.students_visible_to(@current_user, include: :priors)
               else
                 @context.all_students
               end
    students.distinct
  end
end
