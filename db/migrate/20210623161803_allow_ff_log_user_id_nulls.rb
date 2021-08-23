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

class AllowFfLogUserIdNulls < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    # it's possible to have some contexts (like jobs)
    # where feature flags get changed an no
    # user can be inferred.  We don't want those to fail.
    change_column_null :auditor_feature_flag_records, :user_id, true
    Auditors::ActiveRecord::FeatureFlagRecord.where(user_id: 0).update_all(user_id: nil)
  end

  def down
    Auditors::ActiveRecord::FeatureFlagRecord.where(user_id: nil).update_all(user_id: 0)
    change_column_null :auditor_feature_flag_records, :user_id, false
  end
end
