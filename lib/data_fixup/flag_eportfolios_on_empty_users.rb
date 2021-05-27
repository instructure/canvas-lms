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

module DataFixup
  class FlagEportfoliosOnEmptyUsers
    def self.run
      GuardRail.activate(:secondary) do
        Eportfolio.select(:user_id).distinct.find_in_batches(batch_size: 5000) do |batch|
          uid_batch = batch.map(&:user_id)
          uid_batch -= Enrollment.where(user_id: uid_batch).pluck(:user_id)
          uid_batch -= AccountUser.where(user_id: uid_batch).pluck(:user_id)
          if uid_batch.present?
            GuardRail.activate(:primary) do
              Eportfolio.where(user_id: uid_batch, spam_status: nil)
                .update_all(spam_status: 'flagged_as_possible_spam')
            end
          end
        end
      end
    end
  end
end
