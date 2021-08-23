# frozen_string_literal: true

#
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

class AddWorkflowStateToLearningOutcomeResult < ActiveRecord::Migration[6.0]
  tag :predeploy

  disable_ddl_transaction!

  def up
    if (connection.postgresql_version >= 110000)
      add_column :learning_outcome_results, :workflow_state, :string, default: 'active', null: false, if_not_exists: true
    else
      add_column :learning_outcome_results, :workflow_state, :string, if_not_exists: true
      change_column_default :learning_outcome_results, :workflow_state, 'active'
      DataFixup::BackfillNulls.run(LearningOutcomeResult, :workflow_state, default_value: 'active')
      change_column_null :learning_outcome_results, :workflow_state, false
    end
  end

  def down
    remove_column :learning_outcome_results, :workflow_state
  end
end
