# frozen_string_literal: true

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

class RemoveNotNullConstraintFromCreatedByIdOnLtiRegistrationHistoryEntries < ActiveRecord::Migration[7.2]
  tag :predeploy

  def change
    # It's possible for a Lti::RegistrationHistoryEntry to be created without a created_by user,
    # (mainly when a default tool is installed by the system)
    # so we need to make the column nullable.
    change_column_null :lti_registration_history_entries, :created_by_id, true
  end
end
