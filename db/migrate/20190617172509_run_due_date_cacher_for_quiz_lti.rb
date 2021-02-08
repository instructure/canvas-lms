#
# Copyright (C) 2019 - present Instructure, Inc.
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

class RunDueDateCacherForQuizLti < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    Course.find_ids_in_ranges(batch_size: 100_000) do |start_at, end_at|
      DataFixup::RunDueDateCacherForQuizLTI.delay_if_production(priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::RunDueDateCacherForQuizLti", Shard.current.database_server.id]).run(start_at, end_at)
    end
  end
end
