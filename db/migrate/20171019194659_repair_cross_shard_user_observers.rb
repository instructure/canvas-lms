#
# Copyright (C) 2017 - present Instructure, Inc.
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

class RepairCrossShardUserObservers < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    remove_foreign_key :user_observers, column: :observer_id

    UserObservationLink.where("user_id/?<>observer_id/?", Shard::IDS_PER_SHARD, Shard::IDS_PER_SHARD).find_each do |uo|
      # just "restore" it - will automatically create the missing side, and create enrollments that
      # may not have worked initially
      UserObservationLink.create_or_restore(observer: uo.observer, student: uo.student)
    end
  end
end
