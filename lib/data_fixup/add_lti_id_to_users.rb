# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module DataFixup::AddLtiIdToUsers
  def self.run
    User.where(lti_id: nil).find_ids_in_batches(batch_size: 10_000) do |batch|
      updates = batch.index_with { SecureRandom.uuid }
      User.all.update_many(updates, :lti_id)

      delay = Setting.get("lti_id_datafixup_delay", "0").to_i
      sleep(delay) if delay > 0
    end
  end
end
