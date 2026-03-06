# frozen_string_literal: true

#
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
#

# Matcher for IRB::Abort exceptions that works even when the irb gem is not loaded.
# This allows rescue clauses to catch IRB::Abort without directly referencing the
# constant, which would fail if irb is not available.
class AbortExceptionMatcher
  def self.===(other)
    return true if defined?(IRB::Abort) && other.is_a?(IRB::Abort)

    false
  end
end
