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

# @API Accessibility Course Scans
class AccessibilityCourseScansController < ApplicationController
  include Api::V1::Progress

  before_action :require_user

  # @API Trigger accessibility course scan
  #
  # Queues a background job that scans all a11y-enabled courses where the
  # user has an active teacher or designer enrollment. Idempotent — if a
  # scan is already queued or running, the existing Progress is returned.
  #
  # Requires the educator_dashboard feature flag on the root account and
  # a11y_checker_account_statistics on site admin.
  #
  # @argument user_id [Required, String]
  #   The ID of the user, or "self" for the current user.
  #   The requesting user may only trigger a scan for themselves.
  #
  # @returns Progress
  def create
    return render_unauthorized_action unless @domain_root_account.feature_enabled?(:educator_dashboard) &&
                                             @domain_root_account.a11y_checker_account_statistics?

    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless user == @current_user

    # TODO: This enrollment check is duplicated in AccessibilityCourseStatisticsController
    # and UserCourseScanService. Extract to a shared concern when scaling. (ref EGG-2606)
    has_educator_enrollment = user
                              .enrollments
                              .active
                              .where(type: %w[TeacherEnrollment DesignerEnrollment])
                              .joins(:course)
                              .where.not(courses: { workflow_state: %w[completed deleted] })
                              .exists?
    return render_unauthorized_action unless has_educator_enrollment

    progress = Accessibility::UserCourseScanService.queue_user_courses_scan(user, @domain_root_account)
    return render_unauthorized_action if progress.nil?

    render json: progress_json(progress, @current_user, session)
  end
end
