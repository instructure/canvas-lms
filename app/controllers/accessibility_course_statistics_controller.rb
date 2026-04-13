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

class AccessibilityCourseStatisticsController < ApplicationController
  include Api::V1::AccessibilityCourseStatistic

  before_action :require_user

  # GET /api/v1/users/:user_id/educator_accessibility_course_statistics
  #
  # Returns per-course a11y statistics for the requested user's active
  # teacher/designer courses. Only records with workflow_state "active"
  # in accessibility_course_statistics are included.
  #
  # Requires the following feature flags to be enabled:
  #   - educator_dashboard (RootAccount)
  #   - a11y_checker_account_statistics (SiteAdmin) AND a11y_checker (Account)
  #     i.e. @domain_root_account.a11y_checker_account_statistics? must be true
  #
  # Returns 401 if the user is not authenticated.
  # Returns 403 if:
  #   - educator_dashboard is not enabled on the root account
  #   - a11y_checker_account_statistics? is false on the root account
  #   - user_id resolves to a user other than the current user
  #   - the current user has no TeacherEnrollment or DesignerEnrollment
  #     in a non-completed, non-deleted course
  #
  # @returns [AccessibilityCourseStatistic]
  def index
    return render_unauthorized_action unless @domain_root_account.feature_enabled?(:educator_dashboard) &&
                                             @domain_root_account.a11y_checker_account_statistics?

    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless user == @current_user

    educator_course_ids = user
                          .enrollments
                          .active
                          .where(type: %w[TeacherEnrollment DesignerEnrollment])
                          .joins(:course)
                          .where.not(courses: { workflow_state: %w[completed deleted] })
                          .select(:course_id)

    return render_unauthorized_action unless educator_course_ids.exists?

    # When a11y_checker_ga1 is on, all courses under the account are eligible —
    # keep educator_course_ids as a subquery and skip per-course flag lookups.
    # Otherwise fall back to a per-course a11y_checker_enabled? check.
    # Preloading :account ensures the account-level flag calls are cached after
    # the first course. The per-course feature_flag(:a11y_checker_eap) lookup is
    # still N queries — acceptable for this non-scale-ready impl (EGG-2451).
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
    )

    paginated = Api.paginate(
      statistics,
      self,
      api_v1_user_educator_accessibility_course_statistics_url(user)
    )

    render json: paginated.map { |stat|
      accessibility_course_statistic_json(stat, @current_user, session, include_closed: true)
    }
  end
end
