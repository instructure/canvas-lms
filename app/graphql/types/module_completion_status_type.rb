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
#

module Types
  class ModuleCompletionStatusType < Types::BaseEnum
    description "Filter options for module completion status"

    value "COMPLETED", "Modules marked as completed", value: "completed"
    value "INCOMPLETE", "Modules not yet completed (includes locked, unlocked, started)", value: "incomplete"
    value "NOT_STARTED", "Modules that are unlocked but not started", value: "not_started"
    value "IN_PROGRESS", "Modules that are started but not completed", value: "in_progress"
  end
end
