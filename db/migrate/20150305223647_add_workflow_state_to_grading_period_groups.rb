#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddWorkflowStateToGradingPeriodGroups < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    unless column_exists?(:grading_period_groups, :workflow_state)
      add_column :grading_period_groups, :workflow_state, :string
    end
    GradingPeriodGroup.where(workflow_state: nil).find_ids_in_batches do |ids|
      GradingPeriodGroup.where(id: ids).update_all(workflow_state: 'active')
    end
    change_column_default :grading_period_groups, :workflow_state, 'active'
    add_index :grading_period_groups, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :grading_period_groups, :workflow_state
  end
end
