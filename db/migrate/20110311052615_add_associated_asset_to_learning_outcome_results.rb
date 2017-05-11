#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AddAssociatedAssetToLearningOutcomeResults < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :learning_outcome_results, :associated_asset_id, :integer, :limit => 8
    add_column :learning_outcome_results, :associated_asset_type, :string
    remove_index :learning_outcome_results, [:user_id, :content_tag_id]
    add_index :learning_outcome_results, [:user_id, :content_tag_id, :associated_asset_id, :associated_asset_type], :unique => true, :name => "index_learning_outcome_results_association"
  end

  def self.down
    # Not possible to reliably revert to the old index,
    # which was only on user_id and content_tag_id
    raise ActiveRecord::IrreversibleMigration
  end
end
