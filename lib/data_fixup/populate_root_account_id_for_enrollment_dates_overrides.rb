# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdForEnrollmentDatesOverrides
  def self.run
    if Account.root_accounts.size == 1
      EnrollmentDatesOverride
        .where(root_account_id: nil)
        .in_batches(of: 10_000)
        .update_all(root_account_id: Account.root_accounts.take.id)
    else
      EnrollmentDatesOverride
        .where(root_account_id: nil)
        .find_each do |enrollment_dates_override|
          root_account_id = enrollment_dates_override.context&.resolved_root_account_id ||
                            enrollment_dates_override.context&.root_account_id
          enrollment_dates_override.update!(root_account_id: root_account_id) if root_account_id
        end
    end
  end
end
