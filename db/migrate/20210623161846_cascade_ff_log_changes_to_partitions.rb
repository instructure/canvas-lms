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

class CascadeFfLogChangesToPartitions < CanvasPartman::Migration
  disable_ddl_transaction!
  tag :postdeploy
  self.base_class = Auditors::ActiveRecord::FeatureFlagRecord

  def up
    Auditors::ActiveRecord::FeatureFlagRecord.where(user_id: 0).update_all(user_id: nil)
    with_each_partition do |partition|
      change_column_null partition, :user_id, true
      add_foreign_key partition, :users, delay_validation: true, if_not_exists: true
      add_index partition, :user_id, algorithm: :concurrently, if_not_exists: true
    end
  end

  def down
    Auditors::ActiveRecord::FeatureFlagRecord.where(user_id: nil).update_all(user_id: 0)
    with_each_partition do |partition|
      remove_index partition, :user_id
      remove_foreign_key partition, :users
      change_column_null partition, :user_id, false
    end
  end
end
