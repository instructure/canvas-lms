# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module IgniteAgentHelper
  # Load ignite agent JS bundle for application layout if feature is enabled and user is not student-only
  def add_ignite_agent_bundle
    return unless @domain_root_account&.feature_enabled?(:ignite_agent_enabled)
    return unless @current_user

    return if user_has_only_student_enrollments?(@current_user)

    js_bundle :ignite_agent
    remote_env(ignite_agent: {
                 launch_url: Services::IgniteAgent.launch_url,
                 backend_url: Services::IgniteAgent.backend_url
               })
  end

  # Determines if a user has only student enrollments and no admin roles
  # Returns true if:
  # - User has no admin roles in the domain root account
  # - User has course enrollments
  # - All enrollments are StudentEnrollment or StudentViewEnrollment types
  def user_has_only_student_enrollments?(user)
    # Check if user has any admin roles in the account
    return false if @domain_root_account.account_users.where(user:).exists?

    # Get all non-deleted enrollments for the user
    enrollments = user.enrollments.active.shard(@domain_root_account.shard)

    # Return false if user has no enrollments (they're not a student)
    return false if enrollments.empty?

    # Check if all enrollments are student types (StudentEnrollment or StudentViewEnrollment)
    enrollments.all? { |e| %w[StudentEnrollment StudentViewEnrollment].include?(e.type) }
  end
end
