#
# Copyright (C) 2016 - present Instructure, Inc.
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

class RecomputeMergedEnrollments < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    start_date = DateTime.parse("2016-08-05")
    merged_enrollment_ids = UserMergeDataRecord.where(:context_type => "Enrollment").
      joins("INNER JOIN #{UserMergeData.quoted_table_name} ON user_merge_data_records.user_merge_data_id = user_merge_data.id").
      where("user_merge_data.updated_at > ?", start_date).pluck(:context_id)

    if merged_enrollment_ids.any?
      Shard.partition_by_shard(merged_enrollment_ids) do |sliced_ids|
        EnrollmentState.force_recalculation(sliced_ids)
      end
    end
  end

  def down
  end
end
