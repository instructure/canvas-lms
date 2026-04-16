# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

# @API Accessibility Course Statistics
#
# @model AccessibilityCourseStatistic
#   {
#     "id": "AccessibilityCourseStatistic",
#     "description": "Per-course accessibility issue counts for a user's active teacher/designer courses.",
#     "properties": {
#       "id": {
#         "description": "The ID of the accessibility course statistic record",
#         "example": 1,
#         "type": "integer"
#       },
#       "course_id": {
#         "description": "The ID of the course",
#         "example": 42,
#         "type": "integer"
#       },
#       "course_name": {
#         "description": "The name of the course",
#         "example": "Introduction to Biology",
#         "type": "string"
#       },
#       "course_code": {
#         "description": "The course code (short name) of the course",
#         "example": "BIO101",
#         "type": "string"
#       },
#       "published": {
#         "description": "Whether the course is published",
#         "example": true,
#         "type": "boolean"
#       },
#       "active_issue_count": {
#         "description": "The number of active accessibility issues in the course",
#         "example": 5,
#         "type": "integer"
#       },
#       "resolved_issue_count": {
#         "description": "The number of resolved accessibility issues in the course",
#         "example": 3,
#         "type": "integer"
#       },
#       "closed_issue_count": {
#         "description": "The number of closed accessibility issues in the course",
#         "example": 2,
#         "type": "integer"
#       },
#       "workflow_state": {
#         "description": "The workflow state of the statistic record",
#         "example": "active",
#         "type": "string"
#       },
#       "created_at": {
#         "description": "The date and time the record was created",
#         "example": "2026-01-01T00:00:00Z",
#         "type": "datetime"
#       },
#       "updated_at": {
#         "description": "The date and time the record was last updated",
#         "example": "2026-01-02T00:00:00Z",
#         "type": "datetime"
#       }
#     }
#   }
class AccessibilityCourseStatisticsController < ApplicationController
  include Api::V1::AccessibilityCourseStatistic

  before_action :require_user

  # @API List accessibility course statistics
  #
  # Returns per-course accessibility issue statistics for the current user's
  # active teacher and designer courses. Only courses where the accessibility
  # checker is enabled and whose workflow state is neither completed nor deleted
  # are included. Only statistic records with workflow_state "active" are returned.
  #
  # Requires the educator_dashboard feature flag to be enabled on the root
  # account, and a11y_checker_account_statistics on site admin plus a11y_checker
  # on the account (i.e. a11y_checker_account_statistics? must be true).
  #
  # @argument user_id [Required, String]
  #   The ID of the user, or "self" for the current user.
  #   The requesting user may only retrieve their own statistics.
  #
  # @returns [AccessibilityCourseStatistic]
  def index
    return render_unauthorized_action unless @domain_root_account.feature_enabled?(:educator_dashboard) &&
                                             @domain_root_account.a11y_checker_account_statistics?

    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless user == @current_user

    # TODO: Replace enrollment type check with grants_any_right? using
    # RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS to mirror
    # the permission check used to show the Accessibility tab in a course
    # (see Course#tabs_available, course.rb:3696). Tracked in scale ticket.
    # (refer to EGG-2452)
    educator_course_ids = user
                          .enrollments
                          .active
                          .where(type: %w[TeacherEnrollment DesignerEnrollment])
                          .joins(:course)
                          .where.not(courses: { workflow_state: %w[completed deleted] })
                          .select(:course_id)

    return render_unauthorized_action unless educator_course_ids.exists?

    # TODO: When a11y_checker_ga1 is on, all courses under the account are eligible —
    # keep educator_course_ids as a subquery and skip per-course flag lookups.
    # Otherwise fall back to a per-course a11y_checker_enabled? check.
    # Preloading :account ensures the account-level flag calls are cached after
    # the first course. The per-course feature_flag(:a11y_checker_eap) lookup is
    # still N queries — acceptable for this non-scale-ready implementation but
    # will be need to be revisited for EAP. (refer to EGG-2452)
    a11y_enabled_course_ids = if @domain_root_account.feature_enabled?(:a11y_checker_ga1)
                                educator_course_ids
                              else
                                Course.where(id: educator_course_ids)
                                      .preload(:account)
                                      .select(&:a11y_checker_enabled?)
                                      .map(&:id)
                              end

    statistics = AccessibilityCourseStatistic.where(
      course_id: a11y_enabled_course_ids,
      workflow_state: "active"
    ).preload(:course)

    paginated = Api.paginate(
      statistics,
      self,
      api_v1_user_educator_accessibility_course_statistics_url(user)
    )

    render json: paginated.map { |stat|
      accessibility_course_statistic_json(stat, @current_user, session, include_closed: true, include_course_details: true)
    }
  end
end
