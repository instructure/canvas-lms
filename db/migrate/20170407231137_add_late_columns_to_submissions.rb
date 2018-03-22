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

class AddLateColumnsToSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :submissions, :late_policy_status, :string, limit: 16
    add_column :submissions, :accepted_at, :timestamp
    add_column :submissions, :points_deducted, :decimal, precision: 6, scale: 2
  end

  def down
    remove_column :submissions, :points_deducted
    remove_column :submissions, :accepted_at
    remove_column :submissions, :late_policy_status
  end
end
