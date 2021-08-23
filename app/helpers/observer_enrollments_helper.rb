# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module ObserverEnrollmentsHelper
  include Api::V1::User

  MAX_OBSERVED_USERS = 1000
  SELECTED_OBSERVED_USER_COOKIE = "k5_observed_user_id"

  # Returns users whom the user is observing. Sorted by sortable_name. Includes the
  # provided user first if they have their own non-ObserverEnrollment enrollments.
  # Uses all enrollments if course_id is nil, otherwise restricts results to provided
  # course.
  def observed_users(user, session, course_id = nil)
    users = Rails.cache.fetch_with_batched_keys(["observed_users", course_id].cache_key, batch_object: user, batched_keys: :enrollments, expires_in: 1.hour) do
      GuardRail.activate(:secondary) do
        scope = user.enrollments.active_or_pending
        scope = scope.where(course_id: course_id) if course_id
        has_own_enrollments = scope.not_of_observer_type.exists?
        users = User.where(
          id: scope.of_observer_type.where("associated_user_id IS NOT NULL").limit(MAX_OBSERVED_USERS).pluck(:associated_user_id)
        ).order_by_sortable_name.to_a
        users.prepend(user) if has_own_enrollments
        users
      end
    end

    @selected_observed_user = users.detect { |u| u.id.to_s == cookies[SELECTED_OBSERVED_USER_COOKIE] } || users.first
    users.map{ |u| user_json(u, @current_user, session, ['avatar_url'], @context, nil, ['pseudonym']) }
  end
end
