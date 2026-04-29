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

module DataFixup
  module BackfillCustomGradeStatusIcons
    AVAILABLE_ICONS = %w[custom-1 custom-2 custom-3].freeze

    def self.run
      # Process each root account separately to respect the icon pool per account
      Account.root_accounts.active.non_shadow.find_each do |root_account|
        available_icons = AVAILABLE_ICONS.dup

        # Assign icons in ID order to preserve current visual behavior
        root_account.custom_grade_statuses.active.where(icon: nil).order(:id).each do |status|
          break if available_icons.empty?

          # Use update_column to bypass validations and callbacks for performance
          status.update_column(:icon, available_icons.shift)
        end
      end
    end
  end
end
