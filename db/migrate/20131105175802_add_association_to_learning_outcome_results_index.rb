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

class AddAssociationToLearningOutcomeResultsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    rename_index :learning_outcome_results, 'index_learning_outcome_results_association', 'temp_index_learning_outcome'
    LearningOutcomeResult.
      select("user_id, content_tag_id, association_id, association_type,
              associated_asset_id, associated_asset_type").
      group("user_id, content_tag_id, association_id, association_type,
             associated_asset_id, associated_asset_type").
      having("COUNT(*) > 1").find_each do |lor|
      scope = LearningOutcomeResult.
        where(user_id: lor.user_id,
              content_tag_id: lor.content_tag_id,
              associated_asset_id: lor.associated_asset_id,
              association_id: lor.association_id,
              association_type: lor.association_type,
              associated_asset_type: lor.associated_asset_type)
      keeper = scope.order("updated_at DESC").first
      scope.where("id<>?", keeper).delete_all
    end
    add_index :learning_outcome_results,
              [:user_id, :content_tag_id, :association_id, :association_type, :associated_asset_id, :associated_asset_type],
              unique: true,
              name: "index_learning_outcome_results_association",
              algorithm: :concurrently
    remove_index :learning_outcome_results, name: "temp_index_learning_outcome"
  end

  def self.down
    # Not possible to reliably revert to the old index, which was only on
    # user_id and content_tag_id, and associated_asset
    raise ActiveRecord::IrreversibleMigration
  end
end
