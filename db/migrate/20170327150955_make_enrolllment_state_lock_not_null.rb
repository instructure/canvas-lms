# frozen_string_literal: true

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

class MakeEnrolllmentStateLockNotNull < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    change_column_default(:enrollment_states, :lock_version, 0)
    EnrollmentState.find_ids_in_ranges(:batch_size => 100_000) do |min_id, max_id|
      EnrollmentState.where(:enrollment_id => min_id..max_id, :lock_version => nil).update_all(:lock_version => 0)
    end
    change_column_null(:enrollment_states, :lock_version, false)
  end

  def down
  end
end
