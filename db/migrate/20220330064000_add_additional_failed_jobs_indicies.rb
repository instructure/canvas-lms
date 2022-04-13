# frozen_string_literal: true

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

class AddAdditionalFailedJobsIndicies < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    # This column exists in switchman-inst-jobs, although not in Canvas. For the purposes of this migration, mirror
    # the lack of a WHERE constraint to mirror switchman-inst-jobs to prevent any surprises later.
    add_index :failed_jobs, :shard_id, algorithm: :concurrently, if_not_exists: true
  end
end
