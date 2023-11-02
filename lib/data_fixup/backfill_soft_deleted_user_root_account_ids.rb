# frozen_string_literal: true

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

module DataFixup
  module BackfillSoftDeletedUserRootAccountIds
    class << self
      def run
        [AccountUser, Enrollment, Pseudonym].each do |model|
          model.find_ids_in_ranges(batch_size: 10_000) do |min, max|
            delay_if_production(priority: Delayed::LOW_PRIORITY,
                                n_strand: "data_fixups:#{Shard.current.database_server.id}")
              .run_for_range(model, min..max)
          end
        end
      end

      def run_for_range(model, range)
        user_ids = model.deleted.where(id: range).distinct.pluck(:user_id)
        user_ids.each_slice(1_000) do |slice|
          User.select(*User::MINIMAL_COLUMNS_TO_SAVE).where(id: slice).each(&:update_root_account_ids)
        end
      end
    end
  end
end
