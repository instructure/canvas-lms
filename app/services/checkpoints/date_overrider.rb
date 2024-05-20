# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Checkpoints::DateOverrider
  def apply_overridden_dates(override, override_params, shell_override: false)
    # The checkpoint override stores the actual relevant dates (due_at, unlock_at, lock_at).
    # The parent assignment override is a "shell" override that does not contain the relevant dates;
    # it only exists so that assignment visibility can be correctly determined for students.
    override_params.slice(:due_at, :unlock_at, :lock_at).each do |field, value|
      value_to_set = shell_override ? nil : value
      override.public_send(:"override_#{field}", value_to_set)
    end
  end
end
