#
# Copyright (C) 2013 - present Instructure, Inc.
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

class ChangeLearningOutcomeGroupIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :algorithm => :concurrently
  end

  def self.down
    remove_index :learning_outcome_groups, [:context_id, :context_type]
    add_index :learning_outcome_groups, [:context_id, :context_type], :algorithm => :concurrently, :where => "learning_outcome_group_id IS NULL"
  end
end
