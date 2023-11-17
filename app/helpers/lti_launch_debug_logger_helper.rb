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

# Multiple controllers handle launches, so this is used by each to make the
# debug logger and pass it through to Lti::AdvantageAdapter
# Kept in a separate file so we can rip it out easier when the time comes
module LtiLaunchDebugLoggerHelper
  def make_lti_launch_debug_logger(tool)
    return nil unless Lti::LaunchDebugLogger.log_level(@domain_root_account) > 0

    Lti::LaunchDebugLogger.new(
      tool:,
      request:,
      domain_root_account: @domain_root_account,
      pseudonym: @current_pseudonym,
      user: @current_user,
      session:,
      context: @context,
      context_enrollment: @context_enrollment,
      cookies:
    )
  end
end
